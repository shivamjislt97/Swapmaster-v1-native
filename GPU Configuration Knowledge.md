# GPU Configuration Knowledge

Understanding how GPU auto-detection and CUDA work in SwapMaster V1.

---

## GPU Detection Flow

```
Bot starts
  → gpu_auto_detect.detect_gpu()
    → nvidia-smi --query-gpu=name,memory.total
    → Check if CUDAExecutionProvider exists in onnxruntime
    → Set env vars based on VRAM amount
    → Set LD_LIBRARY_PATH for CUDA libs
    → Disable CUDA graphs (ORT_CUDA_GRAPH=0)
```

---

## CUDA Providers (onnxruntime)

onnxruntime uses execution providers for GPU acceleration:

| Provider | GPU Type | Speed | Notes |
|----------|----------|-------|-------|
| `CUDAExecutionProvider` | NVIDIA GPU | Fastest | Required for face swap |
| `CPUExecutionProvider` | CPU | Slowest | Fallback if no GPU |

**Check available providers:**
```python
import onnxruntime as ort
print(ort.get_available_providers())
# Should include: ['CUDAExecutionProvider', 'CPUExecutionProvider']
```

---

## Model Selection by VRAM

| VRAM | Model | Size | Quality | Speed |
|------|-------|------|---------|-------|
| ≥20GB | `hyperswap_1a_256` | 256x256 | Best | Fast (6 threads) |
| 12-20GB | `hyperswap_1a_256` | 256x256 | Best | Medium (4 threads) |
| 6-12GB | `inswapper_128_fp16` | 128x128 | Good | Fast (4 threads) |
| <6GB | `inswapper_128_fp16` | 128x128 | Good | Slow (2 threads, no enhancer) |

**Why hyperswap_1a_256?**
- Higher resolution face swap (256x256 vs 128x128)
- Better face detail preservation
- Requires ≥20GB VRAM for 6 threads

---

## CUDA Graphs

CUDA graphs cache GPU operations for speed but can cause crashes:

```
ORT_CUDA_GRAPH=1  → Faster but crashes with hyperswap on some GPUs
ORT_CUDA_GRAPH=0  → Slower but stable (RECOMMENDED)
```

**When to enable:**
- Small models (inswapper_128_fp16)
- GPUs with good driver support
- If you see "CUDA graph capture failed" errors

**When to disable:**
- Using hyperswap_1a_256
- L40S, A100 (known issues)
- Random CUDA crashes

---

## Unified Memory

```
ORT_CUDA_USE_UNIFIED_MEMORY=1  → More VRAM usage, may help with large inputs
ORT_CUDA_USE_UNIFIED_MEMORY=0  → Standard VRAM usage (RECOMMENDED)
```

---

## Thread Count Impact

| Threads | VRAM Usage | Speed | GPU Load |
|---------|-----------|-------|----------|
| 2 | Low | Slow | ~40% |
| 4 | Medium | Medium | ~65% |
| 6 | High | Fast | ~85% |
| 8 | Very High | Fastest | ~100% (may crash) |

**Recommendation for L40S (46GB):** 6 threads = ~85% GPU load

---

## Common CUDA Errors

### 1. "CUDAExecutionProvider not available"
```
Cause: onnxruntime-gpu not installed or wrong CUDA version
Fix: pip install onnxruntime-gpu==1.19.2
```

### 2. "CUDA graph capture failed"
```
Cause: CUDA graphs incompatible with model/GPU
Fix: Set ORT_CUDA_GRAPH=0 in gpu_auto_detect.py
```

### 3. "out of memory"
```
Cause: Too many threads or large input
Fix: Reduce EXECUTION_THREAD_COUNT or use smaller model
```

### 4. "no kernel image available"
```
Cause: CUDA compute capability mismatch
Fix: Install correct onnxruntime-gpu version for your GPU
```

### 5. "libx264 not found"
```
Cause: ffmpeg compiled without libx264
Fix: Install static ffmpeg: ~/.local/bin/ffmpeg
```

---

## LD_LIBRARY_PATH

The bot auto-sets `LD_LIBRARY_PATH` to find CUDA libraries:

```
/home/zeus/miniconda3/envs/cloudspace/lib/python3.12/site-packages/nvidia/cublas/lib
/home/zeus/miniconda3/envs/cloudspace/lib/python3.12/site-packages/nvidia/cudnn/lib
/home/zeus/miniconda3/envs/cloudspace/lib/python3.12/site-packages/nvidia/cuda_runtime/lib
/usr/local/cuda/targets/x86_64-linux/lib
/usr/lib/x86_64-linux-gnu
```

**If CUDA fails:** Check these paths exist with `ls`

---

## Monitoring GPU Usage

```bash
# Real-time GPU monitor
nvidia-smi

# Watch GPU usage every 1 second
watch -n 1 nvidia-smi

# Check which process uses GPU
nvidia-smi --query-compute-apps=pid,name,used_memory --format=csv

# Python GPU check
python3 -c "import torch; print(f'CUDA: {torch.cuda.is_available()}, Device: {torch.cuda.get_device_name(0)}')"
```

---

## GPU Compatibility Table

| GPU | VRAM | Model | Threads | Status |
|-----|------|-------|---------|--------|
| NVIDIA L40S | 46GB | hyperswap_1a_256 | 6 | Working |
| NVIDIA A100 | 80GB | hyperswap_1a_256 | 8 | Should work |
| NVIDIA 4090 | 24GB | hyperswap_1a_256 | 6 | Should work |
| NVIDIA 4080 | 16GB | hyperswap_1a_256 | 4 | Should work |
| NVIDIA 3080 | 10GB | inswapper_128_fp16 | 4 | Should work |
| NVIDIA 3060 | 12GB | hyperswap_1a_256 | 4 | Should work |
| NVIDIA 1650 | 4GB | inswapper_128_fp16 | 2 | Minimal |
| No GPU | 0GB | inswapper_128_fp16 | 4 | CPU only |
