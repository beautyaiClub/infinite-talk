# RunPod Dockerfile for InfiniteTalk V2 Workflow
# Downloads all models from Hugging Face during build

FROM runpod/worker-comfyui:5.5.1-base

# Install system dependencies including build tools for triton/sageattention
RUN apt-get update && apt-get install -y \
    ffmpeg \
    libsndfile1 \
    wget \
    curl \
    build-essential \
    gcc \
    g++ \
    && rm -rf /var/lib/apt/lists/*

# Debug: Check what CUDA libraries are available in the base image
RUN echo "=== Checking CUDA installation ===" && \
    find /usr -name "libcuda*" 2>/dev/null || echo "No libcuda found in /usr" && \
    find /opt -name "libcuda*" 2>/dev/null || echo "No libcuda found in /opt" && \
    ls -la /usr/local/cuda* 2>/dev/null || echo "No /usr/local/cuda directory" && \
    echo "=== End CUDA check ==="

# Force cache bust for comfyui-beautyai - Updated: 2026-02-14 (refactored to modular structure)
RUN git clone https://github.com/beautyaiClub/comfyui-beautyai.git -b main /comfyui/custom_nodes/comfyui-beautyai
RUN git clone https://github.com/christian-byrne/audio-separation-nodes-comfyui.git /comfyui/custom_nodes/audio-separation-nodes-comfyui && \
    cd /comfyui/custom_nodes/audio-separation-nodes-comfyui && \
    pip install --no-cache-dir -r requirements.txt
RUN comfy node install --exit-on-fail comfyui-various
RUN comfy node install --exit-on-fail ComfyUI-WanVideoWrapper@1.4.7
RUN comfy node install --exit-on-fail ComfyUI_Comfyroll_CustomNodes
RUN comfy node install --exit-on-fail comfyui_layerstyle@2.0.38
RUN comfy node install --exit-on-fail comfyui-kjnodes@1.2.9

# Install additional Python dependencies (not in requirements.txt)
RUN pip install --no-cache-dir \
    av \
    torchaudio \
    scipy \
    sageattention

# Create directory structure for models
RUN mkdir -p /comfyui/models/transformers/TencentGameMate/chinese-wav2vec2-base && \
    mkdir -p /comfyui/models/diffusion_models/Wan2.1 && \
    mkdir -p /comfyui/models/vae && \
    mkdir -p /comfyui/models/clip_vision && \
    mkdir -p /comfyui/models/text_encoders && \
    mkdir -p /comfyui/models/loras/wan

# Download Wav2Vec Chinese model (3 files)
RUN cd /comfyui/models/transformers/TencentGameMate/chinese-wav2vec2-base && \
    wget -q https://huggingface.co/TencentGameMate/chinese-wav2vec2-base/resolve/main/config.json && \
    wget -q https://huggingface.co/TencentGameMate/chinese-wav2vec2-base/resolve/main/preprocessor_config.json && \
    wget -q https://huggingface.co/TencentGameMate/chinese-wav2vec2-base/resolve/main/pytorch_model.bin

# Download InfiniteTalk model (5.13 GB)
RUN comfy model download \
    --url https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/InfiniteTalk/Wan2_1-InfiniTetalk-Single_fp16.safetensors \
    --relative-path models/diffusion_models/Wan2.1 \
    --filename Wan2_1-InfiniTetalk-Single_fp16.safetensors

# Download WanVideo Main model (14B) - ~20GB
RUN comfy model download \
    --url https://huggingface.co/PJMixers-Images/wan2.1_i2v_480p_720p_14B_fp8_e4m3fn/resolve/main/wan2.1_i2v_480p_720p_14B_fp8_e4m3fn.safetensors \
    --relative-path models/diffusion_models/Wan2.1 \
    --filename wan2.1_i2v_480p_14B_fp8_e4m3fn.safetensors

# Download VAE model (~254 MB)
RUN comfy model download \
    --url https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/Wan2_1_VAE_bf16.safetensors \
    --relative-path models/vae \
    --filename Wan2_1_VAE_bf16.safetensors

# Download CLIP Vision model
RUN comfy model download \
    --url https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/clip_vision/clip_vision_h.safetensors \
    --relative-path models/clip_vision \
    --filename clip_vision_h.safetensors

# Download T5 text encoder (~10-15 GB)
RUN comfy model download \
    --url https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/text_encoders/umt5_xxl_fp16.safetensors \
    --relative-path models/text_encoders \
    --filename umt5_xxl_fp16.safetensors

# Download LoRA 1
RUN comfy model download \
    --url https://huggingface.co/lgylgy/Wan21_I2V_14B_lightx2v_cfg_step_distill_lora_rank64/resolve/main/Wan21_I2V_14B_lightx2v_cfg_step_distill_lora_rank64.safetensors \
    --relative-path models/loras/wan \
    --filename Wan21_I2V_14B_lightx2v_cfg_step_distill_lora_rank64.safetensors

# Download LoRA 2
RUN comfy model download \
    --url https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/LoRAs/rCM/Wan_2_1_T2V_14B_480p_rCM_lora_average_rank_83_bf16.safetensors \
    --relative-path models/loras/wan \
    --filename Wan_2_1_T2V_14B_480p_rCM_lora_average_rank_83_bf16.safetensors

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
