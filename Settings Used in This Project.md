# Settings Used in This Project

All current configuration values for SwapMaster V1 Native on Lightning AI Studio.

---

## Environment (.env)

| Setting | Value | Description |
|---------|-------|-------------|
| `BOT_TOKEN` | `YOUR_BOT_TOKEN` | Telegram bot token from @BotFather |
| `ALLOWED_USER_ID` | `YOUR_TELEGRAM_USER_ID` | Your Telegram user ID |
| `MEGA_EMAIL` | `YOUR_MEGA_EMAIL` | MEGA account for downloading user-sent MEGA links |
| `MEGA_PASSWORD` | `YOUR_MEGA_PASSWORD` | MEGA password |
| `GDRIVE_ENABLED` | `true` | Enable Google Drive upload after each job |
| `GDRIVE_REMOTE_NAME` | `gdrive` | rclone remote name |
| `GDRIVE_FOLDER` | `gdrive:faceswap_output` | GDrive folder path for uploads |
| `RCLONE_BIN` | `rclone` | Path to rclone binary |
| `RCLONE_CONF` | `/teamspace/studios/this_studio/swapmaster-v1-native/.config/rclone/rclone.conf` | rclone config path |
| `EXECUTION_PROVIDER` | `cuda` | GPU acceleration (auto-detected) |
| `GPU_ONLY_MODE` | `true` | Skip CPU fallback, GPU required |
| `FACE_SWAPPER_MODEL` | `inswapper_128` | Base model (overridden by GPU auto-detect) |
| `FACE_ENHANCER_MODEL` | `gfpgan_1.4` | Face enhancement model |
| `FACE_ENHANCER_BLEND` | `80` | Enhancer blend percentage (0-100) |
| `ENABLE_FACE_ENHANCER` | `true` | Enable GFPGAN face enhancement |
| `OUTPUT_VIDEO_ENCODER` | `libx264` | Video encoder (software, CUDA-compatible) |
| `EXECUTION_THREAD_COUNT` | `6` | GPU processing threads |
| `THREAD_COUNT` | `6` | General thread count |
| `AUTO_SLEEP_ENABLED` | `true` | Auto-sleep after inactivity |
| `AUTO_SLEEP_MINUTES` | `30` | Minutes of inactivity before auto-sleep |
| `POST_JOB_AUTO_SLEEP_SECONDS` | `120` | Seconds to wait after job completes before sleeping |
| `DASHBOARD_ENABLED` | `true` | Enable web dashboard |
| `DASHBOARD_PORT` | `8765` | Dashboard port |
| `BYPASS_CONTENT_ANALYSER` | `false` | Content safety check enabled |
| `PIPELINE_WATCHDOG_PROCESSING_SEC` | `600` | Max processing time before watchdog kill |
| `PIPELINE_WATCHDOG_MERGING_SEC` | `300` | Max merge time before watchdog kill |
| `PIPELINE_WATCHDOG_UPLOADING_SEC` | `300` | Max upload time before watchdog kill |

---

## GPU Auto-Detect (gpu_auto_detect.py)

The bot auto-detects GPU and overrides `.env` values:

| GPU VRAM | Model | Threads | Enhancer | Encoder |
|----------|-------|---------|----------|---------|
| ≥ 20 GB (L40S, A100, 4090) | `hyperswap_1a_256` | 6 | ON | `libx264` |
| ≥ 12 GB (3080, 4070Ti) | `hyperswap_1a_256` | 4 | ON | `libx264` |
| ≥ 6 GB (3060, 4060) | `inswapper_128_fp16` | 4 | ON | `libx264` |
| < 6 GB (GTX 1650) | `inswapper_128_fp16` | 2 | OFF | `libx264` |
| No GPU (CPU only) | `inswapper_128_fp16` | 4 | ON | `libx264` |

**Additional CUDA settings:**
- `ORT_CUDA_GRAPH=0` — Disabled (causes crashes with hyperswap)
- `ORT_CUDA_USE_UNIFIED_MEMORY=0` — Disabled (reduces VRAM usage)
- `LD_LIBRARY_PATH` — Auto-set to include nvidia CUDA libraries

---

## Persistent Config (app/persistent/config.json)

| Setting | Value | Description |
|---------|-------|-------------|
| `mega_email` | `YOUR_MEGA_EMAIL` | MEGA account (persistent) |
| `mega_password` | `YOUR_MEGA_PASSWORD` | MEGA password (persistent) |
| `drive_auth_token.refresh_token` | `YOUR_REFRESH_TOKEN` | GDrive OAuth refresh token |
| `face_selector_prefs.USER_ID.gender_mode` | `female` | Default face selector gender |

---

## Output Filenames

All outputs use timestamp format to prevent overwrites:

| Type | Filename Format | Example |
|------|----------------|---------|
| Main swap | `swapped_<original>_DDMMYY_HHMMSS.jpg` | `swapped_photo_280626_143025.jpg` |
| Selective swap | `swapped_selective_<original>_DDMMYY_HHMMSS.jpg` | `swapped_selective_video_280626_143025.mp4` |
| Segment swap | `swapped_segment_<original>_DDMMYY_HHMMSS.jpg` | `swapped_segment_img_280626_143025.jpg` |
| Normalize | `normalized_<original>_DDMMYY_HHMMSS.jpg` | `normalized_photo_280626_143025.jpg` |

---

## Process Management

| Component | Behavior |
|-----------|----------|
| `process_guard.py` | Watchdog that auto-restarts bot if it crashes |
| Auto-sleep | After `POST_JOB_AUTO_SLEEP_SECONDS=120` seconds of inactivity |
| Token refresh | GDrive token auto-refreshed before every upload |
| NGROK tunnel | Dashboard accessible via ngrok public URL |

---

## Key Paths

| Path | Purpose |
|------|---------|
| `/teamspace/studios/this_studio/swapmaster-v1-native/` | Project root |
| `/teamspace/studios/this_studio/swapmaster-v1-native/.env` | Main config |
| `/teamspace/studios/this_studio/swapmaster-v1-native/app/bot.py` | Main bot code |
| `/teamspace/studios/this_studio/swapmaster-v1-native/app/ops/gpu_auto_detect.py` | GPU detection |
| `/teamspace/studios/this_studio/swapmaster-v1-native/app/persistent/config.json` | Persistent state |
| `/teamspace/studios/this_studio/swapmaster-v1-native/.config/rclone/rclone.conf` | GDrive auth |
| `/teamspace/studios/this_studio/swapmaster-v1-native/.local/bin/ffmpeg` | FFmpeg with libx264 |
| `/home/zeus/.ngrok/ngrok.yml` | ngrok config |
