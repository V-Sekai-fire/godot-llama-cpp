extends Node

func _ready():
	print('Testing basic extension load...')
	print('LlamaContext available:',
	ClassDB.class_exists('LlamaContext'))
	get_tree().quit()
