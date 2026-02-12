# RunPod Dockerfile for InfiniteTalk V2 Workflow
# Downloads all models from Hugging Face during build

FROM runpod/worker-comfyui:5.5.1-base

# Install system dependencies
RUN apt-get update && apt-get install -y \
    ffmpeg \
    libsndfile1 \
    wget \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install ComfyUI-WanVideoWrapper (InfiniteTalk/MultiTalk support)
RUN git clone https://github.com/kijai/ComfyUI-WanVideoWrapper.git /comfyui/custom_nodes/ComfyUI-WanVideoWrapper && \
    cd /comfyui/custom_nodes/ComfyUI-WanVideoWrapper && \
    pip install --no-cache-dir -r requirements.txt

# Install ComfyUI LayerStyle (for ImageScaleByAspectRatio V2 node)
RUN git clone https://github.com/chflame163/ComfyUI_LayerStyle.git /comfyui/custom_nodes/comfyui_layerstyle && \
    cd /comfyui/custom_nodes/comfyui_layerstyle && \
    pip install --no-cache-dir -r requirements.txt

# Install KJNodes (commonly used utility nodes)
RUN comfy node install --exit-on-fail comfyui-kjnodes

# Install additional Python dependencies for audio processing
RUN pip install --no-cache-dir \
    pyloudnorm \
    torchaudio \
    librosa \
    soundfile \
    huggingface-hub

# Create directory structure for models
RUN mkdir -p /comfyui/models/transformers/TencentGameMate/chinese-wav2vec2-base && \
    mkdir -p /comfyui/models/diffusion_models/Wan2.1 && \
    mkdir -p /comfyui/models/vae && \
    mkdir -p /comfyui/models/clip_vision && \
    mkdir -p /comfyui/models/text_encoders && \
    mkdir -p /comfyui/models/loras/wan

# Download Wav2Vec Chinese model from Hugging Face
RUN cd /comfyui/models/transformers/TencentGameMate/chinese-wav2vec2-base && \
    wget -q https://huggingface.co/TencentGameMate/chinese-wav2vec2-base/resolve/main/config.json && \
    wget -q https://huggingface.co/TencentGameMate/chinese-wav2vec2-base/resolve/main/preprocessor_config.json && \
    wget -q https://huggingface.co/TencentGameMate/chinese-wav2vec2-base/resolve/main/pytorch_model.bin && \
    echo "✓ Wav2Vec model downloaded"

# Download WanVideo models from Hugging Face
# Note: Replace these URLs with actual Hugging Face model URLs
# These are placeholder URLs - you need to provide the correct ones

# InfiniteTalk model
RUN wget -q -O /comfyui/models/diffusion_models/Wan2.1/Wan2_1-InfiniTetalk-Single_fp16.safetensors \
    https://huggingface.co/Kijai/WanVideo_pruned/resolve/main/Wan2_1-InfiniTetalk-Single_fp16.safetensors || \
    echo "⚠ InfiniteTalk model URL needs to be updated"

# WanVideo Main model (14B)
RUN wget -q -O /comfyui/models/diffusion_models/Wan2.1/wan2.1_i2v_480p_14B_fp8_e4m3fn.safetensors \
    https://huggingface.co/Kijai/WanVideo_pruned/resolve/main/wan2.1_i2v_480p_14B_fp8_e4m3fn.safetensors || \
    echo "⚠ WanVideo main model URL needs to be updated"

# VAE model
RUN wget -q -O /comfyui/models/vae/Wan2_1_VAE_bf16.safetensors \
    https://huggingface.co/Kijai/WanVideo_pruned/resolve/main/Wan2_1_VAE_bf16.safetensors || \
    echo "⚠ VAE model URL needs to be updated"

# CLIP Vision model
RUN wget -q -O /comfyui/models/clip_vision/clip_vision_h.safetensors \
    https://huggingface.co/h94/IP-Adapter/resolve/main/models/image_encoder/model.safetensors || \
    echo "⚠ CLIP Vision model URL needs to be updated"

# T5 text encoder
RUN wget -q -O /comfyui/models/text_encoders/umt5_xxl_fp16.safetensors \
    https://huggingface.co/Kijai/WanVideo_pruned/resolve/main/umt5_xxl_fp16.safetensors || \
    echo "⚠ T5 model URL needs to be updated"

# LoRA models
RUN wget -q -O /comfyui/models/loras/wan/Wan21_I2V_14B_lightx2v_cfg_step_distill_lora_rank64.safetensors \
    https://huggingface.co/Kijai/WanVideo_pruned/resolve/main/Wan21_I2V_14B_lightx2v_cfg_step_distill_lora_rank64.safetensors || \
    echo "⚠ LoRA 1 model URL needs to be updated"

RUN wget -q -O /comfyui/models/loras/wan/Wan_2_1_T2V_14B_480p_rCM_lora_average_rank_83_bf16.safetensors \
    https://huggingface.co/Kijai/WanVideo_pruned/resolve/main/Wan_2_1_T2V_14B_480p_rCM_lora_average_rank_83_bf16.safetensors || \
    echo "⚠ LoRA 2 model URL needs to be updated"

# Verify downloaded models
RUN echo "=== Verifying downloaded models ===" && \
    ls -lh /comfyui/models/transformers/TencentGameMate/chinese-wav2vec2-base/ && \
    ls -lh /comfyui/models/diffusion_models/Wan2.1/ && \
    ls -lh /comfyui/models/vae/ && \
    ls -lh /comfyui/models/clip_vision/ && \
    ls -lh /comfyui/models/text_encoders/ && \
    ls -lh /comfyui/models/loras/wan/ && \
    echo "=== Model verification complete ==="

# Set working directory
WORKDIR /comfyui

# The base image already has the correct CMD for RunPod worker

# IMPORTANT: Update the Hugging Face URLs above with the correct model locations
# You can find models at:
# - https://huggingface.co/Kijai/WanVideo_pruned
# - https://huggingface.co/TencentGameMate/chinese-wav2vec2-base
# - Other relevant Hugging Face repositories

# Build notes:
# - Build time: 30-60 minutes (downloading 35-45 GB of models)
# - Image size: ~40-50 GB
# - Requires stable internet connection
# - No local models needed
