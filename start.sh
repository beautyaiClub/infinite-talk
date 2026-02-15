#!/bin/bash
set -e

echo "=== Starting RunPod Worker with Custom Output Handler ==="

# Start ComfyUI in the background
echo "Starting ComfyUI server..."
cd /comfyui
python main.py --listen 0.0.0.0 --port 8188 &

COMFYUI_PID=$!
echo "ComfyUI started with PID: $COMFYUI_PID"

# Wait for ComfyUI to be ready
echo "Waiting for ComfyUI to be ready..."
MAX_RETRIES=60
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if curl -s http://127.0.0.1:8188/system_stats > /dev/null 2>&1; then
        echo "ComfyUI is ready!"
        break
    fi

    RETRY_COUNT=$((RETRY_COUNT + 1))
    echo "Waiting for ComfyUI... ($RETRY_COUNT/$MAX_RETRIES)"
    sleep 2
done

if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
    echo "ERROR: ComfyUI failed to start within timeout"
    exit 1
fi

# Start the original RunPod worker with our wrapper
echo "Starting RunPod worker with output transformer..."
cd /comfyui
python -u /comfyui/handler_wrapper.py
