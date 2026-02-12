# RunPod 部署完整指南

## 🎯 概述

这个指南将帮你在 RunPod 上部署 InfiniteTalk ComfyUI。RunPod 版本的特点：

- ✅ **轻量镜像** - 5-8 GB（不包含模型）
- ✅ **快速构建** - 5-10 分钟
- ✅ **网络存储** - 模型存储在 RunPod 网络存储中
- ✅ **灵活扩展** - 可以随时更换模型

## 📋 前置要求

1. **Docker Hub 账号** - 用于存储镜像
2. **RunPod 账号** - 用于部署
3. **本地已有模型** - 约 35-45 GB

## 🚀 部署步骤

### 步骤 1: 构建并推送镜像

```bash
cd /home/comfyui/ComfyUI/runpod

# 构建并推送到 Docker Hub
./build-runpod.sh YOUR_DOCKERHUB_USERNAME --push

# 例如：
# ./build-runpod.sh johndoe --push
```

**预计时间**: 5-10 分钟（不下载模型）

**输出镜像**: `YOUR_USERNAME/infinitetalk-comfyui:runpod`

---

### 步骤 2: 准备模型文件

#### 方法 A: 打包本地模型

```bash
# 1. 确保模型已复制到 ./models/
./copy-models.sh
./verify-models.sh

# 2. 打包模型（用于上传）
cd models
tar -czf ../infinitetalk-models.tar.gz .
cd ..

# 3. 模型包大小约 35-45 GB
ls -lh infinitetalk-models.tar.gz
```

#### 方法 B: 直接使用现有模型

如果你已经在 RunPod 上有模型，可以跳过打包步骤。

---

### 步骤 3: 上传模型到 RunPod 网络存储

#### 3.1 创建网络存储

1. 登录 RunPod: https://runpod.io
2. 进入 **Storage** → **Network Volumes**
3. 点击 **+ New Network Volume**
4. 配置:
   - Name: `infinitetalk-models`
   - Size: **60 GB** (推荐)
   - Region: 选择你常用的区域
5. 点击 **Create**

#### 3.2 上传模型

**方法 1: 通过临时 Pod 上传**

```bash
# 1. 在 RunPod 创建一个临时 Pod
#    - 选择任意 GPU
#    - 挂载你创建的网络存储到 /workspace
#    - 启动 Pod

# 2. 通过 SSH 连接到 Pod
#    RunPod 会提供 SSH 命令，类似：
#    ssh root@<pod-id>.runpod.io -p <port>

# 3. 在 Pod 中创建目录
mkdir -p /workspace/models

# 4. 从本地上传模型包
#    在本地终端运行：
scp -P <port> infinitetalk-models.tar.gz root@<pod-id>.runpod.io:/workspace/

# 5. 在 Pod 中解压
cd /workspace
tar -xzf infinitetalk-models.tar.gz -C models/
rm infinitetalk-models.tar.gz

# 6. 验证模型结构
ls -la /workspace/models/
```

**方法 2: 使用 RunPod 文件管理器**

1. 启动临时 Pod 并挂载网络存储
2. 使用 RunPod 的 Web 文件管理器上传文件
3. 注意：大文件上传可能较慢

#### 3.3 验证模型结构

确保模型目录结构正确：

```
/workspace/models/
├── transformers/
│   └── TencentGameMate/
│       └── chinese-wav2vec2-base/
│           ├── config.json
│           ├── preprocessor_config.json
│           └── pytorch_model.bin
├── diffusion_models/
│   └── Wan2.1/
│       ├── Wan2_1-InfiniTetalk-Single_fp16.safetensors
│       └── wan2.1_i2v_480p_14B_fp8_e4m3fn.safetensors
├── vae/
│   └── Wan2_1_VAE_bf16.safetensors
├── clip_vision/
│   └── clip_vision_h.safetensors
├── text_encoders/
│   └── umt5_xxl_fp16.safetensors
└── loras/
    └── wan/
        ├── Wan21_I2V_14B_lightx2v_cfg_step_distill_lora_rank64.safetensors
        └── Wan_2_1_T2V_14B_480p_rCM_lora_average_rank_83_bf16.safetensors
```

---

### 步骤 4: 创建 RunPod 模板

1. 进入 **Templates** → **New Template**

2. 配置模板:

   **基本设置:**
   - Template Name: `InfiniteTalk ComfyUI`
   - Container Image: `YOUR_USERNAME/infinitetalk-comfyui:runpod`
   - Docker Command: (留空，使用默认)

   **存储设置:**
   - Container Disk: **25 GB**
   - Volume Mount Path: `/workspace/models`
   - Volume Mount: 选择你创建的 `infinitetalk-models`

   **网络设置:**
   - Expose HTTP Ports: `8188`
   - Expose TCP Ports: (留空)

   **环境变量:**（可选）
   ```
   COMFYUI_PORT=8188
   ```

3. 点击 **Save Template**

---

### 步骤 5: 部署 Pod

1. 进入 **Pods** → **+ Deploy**

2. 选择配置:
   - **Template**: 选择你创建的 `InfiniteTalk ComfyUI`
   - **GPU**: 推荐选择
     - RTX 4090 (24GB) - 性价比高
     - A100 (40GB/80GB) - 性能最好
     - RTX 3090 (24GB) - 经济选择
   - **Region**: 选择延迟最低的区域

3. 点击 **Deploy**

4. 等待 Pod 启动（约 1-2 分钟）

---

### 步骤 6: 访问 ComfyUI

1. Pod 启动后，点击 **Connect**

2. 选择 **HTTP Service [Port 8188]**

3. 浏览器会打开 ComfyUI 界面

4. 上传你的工作流 JSON 文件

5. 开始生成！

---

## 🔧 配置优化

### GPU 选择建议

| GPU | VRAM | 性能 | 价格 | 推荐场景 |
|-----|------|------|------|----------|
| RTX 4090 | 24GB | ⭐⭐⭐⭐ | $$ | 最佳性价比 |
| A100 40GB | 40GB | ⭐⭐⭐⭐⭐ | $$$ | 高性能需求 |
| A100 80GB | 80GB | ⭐⭐⭐⭐⭐ | $$$$ | 超大模型 |
| RTX 3090 | 24GB | ⭐⭐⭐ | $ | 预算有限 |

### 网络存储优化

- **持久化存储**: 模型存储在网络存储中，Pod 删除后模型仍然保留
- **多 Pod 共享**: 多个 Pod 可以共享同一个网络存储
- **快照备份**: 定期创建网络存储快照

---

## 📊 成本估算

### 一次性成本
- 网络存储 (60GB): ~$3-5/月
- Docker Hub (免费): $0

### 运行成本（按小时计费）
- RTX 4090: ~$0.50-0.70/小时
- A100 40GB: ~$1.50-2.00/小时
- A100 80GB: ~$2.50-3.50/小时

### 节省成本技巧
1. **按需使用**: 用完立即停止 Pod
2. **Spot 实例**: 使用 Spot 价格（便宜 50-70%）
3. **区域选择**: 不同区域价格不同
4. **批量处理**: 一次性处理多个任务

---

## 🐛 故障排除

### 问题 1: Pod 启动失败

**可能原因:**
- 镜像拉取失败
- 网络存储未正确挂载

**解决方案:**
```bash
# 检查 Pod 日志
# 在 RunPod 界面点击 Pod → Logs

# 验证镜像存在
docker pull YOUR_USERNAME/infinitetalk-comfyui:runpod

# 检查网络存储挂载
# 在 Pod 终端运行:
ls -la /comfyui/models/
```

### 问题 2: 模型加载失败

**可能原因:**
- 模型文件路径不正确
- 模型文件损坏

**解决方案:**
```bash
# 进入 Pod 终端
# 检查模型文件
ls -lh /comfyui/models/diffusion_models/Wan2.1/
ls -lh /comfyui/models/transformers/TencentGameMate/chinese-wav2vec2-base/

# 验证文件大小
du -sh /comfyui/models/*
```

### 问题 3: ComfyUI 无法访问

**可能原因:**
- 端口未正确暴露
- 服务未启动

**解决方案:**
```bash
# 检查服务状态
ps aux | grep python

# 检查端口
netstat -tlnp | grep 8188

# 重启服务（如果需要）
cd /comfyui
python main.py --listen 0.0.0.0 --port 8188
```

### 问题 4: 显存不足

**解决方案:**
- 启用 `force_offload` 和 `tiled_vae`
- 减少 `frame_window_size`
- 降低分辨率
- 使用更大 VRAM 的 GPU

---

## 📝 最佳实践

### 1. 开发流程

```
本地开发 → 本地测试 → 构建镜像 → RunPod 部署 → 生产使用
```

### 2. 模型管理

- 使用版本控制管理模型
- 定期备份网络存储
- 记录模型版本和配置

### 3. 成本控制

- 开发时使用本地环境
- 生产时使用 RunPod
- 设置自动停止时间
- 监控使用情况

### 4. 安全建议

- 不要在镜像中包含敏感信息
- 使用环境变量传递配置
- 定期更新依赖包
- 限制网络访问

---

## 🔄 更新流程

### 更新代码

```bash
# 1. 修改代码
# 2. 重新构建镜像
./build-runpod.sh YOUR_USERNAME --push

# 3. 在 RunPod 重启 Pod
#    Pod 会自动拉取最新镜像
```

### 更新模型

```bash
# 1. 启动临时 Pod
# 2. 连接到 Pod
# 3. 替换模型文件
cp new_model.safetensors /workspace/models/diffusion_models/Wan2.1/

# 4. 重启使用该存储的 Pod
```

---

## 📚 相关资源

- **RunPod 文档**: https://docs.runpod.io/
- **ComfyUI**: https://github.com/comfyanonymous/ComfyUI
- **WanVideo**: https://github.com/kijai/ComfyUI-WanVideoWrapper
- **Docker Hub**: https://hub.docker.com/

---

## ✅ 部署检查清单

部署前确认:
- [ ] Docker Hub 账号已创建
- [ ] 镜像已成功推送
- [ ] RunPod 账号已创建并充值
- [ ] 网络存储已创建（60GB+）
- [ ] 模型已上传到网络存储
- [ ] 模型目录结构正确
- [ ] 模板已创建并配置正确

部署后验证:
- [ ] Pod 成功启动
- [ ] ComfyUI 界面可访问
- [ ] 模型正确加载
- [ ] 工作流可以运行
- [ ] 生成结果正常

---

## 🎉 完成！

如果一切顺利，你现在应该有一个运行在 RunPod 上的 InfiniteTalk ComfyUI 实例了！

**下一步**: 上传你的工作流和素材，开始创作！

---

**需要帮助？** 查看 TROUBLESHOOTING.md 或在 GitHub 提 Issue。
