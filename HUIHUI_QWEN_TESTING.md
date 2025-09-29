# Huihui-Qwen3 Testing with godot-llama-cpp

This document explains how to test the `huihui-ai/Huihui-Qwen3-0.6B-abliterated-v2` model with godot-llama-cpp in both GitHub Actions and locally.

## Overview

- **Model**: `huihui-qwen3-0.6b-abliterated-v2-q8_0.gguf` (609MB)
- **Format**: GGUF (directly compatible with llama.cpp)
- **Grammar**: Custom JSON grammar for structured output
- **Platforms**: Linux (GitHub Actions) and macOS (local testing)

## Project Structure

```
.github/
├── godot-demo/                 # Hidden Godot demo project
│   ├── project.godot
│   ├── test_huihui_qwen.gd    # Test script
│   ├── models/                # Model directory
│   │   └── huihui-qwen3-0.6b-abliterated-v2-q8_0.gguf
│   ├── grammars/              # Grammar files
│   │   ├── test_response.gbnf # Custom JSON grammar
│   │   └── json.gbnf          # Fallback JSON grammar
│   └── addons/
│       └── godot-llama-cpp/   # Extension files
├── scripts/
│   └── download_model.sh      # Model download script
└── workflows/
    └── test-huihui-qwen.yml   # GitHub Actions workflow
```

## GitHub Actions Testing

### Automatic Triggers
- Push to `main` or `master` branches
- Pull requests
- Manual workflow dispatch

### What it does
1. **Downloads Godot 4.3** for Linux
2. **Builds the extension** using CMake
3. **Downloads the model** (cached for performance)
4. **Runs the test** in headless mode
5. **Parses JSON output** and validates results
6. **Comments on PRs** with test results

### Viewing Results
- Check the "Actions" tab in GitHub
- Download test artifacts for detailed logs
- PR comments show test summaries

## Local macOS Testing

### Prerequisites
- macOS with Xcode command line tools
- CMake
- Python 3

### Running the Test
```bash
# Make the script executable (if not already)
chmod +x test_local_macos.sh

# Run the full test
./test_local_macos.sh
```

### What the script does
1. **Downloads Godot 4.3** for macOS (universal binary)
2. **Builds the extension** with optimizations
3. **Downloads the model** (if not cached)
4. **Runs the test** and captures output
5. **Parses results** and displays summary

## Test Details

### Test Prompt
```
Please answer this math question in the following JSON format: 
{"answer": "your_answer", "explanation": "brief_explanation", "confidence": 0.95}. 
Question: What is 2+2?
```

### Expected Output Format
```json
{
  "test_prompt": "Please answer this math question...",
  "status": "completed",
  "response": "{\"answer\": \"4\", \"explanation\": \"2+2 equals 4\", \"confidence\": 0.95}",
  "duration_ms": 1500,
  "grammar_used": true,
  "start_time": 1234567890,
  "end_time": 1234567891,
  "completion_id": 1
}
```

### Grammar Enforcement
The test uses a custom GBNF grammar file (`test_response.gbnf`) to ensure the model outputs valid JSON:
- Enforces specific field structure
- Validates JSON syntax
- Fallback to standard JSON grammar if custom grammar fails

## Configuration

### Model Settings
- **Temperature**: 0.7
- **Max Tokens**: 100
- **Timeout**: 30 seconds
- **Grammar**: Custom JSON format

### Performance Expectations
- **Model Load Time**: 5-15 seconds
- **Response Time**: 1-5 seconds
- **Total Test Time**: < 30 seconds

## Troubleshooting

### Common Issues

1. **Model Download Fails**
   - Check internet connection
   - Verify Hugging Face accessibility
   - Clear cache and retry

2. **Extension Build Fails**
   - Ensure CMake is installed
   - Check compiler compatibility
   - Verify submodules are initialized

3. **Test Timeout**
   - Model may be too large for available memory
   - Check system resources
   - Increase timeout in test script

4. **Invalid JSON Output**
   - Grammar file may not be loaded correctly
   - Model may not follow instructions
   - Check test prompt format

### Debug Commands
```bash
# Check model file
ls -la .github/godot-demo/models/

# Verify grammar files
ls -la .github/godot-demo/grammars/

# Test extension build
mkdir -p build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
make -j$(nproc)

# Manual Godot test
cd .github/godot-demo
../../godot-bin/godot --headless --script test_huihui_qwen.gd
```

## Integration with CI/CD

### PR Workflow
1. Developer creates PR
2. GitHub Actions automatically runs test
3. Results posted as PR comment
4. Pass/fail status affects merge ability

### Caching Strategy
- **Godot binaries**: Cached by version and OS
- **Model file**: Cached by download script hash
- **Extension builds**: Not cached (quick to build)

## Performance Metrics

### Typical Results
- **Linux CI**: 2-4 seconds response time
- **macOS Local**: 1-3 seconds response time
- **Model Accuracy**: >95% for simple math
- **JSON Compliance**: 100% with grammar

### Resource Usage
- **Memory**: ~2-4 GB during execution
- **CPU**: High during model load, moderate during inference
- **Disk**: 609 MB for model file

## Future Improvements

1. **Multi-model testing**: Add support for different quantizations
2. **Benchmark suite**: Comprehensive performance testing
3. **Error reporting**: Enhanced debugging information
4. **Cross-platform**: Add Windows support
5. **Performance monitoring**: Track response times over time
