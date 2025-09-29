#!/bin/bash

# Test script for godot-llama-cpp manual testing
echo "=== Godot-Llama-CPP Manual Test Script ==="
echo "Current directory: $(pwd)"
echo "Date: $(date)"

# Check if build exists
if [ -d "build" ] && [ -f "build/libgodot_llama.dylib" ]; then
    echo "✓ Build directory exists with library"
else
    echo "✗ Build not found, running make..."
    make -j$(nproc)
    if [ $? -ne 0 ]; then
        echo "ERROR: Build failed"
        exit 1
    fi
fi

# Check Godot
if [ ! -d "godot-bin" ]; then
    echo "✗ Godot binary not found"
    exit 1
fi

# Check for Godot executable
GODOT_EXE="./godot-bin/Godot.app/Contents/MacOS/Godot"
if [ ! -f "$GODOT_EXE" ]; then
    echo "Checking if standalone godot executable exists..."
    GODOT_EXE="./godot-bin/godot"
    if [ -f "$GODOT_EXE" ]; then
        chmod +x "$GODOT_EXE" 2>/dev/null || true
        if [ ! -x "$GODOT_EXE" ]; then
            echo "✗ Godot executable not executable"
            exit 1
        fi
    else
        echo "✗ Godot executable not found"
        exit 1
    fi
fi

echo "✓ Godot executable found: $GODOT_EXE"

# Copy built library to demo
echo "Copying library to demo addons..."
cp build/libgodot_llama.dylib .github/godot-demo/addons/godot-llama-cpp/

echo "=== Running Godot Test ==="
echo "Running: $GODOT_EXE --headless --path .github/godot-demo test_scene.tscn"

# Run Godot in headless mode with the test scene
"$GODOT_EXE" --headless --path .github/godot-demo test_scene.tscn 2>&1 | tee .github/godot-demo/test_execution.log

# Check results
if [ -f ".github/godot-demo/test_results.log" ]; then
    echo "=== Test Results ==="
    cat .github/godot-demo/test_results.log
elif [ -f ".github/godot-demo/test_execution.log" ]; then
    echo "=== Test Execution Log ==="
    cat .github/godot-demo/test_execution.log
else
    echo "✗ Test result files not found"
    echo "Check .github/godot-demo/ for test_execution.log or test_results.log"
fi

echo "=== Test Complete ==="
