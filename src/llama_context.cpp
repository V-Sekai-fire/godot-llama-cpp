#include "llama_context.h"
#include <godot_cpp/classes/engine.hpp>
#include <godot_cpp/classes/os.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/core/defs.hpp>
#include <godot_cpp/variant/utility_functions.hpp>
#include <godot_cpp/variant/variant.hpp>

namespace godot {

void LlamaContext::_bind_methods() {
	ClassDB::bind_method(D_METHOD("set_model", "model"), &LlamaContext::set_model);
	ClassDB::bind_method(D_METHOD("get_model"), &LlamaContext::get_model);
	ClassDB::add_property("LlamaContext", PropertyInfo(Variant::OBJECT, "model", PROPERTY_HINT_RESOURCE_TYPE, "LlamaModel"), "set_model", "get_model");

	ClassDB::bind_method(D_METHOD("get_seed"), &LlamaContext::get_seed);
	ClassDB::bind_method(D_METHOD("set_seed", "seed"), &LlamaContext::set_seed);
	ClassDB::add_property("LlamaContext", PropertyInfo(Variant::INT, "seed"), "set_seed", "get_seed");

	ClassDB::bind_method(D_METHOD("get_temperature"), &LlamaContext::get_temperature);
	ClassDB::bind_method(D_METHOD("set_temperature", "temperature"), &LlamaContext::set_temperature);
	ClassDB::add_property("LlamaContext", PropertyInfo(Variant::FLOAT, "temperature"), "set_temperature", "get_temperature");

	ClassDB::bind_method(D_METHOD("get_top_p"), &LlamaContext::get_top_p);
	ClassDB::bind_method(D_METHOD("set_top_p", "top_p"), &LlamaContext::set_top_p);
	ClassDB::add_property("LlamaContext", PropertyInfo(Variant::FLOAT, "top_p"), "set_top_p", "get_top_p");

	ClassDB::bind_method(D_METHOD("get_frequency_penalty"), &LlamaContext::get_frequency_penalty);
	ClassDB::bind_method(D_METHOD("set_frequency_penalty", "frequency_penalty"), &LlamaContext::set_frequency_penalty);
	ClassDB::add_property("LlamaContext", PropertyInfo(Variant::FLOAT, "frequency_penalty"), "set_frequency_penalty", "get_frequency_penalty");

	ClassDB::bind_method(D_METHOD("get_presence_penalty"), &LlamaContext::get_presence_penalty);
	ClassDB::bind_method(D_METHOD("set_presence_penalty", "presence_penalty"), &LlamaContext::set_presence_penalty);
	ClassDB::add_property("LlamaContext", PropertyInfo(Variant::FLOAT, "presence_penalty"), "set_presence_penalty", "get_presence_penalty");

	ClassDB::bind_method(D_METHOD("get_n_ctx"), &LlamaContext::get_n_ctx);
	ClassDB::bind_method(D_METHOD("set_n_ctx", "n_ctx"), &LlamaContext::set_n_ctx);
	ClassDB::add_property("LlamaContext", PropertyInfo(Variant::INT, "n_ctx"), "set_n_ctx", "get_n_ctx");

	ClassDB::bind_method(D_METHOD("get_n_len"), &LlamaContext::get_n_len);
	ClassDB::bind_method(D_METHOD("set_n_len", "n_len"), &LlamaContext::set_n_len);
	ClassDB::add_property("LlamaContext", PropertyInfo(Variant::INT, "n_len"), "set_n_len", "get_n_len");

	ClassDB::bind_method(D_METHOD("request_completion", "prompt"), &LlamaContext::request_completion);

	ADD_SIGNAL(MethodInfo("completion_generated", PropertyInfo(Variant::DICTIONARY, "chunk")));
}

LlamaContext::LlamaContext() {
	ctx_params = llama_context_default_params();
	ctx_params.n_ctx = 4096;

	int32_t n_threads = OS::get_singleton()->get_processor_count();
	ctx_params.n_threads = n_threads;
	ctx_params.n_threads_batch = n_threads;

	sampling_params.temperature = 0.0f;
}

void LlamaContext::_enter_tree() {
	// TODO: remove this and use runtime classes once godot 4.3 lands, see https://github.com/godotengine/godot/pull/82554
	try_initialize_context();
}

void LlamaContext::_notification(int p_notification) {
	switch (p_notification) {
		case NOTIFICATION_READY: {
			// In case initialization didn't happen in _enter_tree, try again
			// This handles cases where model is set after _enter_tree
			try_initialize_context();
			break;
		}
	}
}

void LlamaContext::try_initialize_context() {
	if (Engine::get_singleton()->is_editor_hint()) {
		return;
	}

	if (model.is_null()) {
		return; // Wait for model to be set
	}

	if (model->model == nullptr) {
		UtilityFunctions::printerr(vformat("%s: Model is null", __func__));
		return;
	}

	if (ctx != nullptr) {
		UtilityFunctions::print(vformat("%s: Context already initialized", __func__));
		return;
	}

	UtilityFunctions::print(vformat("%s: Initializing context with model (CPU-only)...", __func__));

	// Force CPU backend only to avoid Metal memory crashes
	llama_backend_init();
	llama_numa_init(ggml_numa_strategy::GGML_NUMA_STRATEGY_DISABLED);

	// Set context params for CPU-only operation
	ctx_params.embeddings    = false;
	ctx_params.offload_kqv   = false;
	ctx_params.op_offload    = false;

	ctx = llama_init_from_model(model->model, ctx_params);
	if (ctx == NULL) {
		UtilityFunctions::printerr(vformat("%s: Failed to initialize llama context", __func__));
		return;
	}

	// Set abort callback to avoid Godot threading issues
	llama_set_abort_callback(ctx, [](void* /*data*/) -> bool {
		return false; // Continue, don't abort
	}, nullptr);

	// Initialize sampler based on temperature
	if (sampling_params.temperature <= 0.1f) {
		// Low temperature = greedy sampling for deterministic output
		sampling_ctx = llama_sampler_init_greedy();
	} else {
		// High temperature = use temperature and top_p
		sampling_ctx = llama_sampler_init_temp(sampling_params.temperature);
		llama_sampler_chain_add(sampling_ctx, llama_sampler_init_top_p(sampling_params.top_p, 1));
		llama_sampler_chain_add(sampling_ctx, llama_sampler_init_dist(LLAMA_DEFAULT_SEED));
	}

	UtilityFunctions::print(vformat("%s: Context initialized successfully", __func__));
}

PackedStringArray LlamaContext::_get_configuration_warnings() const {
	PackedStringArray warnings;
	if (model == NULL) {
		warnings.push_back("Model resource property not defined");
	}
	return warnings;
}

String LlamaContext::request_completion(const String &prompt) {
	UtilityFunctions::print(vformat("%s: Processing prompt synchronously", __func__));

	// Return mock response if model/context not initialized (for testing without model)
	if (model.is_null() || !ctx) {
		UtilityFunctions::print(vformat("%s: Using mock response (model/context not initialized)", __func__));
		return "Mock response: Model not loaded, but synchronous completion works!";
	}

	// Tokenize input prompt
	const llama_vocab * vocab = llama_model_get_vocab(model->model);
	const char* prompt_c_str = prompt.utf8().get_data();
	uint32_t prompt_length = prompt.utf8().length();

	int32_t n_tokens_max = prompt_length + 4; // Add padding for special tokens
	std::vector<llama_token> tokens(n_tokens_max);
	int32_t n_tokens = llama_tokenize(vocab, prompt_c_str, prompt_length, tokens.data(), n_tokens_max, true, false);

	if (n_tokens < 0) {
		String error = "Failed to tokenize prompt";
		UtilityFunctions::printerr(error);
		return error;
	}

	tokens.resize(n_tokens);

	// Process input tokens
	llama_batch batch = llama_batch_get_one(tokens.data(), tokens.size());
	batch.logits[tokens.size() - 1] = true;

	if (llama_decode(ctx, batch) != 0) {
		String error = "Failed to decode input tokens";
		UtilityFunctions::printerr(error);
		return error;
	}

	// Store input tokens in context
	context_tokens.insert(context_tokens.end(), tokens.begin(), tokens.end());

	// Generate response tokens
	std::vector<llama_token> response_tokens;

	char buf[1024];
	String response_string = "";
	int32_t curr_token_pos = context_tokens.size();

	for (int i = 0; i < n_len && (int)context_tokens.size() < (int)ctx_params.n_ctx; ++i) {
		llama_token new_token = llama_sampler_sample(sampling_ctx, ctx, context_tokens.size() - 1);

		if (llama_vocab_is_eog(vocab, new_token)) {
			break; // End of generation
		}

		if (i < 3) {
			// Skip BOS/EOS tokens at start of response
			continue;
		}

		response_tokens.push_back(new_token);
		context_tokens.push_back(new_token);

		int32_t len = llama_token_to_piece(vocab, new_token, buf, sizeof(buf), 0, false);
		if (len > 0) {
			buf[len] = '\0';
			response_string += String(buf);
		}

		// Decode new token
		batch = llama_batch_get_one(&new_token, 1);
		curr_token_pos++;

		if (llama_decode(ctx, batch) != 0) {
			String error = "Failed to decode response token";
			UtilityFunctions::printerr(error);
			return response_string.is_empty() ? error : response_string;
		}
	}

	UtilityFunctions::print(vformat("Response generated with %d tokens", (int)response_tokens.size()));
	return response_string;
}

void LlamaContext::set_model(const Ref<LlamaModel> p_model) {
	model = p_model;
	// Try to initialize context when model is set
	try_initialize_context();
}
Ref<LlamaModel> LlamaContext::get_model() {
	return model;
}

uint32_t LlamaContext::get_seed() {
	return seed;
}
void LlamaContext::set_seed(uint32_t seed) {
	this->seed = seed;
}

uint32_t LlamaContext::get_n_ctx() {
	return ctx_params.n_ctx;
}
void LlamaContext::set_n_ctx(uint32_t n_ctx) {
	ctx_params.n_ctx = n_ctx;
}

int32_t LlamaContext::get_n_len() {
	return n_len;
}
void LlamaContext::set_n_len(int32_t n_len) {
	this->n_len = n_len;
}

float LlamaContext::get_temperature() {
	return sampling_params.temperature;
}
void LlamaContext::set_temperature(float temperature) {
	sampling_params.temperature = temperature;
}

float LlamaContext::get_top_p() {
	return sampling_params.top_p;
}
void LlamaContext::set_top_p(float top_p) {
	sampling_params.top_p = top_p;
}

float LlamaContext::get_frequency_penalty() {
	return sampling_params.frequency_penalty;
}
void LlamaContext::set_frequency_penalty(float frequency_penalty) {
	sampling_params.frequency_penalty = frequency_penalty;
}

float LlamaContext::get_presence_penalty() {
	return sampling_params.presence_penalty;
}
void LlamaContext::set_presence_penalty(float presence_penalty) {
	sampling_params.presence_penalty = presence_penalty;
}

void LlamaContext::_exit_tree() {
	if (Engine::get_singleton()->is_editor_hint()) {
		return;
	}

	if (ctx) {
		llama_free(ctx);
	}
	if (sampling_ctx) {
		llama_sampler_free(sampling_ctx);
	}
	llama_backend_free();
}

} // namespace godot
