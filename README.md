<div align='center'>

<img width="100" src="/godot/addons/godot-llama-cpp/assets/godot-llama-cpp-1024x1024.svg">

<h1>godot-llama-cpp</h1>

Run large language models in [Godot](https://godotengine.org). Powered by [llama.cpp](https://github.com/ggerganov/llama.cpp).

<br />
<br />

![Godot v4.2](https://img.shields.io/badge/Godot-v4.2-%23478cbf?logo=godot-engine&logoColor=white)
![CMake CI](https://github.com/hazelnutcloud/godot-llama-cpp/actions/workflows/builds.yml/badge.svg)
![GitHub License](https://img.shields.io/github/license/hazelnutcloud/godot-llama-cpp)

</div>

## Overview

This library aims to provide a high-level interface to run large language models in Godot, following Godot's node-based design principles.

```gdscript
@onready var llama_context = %LlamaContext

var messages = [
  { "sender": "system", "text": "You are a pirate chatbot who always responds in pirate speak!" },
  { "sender": "user", "text": "Who are you?" }
]
var prompt = ChatFormatter.apply("llama3", messages)
var completion_id = llama_context.request_completion(prompt)

while (true):
  var response = await llama_context.completion_generated
  print(response["text"])

  if response["done"]: break
```

## Features
  - Platform and compute backend support:
    | Platform | CPU | Metal | Vulkan | CUDA |
    |----------|-----|-------|--------|------|
    | macOS    | ✅  | ✅    | ❌     | ❌   |
    | Linux    | ✅  | ❌    | ✅     | 🚧   |
    | Windows  | ✅  | ❌    | 🚧     | 🚧   |
  - Asynchronous completion generation
  - Support any language model that llama.cpp supports in GGUF format
  - GGUF files are Godot resources

## Roadmap
  - [ ] Chat completions support via dedicated library for jinja2 templating in zig
  - [ ] Grammar support
  - [ ] Multimodal models support
  - [ ] Embeddings
  - [ ] Vector database using LibSQL

## Building & Installation

### Prerequisites
- CMake 3.14 or later
- C++ compiler supporting C++17
- Python 3.4+ (for bindings generation)

### Steps

1. Clone the repository:
   ```bash
   git clone --recurse-submodules https://github.com/hazelnutcloud/godot-llama-cpp.git
   ```
2. Copy the `godot-llama-cpp` addon folder in `godot/addons` to your Godot project's `addons` folder.
   ```bash
    cp -r godot-llama-cpp/godot/addons/godot-llama-cpp <your_project>/addons
   ```
3. Build the extension and install it in your Godot project addons folder:
   ```bash
   cd godot-llama-cpp
   mkdir build && cd build
   cmake .. -DENABLE_METAL=ON  # or other options like ENABLE_CUDA=ON
   make
   make install
   ```
4. Enable the plugin in your Godot project settings.
5. Add the `LlamaContext` node to your scene.
6. Run your Godot project.
7. Enjoy!

### Build Options
- `ENABLE_METAL=ON`: Enable Metal compute backend (macOS)
- `ENABLE_VULKAN=ON`: Enable Vulkan compute backend
- `ENABLE_CUDA=ON`: Enable CUDA compute backend
- `ENABLE_CANN=ON`: Enable CANN compute backend

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE.md) file for details.
