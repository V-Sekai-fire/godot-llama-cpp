extends Node

# Test script for Huihui-Qwen3-0.6B-abliterated-v2 model
# This script runs the model and outputs JSON results for easy parsing

var test_results = {}
var test_completed = false
var llama_context = null

func _init():
	print("=== Starting Huihui-Qwen3 Model Test ===")
	print("Godot version: ", Engine.get_version_info())
	
	# Initialize test results
	test_results["godot_version"] = Engine.get_version_info()
	test_results["test_start_time"] = Time.get_ticks_msec()
	test_results["status"] = "initializing"
	
	# Check extension availability
	if not check_extension_classes():
		output_error("Extension classes not available")
		return
	
	# Run the actual test
	call_deferred("run_test")

func check_extension_classes() -> bool:
	print("=== Checking Extension Classes ===")
	
	var llama_context_available = ClassDB.class_exists("LlamaContext")
	var llama_model_available = ClassDB.class_exists("LlamaModel")
	
	test_results["llama_context_available"] = llama_context_available
	test_results["llama_model_available"] = llama_model_available
	
	if llama_context_available:
		print("✓ LlamaContext class found")
	else:
		print("✗ LlamaContext class NOT found")
	
	if llama_model_available:
		print("✓ LlamaModel class found")
	else:
		print("✗ LlamaModel class NOT found")
	
	if not llama_context_available or not llama_model_available:
		print("Extension classes not available - checking extension loading...")
		check_extension_files()
		return false
	
	return true

func check_extension_files():
	print("=== Checking Extension Files ===")
	
	# Check if extension file exists
	var extension_path = "res://addons/godot-llama-cpp/plugin.gdextension"
	var extension_exists = FileAccess.file_exists(extension_path)
	test_results["extension_file_exists"] = extension_exists
	
	if extension_exists:
		print("✓ Extension file exists: ", extension_path)
		
		# Check library file
		var lib_path = "res://addons/godot-llama-cpp/lib/libgodot_llama.dylib"
		var lib_exists = FileAccess.file_exists(lib_path)
		test_results["library_file_exists"] = lib_exists
		
		if lib_exists:
			print("✓ Library file exists: ", lib_path)
		else:
			print("✗ Library file missing: ", lib_path)
	else:
		print("✗ Extension file missing: ", extension_path)

func run_test():
	print("=== Running Model Test ===")
	
	# Check if we can proceed with the actual test
	if not test_results.get("llama_context_available", false) or not test_results.get("llama_model_available", false):
		output_error("Cannot run test - extension classes not available")
		return
	
	# Check model file
	var model_path = "res://models/huihui-qwen3-0.6b-abliterated-v2-q8_0.gguf"
	if not FileAccess.file_exists(model_path):
		output_error("Model file not found: " + model_path)
		return
	
	print("✓ Model file exists: ", model_path)
	test_results["model_file_exists"] = true
	
	# Create extension instances
	if not create_llama_context():
		return
	
	if not load_model(model_path):
		return
	
	if not setup_context():
		return
	
	# Run the actual inference
	run_inference()

func create_llama_context() -> bool:
	print("Creating LlamaContext...")
	
	llama_context = LlamaContext.new()
	if not llama_context:
		output_error("Failed to create LlamaContext")
		return false
	
	if not is_instance_valid(llama_context):
		output_error("LlamaContext instance is invalid")
		return false
	
	print("✓ LlamaContext created successfully")
	return true

func load_model(model_path: String) -> bool:
	print("Loading model...")
	
	var llama_model = load(model_path) as LlamaModel
	if not llama_model:
		output_error("Failed to load model as LlamaModel")
		return false
	
	if not is_instance_valid(llama_model):
		output_error("LlamaModel instance is invalid")
		return false
	
	# Set model on context
	llama_context.model = llama_model
	print("✓ Model loaded and set on context")
	return true

func setup_context() -> bool:
	# Check for completion_generated signal
	if not llama_context.has_signal("completion_generated"):
		output_error("LlamaContext missing completion_generated signal")
		return false

	# Connect signal
	var result = llama_context.completion_generated.connect(_on_completion_generated)
	if result != OK:
		output_error("Failed to connect completion_generated signal")
		return false

	print("✓ Connected to completion_generated signal")

	# Add to scene tree
	get_tree().get_root().add_child(llama_context)
	print("✓ Added LlamaContext to scene tree")

	return true

func run_inference():
	print("=== Running Inference ===")

	# Load grammar if available
	var grammar_content = load_grammar()

	# Prepare test prompt
	var test_prompt = 'What is 2+2?'
	var start_time = Time.get_ticks_msec()

	test_results["test_prompt"] = test_prompt
	test_results["inference_start_time"] = start_time
	test_results["status"] = "running_inference"

	print("Prompt: ", test_prompt)

	# Check if request_completion method exists
	if not llama_context.has_method("request_completion"):
		output_error("LlamaContext missing request_completion method")
		return

	# Request completion synchronously
	var response = llama_context.request_completion(test_prompt)
	var end_time = Time.get_ticks_msec()

	if response == "":
		output_error("Failed to get completion - empty response")
		return

	# Store synchronous result
	test_results["response"] = response
	test_results["status"] = "completed"
	test_results["end_time"] = end_time
	test_results["duration_ms"] = end_time - start_time

	print("✓ Synchronous completion successful")
	print("Response: ", response)
	output_results()

func load_grammar() -> String:
	print("=== Loading Grammar ===")
	
	var grammar_path = "res://grammars/test_response.gbnf"
	
	if FileAccess.file_exists(grammar_path):
		print("✓ Grammar file exists: ", grammar_path)
		var grammar_file = FileAccess.open(grammar_path, FileAccess.READ)
		if grammar_file:
			var content = grammar_file.get_as_text()
			grammar_file.close()
			print("✓ Loaded grammar, length: ", content.length())
			return content
		else:
			print("✗ Could not open grammar file")
	else:
		print("✗ Grammar file not found: ", grammar_path)
	
	# Try JSON fallback
	var json_grammar_path = "res://grammars/json.gbnf"
	if FileAccess.file_exists(json_grammar_path):
		print("Trying JSON fallback grammar...")
		var json_file = FileAccess.open(json_grammar_path, FileAccess.READ)
		if json_file:
			var content = json_file.get_as_text()
			json_file.close()
			print("✓ Using JSON grammar as fallback, length: ", content.length())
			return content
		else:
			print("✗ Could not open JSON fallback grammar")
	else:
		print("✗ JSON fallback grammar not found either")
	
	print("Will proceed without grammar")
	return ""

func _on_completion_generated(chunk: Dictionary):
	print("Received chunk: ", chunk)
	
	if chunk.has("error"):
		test_results["status"] = "error"
		test_results["error"] = chunk["error"]
		output_results()
		return
	
	if chunk.has("text"):
		if not test_results.has("response"):
			test_results["response"] = ""
		test_results["response"] += chunk["text"]
		
		# Check if completion is done (simple heuristic)
		if chunk.get("done", false) or chunk["text"].ends_with("\n") or test_results["response"].length() > 100:
			test_results["status"] = "completed"
			test_results["end_time"] = Time.get_ticks_msec()
			test_results["duration_ms"] = test_results["end_time"] - test_results["start_time"]
			output_results()

func _on_timeout():
	if not test_completed:
		test_results["status"] = "timeout"
		test_results["error"] = "Test timed out after 30 seconds"
		output_results()

func output_results():
	if test_completed:
		return
	
	test_completed = true
	
	print("=== TEST RESULTS (JSON) ===")
	print(JSON.stringify(test_results, "\t"))
	print("=== END TEST RESULTS ===")
	
	get_tree().quit(0)

func output_error(message: String):
	test_results["status"] = "error"
	test_results["error"] = message
	print("ERROR: ", message)
	output_results()
