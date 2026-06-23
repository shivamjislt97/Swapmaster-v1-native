# Settings Used in This Project

All face swap settings currently configured. Copy-paste ready for `.env` or config.

---

## Face Swap Settings (.env)

```env
# === GPU / FACEFUSION ===
EXECUTION_PROVIDER=cuda
GPU_ONLY_MODE=true
FACE_SWAPPER_MODEL=inswapper_128
FACE_ENHANCER_MODEL=gfpgan_1.4
FACE_ENHANCER_BLEND=80
ENABLE_FACE_ENHANCER=true
OUTPUT_VIDEO_ENCODER=h264_qsv
EXECUTION_THREAD_COUNT=4
THREAD_COUNT=4
```

---

## Face Swap Hardcoded Settings (in bot.py)

These are hardcoded in the bot code and NOT configurable via .env:

| Setting | Value | Description |
|---------|-------|-------------|
| `face_swapper_pixel_boost` | `512x512` | Resolution for face swap |
| `face_swapper_weight` | `0.85` | How much of the swapped face to apply |
| `face_enhancer_weight` | `0.70` | Enhancement strength |
| `face_mask_blur` | `0.3` | Blur amount on face mask edges |
| `face_mask_padding` | `0, 0, 0, 0` | Top, Right, Bottom, Left padding |
| `face_detector_size` | `640x640` | Face detection resolution |
| `face_detector_score` | `0.50` | Minimum confidence for face detection |
| `face_landmarker_score` | `0.35` | Minimum confidence for landmarks |
| `face_detector_model` | `yolo_face` | Face detection model |
| `face_selector_mode` | `reference` | Use reference face for matching |
| `reference_face_position` | `0` | Which face to use as reference |
| `reference_face_distance` | `0.30` | Max distance for face matching |
| `reference_frame_number` | `0` | Frame number for reference |
| `video_memory_strategy` | `tolerant` | GPU memory usage strategy |
| `output_image_quality` | `95` | JPEG quality for images |
| `output_audio_encoder` | `aac` | Audio encoding format |
| `temp_frame_format` | `jpeg` | Temp frame format |
| `processors` | `face_swapper, expression_restorer, face_enhancer` | Active processors |

---

## Expression Restorer Settings

| Setting | Value |
|---------|-------|
| `ENABLE_EXPRESSION_RESTORER` | `true` |
| `EXPRESSION_RESTORER_FACTOR` | `90` |

---

## GPU Retry Profile (on OOM)

| Level | Changes |
|-------|---------|
| Level 1 | `video_memory_strategy=strict` |
| Level 2 | `execution_thread_count=2`, `pixel_boost=256x256` |
| Level 3 | `execution_thread_count=1`, `pixel_boost=256x256`, processors=`[face_swapper]` only |

---

## Upload Settings (.env)

```env
# === GDRIVE UPLOAD (rclone) ===
GDRIVE_ENABLED=true
GDRIVE_REMOTE_NAME=gdrive
GDRIVE_FOLDER=gdrive:faceswap_output
RCLONE_BIN=rclone
RCLONE_CONF=/teamspace/studios/this_studio/swapmaster-v1-native/.config/rclone/rclone.conf
```

---

## MEGA Settings (.env)

```env
# === MEGA (for downloading user-sent MEGA links) ===
MEGA_EMAIL=dummy@example.com
MEGA_PASSWORD=dummypassword123
```

---

## Bot Behavior Settings (.env)

```env
# === BOT BEHAVIOUR ===
AUTO_SLEEP_ENABLED=true
AUTO_SLEEP_MINUTES=30
POST_JOB_AUTO_SLEEP_SECONDS=300
DASHBOARD_ENABLED=true
DASHBOARD_PORT=8765
BYPASS_CONTENT_ANALYSER=false
```

---

## Watchdog Timeout Settings (.env)

```env
PIPELINE_WATCHDOG_PROCESSING_SEC=600
PIPELINE_WATCHDOG_MERGING_SEC=300
PIPELINE_WATCHDOG_UPLOADING_SEC=300
```

---

## Memory Management Settings (bot.py defaults)

| Setting | Value | Description |
|---------|-------|-------------|
| `LOW_MEMORY_MODE` | `true` | Enable low memory optimizations |
| `LOW_MEMORY_THREAD_COUNT` | `2` | Threads in low memory mode |
| `CPU_THREAD_UTILIZATION_PCT` | `75` | CPU thread utilization |
| `GPU_STARTUP_BALANCED_MODE` | `true` | Balanced GPU startup |
| `GPU_STARTUP_THREAD_COUNT` | `2` | GPU startup threads |
| `GPU_STARTUP_FACE_DETECTOR_SIZE` | `640x640` | Detector size at startup |
| `GPU_STARTUP_PIXEL_BOOST` | `512x512` | Pixel boost at startup |
| `GPU_STARTUP_VIDEO_MEMORY_STRATEGY` | `tolerant` | Memory strategy at startup |
| `GPU_OOM_MAX_LEVELS` | `3` | Max OOM retry levels |
| `GPU_RETRY_CHUNK_SECONDS_L2` | `8` | Retry delay level 2 |
| `GPU_RETRY_CHUNK_SECONDS_L3` | `4` | Retry delay level 3 |
| `FACEFUSION_WATCHDOG_SEC` | `60` | FaceFusion watchdog timeout |
| `AUTO_CPU_FALLBACK_ON_OOM` | `false` | Auto CPU fallback disabled |

---

## Supported Video Encoders

| Encoder | Type | Notes |
|---------|------|-------|
| `h264_qsv` | Intel QSV | **Currently used** - Hardware encoding |
| `hevc_qsv` | Intel QSV | H.265 hardware encoding |
| `libvpx-vp9` | Software | VP9 software encoding |
| `rawvideo` | None | No compression |

> **Note:** `libx264` and `h264_nvenc` are NOT available in this FaceFusion build.

---

## System Requirements

| Component | Minimum | Current |
|-----------|---------|---------|
| GPU | CUDA-capable GPU | Tesla T4 (15GB VRAM) |
| CUDA | 11.0+ | 13.0 |
| Python | 3.10+ | 3.12.11 |
| FFmpeg | 5.0+ | 7.0.2-static |
| RAM | 8GB+ | - |
| Disk | 10GB+ | - |
