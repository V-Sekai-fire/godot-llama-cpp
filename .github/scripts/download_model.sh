#!/bin/bash

# Download script for Huihui-Qwen3-0.6B-abliterated-v2 model
set -e

MODEL_DIR=".github/godot-demo/models"
MODEL_FILE="huihui-qwen3-0.6b-abliterated-v2-q8_0.gguf"
MODEL_URL="https://huggingface.co/Triangle104/Huihui-Qwen3-0.6B-abliterated-v2-Q8_0-GGUF/resolve/main/huihui-qwen3-0.6b-abliterated-v2-q8_0.gguf?download=true"

echo "=== Downloading Huihui-Qwen3 Model ==="
echo "Model: $MODEL_FILE"
echo "Destination: $MODEL_DIR/$MODEL_FILE"

# Create models directory if it doesn't exist
mkdir -p "$MODEL_DIR"

# Download model if it doesn't exist
if [ ! -f "$MODEL_DIR/$MODEL_FILE" ]; then
    echo "Downloading model..."
    curl -L -o "$MODEL_DIR/$MODEL_FILE" "$MODEL_URL"
    echo "Model downloaded successfully"
else
    echo "Model already exists, skipping download"
fi

# Verify file exists and has reasonable size (should be > 100MB)
if [ -f "$MODEL_DIR/$MODEL_FILE" ]; then
    FILE_SIZE=$(stat -f%z "$MODEL_DIR/$MODEL_FILE" 2>/dev/null || stat -c%s "$MODEL_DIR/$MODEL_FILE" 2>/dev/null || echo "0")
    if [ "$FILE_SIZE" -gt 100000000 ]; then
        echo "Model file verified: $(($FILE_SIZE / 1024 / 1024)) MB"
    else
        echo "Error: Model file seems too small: $FILE_SIZE bytes"
        exit 1
    fi
else
    echo "Error: Model file not found after download"
    exit 1
fi

echo "=== Model download completed ==="
