extends Node

func _ready():
	print("=== Manual Synchronous Test ===")

	# Check extension
	print("Classes available:")
	print("LlamaContext: ", ClassDB.class_exists("LlamaContext"))
	print("LlamaModel: ", ClassDB.class_exists("LlamaModel"))

	if ClassDB.class_exists("LlamaContext") and ClassDB.class_exists("LlamaModel"):
		print("✓ Extension loaded, testing simple completion...")
		var ctx = LlamaContext.new()
		print("Context created: ", ctx)

		if ctx:
			var mock_prompt = "What is 2+2?"
			print("Testing with prompt: ", mock_prompt)
			var response = ctx.request_completion(mock_prompt)
			print("Response received: ", response)

			get_tree().quit(0)
		else:
			print("✗ Could not create context")
			get_tree().quit(1)
	else:
		print("✗ Classes not available")
		get_tree().quit(1)
