# SwapMaster V1 - Native Installation

FaceFusion Telegram Bot with GPU support, GDrive upload, MEGA download, and auto-sleep.

## Download

**GDrive Backup (6.4GB):** [swapmaster-v1-native-23-06-2026.tar](https://drive.google.com/open?id=1r8kRQX9FwuhRip_m3NwDXYfwh1x4bmGA)

---

## Quick Start - AI Prompt (Copy-Paste to Any AI)

```
I have a SwapMaster V1 Native project (FaceFusion Telegram Bot) backup on GDrive.
I need you to set it up completely on a new Lightning AI studio (Ubuntu, CUDA GPU).

STEP-BY-STEP COMMANDS TO EXECUTE:

# 1. Download and extract the backup
cd /teamspace/studios/this_studio
curl -L -o swapmaster.tar "https://drive.google.com/uc?id=1r8kRQX9FwuhRip_m3NwDXYfwh1x4bmGA"
tar xf swapmaster.tar
cd swapmaster-v1-native

# 2. Add ~/.local/bin to PATH (permanent + current session)
export PATH="$HOME/.local/bin:$PATH"
grep -q '.local/bin' ~/.bashrc 2>/dev/null || echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc

# 3. Install FFmpeg static build (with libx264 support)
mkdir -p ~/.local/bin
cd /tmp
curl -L -o ffmpeg.tar.xz https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-amd64-static.tar.xz
tar xf ffmpeg.tar.xz
cp ffmpeg-*-static/ffmpeg ~/.local/bin/
cp ffmpeg-*-static/ffprobe ~/.local/bin/
chmod +x ~/.local/bin/ffmpeg ~/.local/bin/ffprobe
rm -rf ffmpeg*
cd /teamspace/studios/this_studio/swapmaster-v1-native

# 4. Install rclone
curl -L -o /tmp/rclone.zip https://downloads.rclone.org/current/rclone-v1.74.3-linux-amd64.zip
cd /tmp && unzip -o rclone.zip && cp rclone-*-linux-amd64/rclone ~/.local/bin/
chmod +x ~/.local/bin/rclone
cd /teamspace/studios/this_studio/swapmaster-v1-native

# 5. Install Python dependencies
pip install --upgrade pip
pip install -r requirements.txt
pip install torch torchvision --index-url https://download.pytorch.org/whl/cu121

# 6. Create .env from template and configure
cp .env.example .env
PROJECT_DIR="$(pwd)"
sed -i "s|CHANGE_TO_YOUR_PATH.*|$PROJECT_DIR|" .env

# 7. IMPORTANT: Edit .env manually with your credentials:
#    BOT_TOKEN=your_telegram_bot_token (from @BotFather)
#    ALLOWED_USER_ID=your_telegram_user_id (from @userinfobot)
#    MEGA_EMAIL=your_mega_email (or leave dummy)
#    MEGA_PASSWORD=your_mega_password (or leave dummy)

# 8. Setup rclone for GDrive (if not already configured)
#    Run: rclone config
#    Create remote named "gdrive" with Google Drive scope

# 9. Verify encoder works
ffmpeg -encoders 2>/dev/null | grep -E "libx264|h264_qsv"
# If libx264 found: OUTPUT_VIDEO_ENCODER=libx264
# If h264_qsv found: OUTPUT_VIDEO_ENCODER=h264_qsv
# Update .env accordingly

# 10. Start the bot
export PATH="$HOME/.local/bin:$PATH"
python3 app/startup.py

# 11. Verify it works
curl http://localhost:8765/healthz
# Should return: ok
```

---

## Manual Setup (Step-by-Step)

### Step 1: Download & Extract

```bash
cd /teamspace/studios/this_studio
curl -L -o swapmaster.tar "https://drive.google.com/uc?id=1r8kRQX9FwuhRip_m3NwDXYfwh1x4bmGA"
tar xf swapmaster.tar
cd swapmaster-v1-native
```

### Step 2: PATH Setup (CRITICAL - Do This First!)

```bash
# Add ~/.local/bin to PATH for current session
export PATH="$HOME/.local/bin:$PATH"

# Make permanent (add to bashrc)
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc

# Verify
echo $PATH | grep -o ".local/bin" | head -1
# Should output: .local/bin
```

> **Why this matters:** FFmpeg and rclone are installed to `~/.local/bin`. If this path is missing, you'll get "ffmpeg not found" and "rclone not found" errors. The bot's worker subprocess also needs this PATH - it's auto-injected by `prepare_cuda_runtime_env()` in bot.py.

### Step 3: Install FFmpeg (Static Build)

```bash
# Check if already installed
~/.local/bin/ffmpeg -version 2>/dev/null | head -1
# If "command not found", install:

mkdir -p ~/.local/bin
cd /tmp
curl -L -o ffmpeg.tar.xz https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-amd64-static.tar.xz
tar xf ffmpeg.tar.xz
cp ffmpeg-*-static/ffmpeg ~/.local/bin/
cp ffmpeg-*-static/ffprobe ~/.local/bin/
chmod +x ~/.local/bin/ffmpeg ~/.local/bin/ffprobe
rm -rf ffmpeg*
cd -

# Verify libx264 support
~/.local/bin/ffmpeg -encoders 2>/dev/null | grep libx264
```

> **Important:** System `apt-get install ffmpeg` often lacks libx264. Use the static build from John Van Sickle.

### Step 4: Install rclone

```bash
# Check if already installed
rclone version 2>/dev/null | head -1
# If not found:

curl -L -o /tmp/rclone.zip https://downloads.rclone.org/current/rclone-v1.74.3-linux-amd64.zip
cd /tmp && unzip -o rclone.zip
cp rclone-*-linux-amd64/rclone ~/.local/bin/
chmod +x ~/.local/bin/rclone
rm -rf rclone*
cd -
```

### Step 5: Install Python Dependencies

```bash
pip install --upgrade pip
pip install -r requirements.txt

# PyTorch with CUDA (REQUIRED for GPU)
pip install torch torchvision --index-url https://download.pytorch.org/whl/cu121
```

### Step 6: Configure .env

```bash
cp .env.example .env
PROJECT_DIR="$(pwd)"
sed -i "s|CHANGE_TO_YOUR_PATH.*|$PROJECT_DIR|" .env
```

Then edit `.env` with your values:

```bash
nano .env
```

**Required changes in .env:**

| Variable | How to get | Example |
|----------|-----------|---------|
| `BOT_TOKEN` | @BotFather on Telegram | `123456:ABC-DEF...` |
| `ALLOWED_USER_ID` | @userinfobot on Telegram | `6267031612` |
| `RCLONE_CONF` | Auto-set by sed command above | `/teamspace/.../rclone.conf` |
| `MEGA_EMAIL` | Your MEGA account email | `you@email.com` |
| `MEGA_PASSWORD` | Your MEGA account password | `your_password` |

### Step 7: Setup rclone for GDrive

```bash
rclone config

# When prompted:
# - n) New remote
# - Name: gdrive
# - Storage: Google Drive
# - Client ID: (leave blank - press Enter)
# - Client Secret: (leave blank - press Enter)
# - Scope: 1 (full access)
# - Root folder ID: (leave blank - press Enter)
# - Service account: No
# - Edit advanced config: No
# - Auto config: Yes (opens browser, authorize access)
# - Shared with me: No
# - Team drive: No
# - y) Yes to confirm
# - q) Quit config
```

### Step 8: Start the Bot

```bash
export PATH="$HOME/.local/bin:$PATH"
python3 app/startup.py
```

### Step 9: Verify Working

```bash
# Health check
curl http://localhost:8765/healthz
# Expected: ok

# Check GPU detection in logs
# Look for: [OK] GPU: Tesla T4 (15360MB) -> cuda

# Test via Telegram
# Send face photo to bot, then send video/MEGA link
```

---

## Complete .env Reference

```env
# === REQUIRED ===
BOT_TOKEN=your_bot_token_here           # From @BotFather
ALLOWED_USER_ID=your_user_id_here       # From @userinfobot

# === MEGA ===
MEGA_EMAIL=your_mega_email@example.com  # For downloading MEGA links
MEGA_PASSWORD=your_mega_password        # MEGA account password

# === GDRIVE UPLOAD ===
GDRIVE_ENABLED=true
GDRIVE_REMOTE_NAME=gdrive               # Must match rclone remote name
GDRIVE_FOLDER=gdrive:faceswap_output    # Format: remote_name:folder_name
RCLONE_BIN=rclone
RCLONE_CONF=/full/path/to/.config/rclone/rclone.conf  # MUST be absolute path

# === GPU / FACEFUSION ===
EXECUTION_PROVIDER=cuda                 # "cuda" for GPU, "cpu" for CPU-only
GPU_ONLY_MODE=true
FACE_SWAPPER_MODEL=inswapper_128        # Options: inswapper_128, inswapper_128_fp16, hyperswap_1a_256
FACE_ENHANCER_MODEL=gfpgan_1.4          # Options: gfpgan_1.4, codeformer
FACE_ENHANCER_BLEND=80                  # 0-100, higher = more enhancement
ENABLE_FACE_ENHANCER=true
OUTPUT_VIDEO_ENCODER=h264_qsv           # Options: h264_qsv, libx264, libvpx-vp9, rawvideo
EXECUTION_THREAD_COUNT=4                # Match your CPU cores
THREAD_COUNT=4

# === BOT BEHAVIOUR ===
AUTO_SLEEP_ENABLED=true
AUTO_SLEEP_MINUTES=30
POST_JOB_AUTO_SLEEP_SECONDS=300         # Sleep after job completes
DASHBOARD_ENABLED=true
DASHBOARD_PORT=8765
BYPASS_CONTENT_ANALYSER=false

# === WATCHDOG TIMEOUTS ===
PIPELINE_WATCHDOG_PROCESSING_SEC=600    # 10 min max for processing
PIPELINE_WATCHDOG_MERGING_SEC=300       # 5 min max for merging
PIPELINE_WATCHDOG_UPLOADING_SEC=300     # 5 min max for upload
DASHBOARD_PUBLIC_URL=https://your-dashboard-url.cloudspaces.litng.ai
```

---

## Path Setup Guide

### All Paths Must Be Absolute

| Path | Variable | How to Find |
|------|----------|-------------|
| Python | - | `which python3` |
| FFmpeg | Auto-detected | `~/.local/bin/ffmpeg` |
| rclone | Auto-detected | `which rclone` |
| rclone.conf | `RCLONE_CONF` | `pwd` + `/.config/rclone/rclone.conf` |
| Project root | - | `pwd` (where `.env` is) |

### Auto-Set RCLONE_CONF Path

```bash
PROJECT_DIR="$(pwd)"
sed -i "s|RCLONE_CONF=.*|RCLONE_CONF=$PROJECT_DIR/.config/rclone/rclone.conf|" .env
```

### How PATH Flows Through the System

```
Your terminal
  └─ export PATH="$HOME/.local/bin:$PATH"
      └─ python3 app/startup.py
          └─ .env loaded (overrides os.environ)
              └─ bot.py starts worker subprocess
                  └─ worker_env = os.environ.copy()
                      └─ prepare_cuda_runtime_env() adds ~/.local/bin to PATH
                          └─ FaceFusion subprocess uses PATH
                              └─ Finds ~/.local/bin/ffmpeg (static, with libx264)
```

> **Key:** `prepare_cuda_runtime_env()` in bot.py automatically prepends `~/.local/bin` to worker subprocess PATH. This ensures static FFmpeg is used even if conda/system FFmpeg exists.

### Common Path Issues

| Error | Cause | Fix |
|-------|-------|-----|
| `ffmpeg: not found` | `~/.local/bin` not in PATH | `export PATH="$HOME/.local/bin:$PATH"` |
| `rclone: not found` | rclone not installed | Install rclone to `~/.local/bin/` |
| `rclone.conf not found` | Relative path in RCLONE_CONF | Use absolute path |
| `libx264 not found` | conda FFmpeg overriding static | Ensure `~/.local/bin` is FIRST in PATH |
| `No module named 'cv2'` | Missing opencv | `pip install opencv-python-headless` |

---

## GPU Change Guide

### Check Your GPU

```bash
nvidia-smi
# Note: GPU name and VRAM
```

### Settings by GPU

| GPU | VRAM | `EXECUTION_THREAD_COUNT` | `GPU_ONLY_MODE` | Notes |
|-----|------|--------------------------|-----------------|-------|
| Tesla T4 | 16GB | 4 | true | Current setting |
| Tesla V100 | 16GB | 4 | true | |
| Tesla V100 | 32GB | 6 | true | |
| Tesla A100 | 40GB | 6 | true | |
| Tesla A100 | 80GB | 8 | true | |
| RTX 3060 | 12GB | 2 | true | |
| RTX 3080 | 10GB | 2 | true | |
| RTX 3090 | 24GB | 4 | true | |
| RTX 4090 | 24GB | 4 | true | |
| No GPU | - | 2 | false | `EXECUTION_PROVIDER=cpu` |

### Update .env for New GPU

```bash
# Example: Switching to RTX 3060 (12GB)
sed -i 's/EXECUTION_THREAD_COUNT=4/EXECUTION_THREAD_COUNT=2/' .env

# Example: No GPU available
sed -i 's/EXECUTION_PROVIDER=cuda/EXECUTION_PROVIDER=cpu/' .env
sed -i 's/GPU_ONLY_MODE=true/GPU_ONLY_MODE=false/' .env
sed -i 's/EXECUTION_THREAD_COUNT=4/EXECUTION_THREAD_COUNT=2/' .env
```

### Check Available Encoders

```bash
# Check which encoder your FFmpeg supports
~/.local/bin/ffmpeg -encoders 2>/dev/null | grep -E "libx264|h264_qsv|h264_nvenc|libvpx-vp9"

# Update .env accordingly:
# libx264 available?     -> OUTPUT_VIDEO_ENCODER=libx264
# h264_qsv available?    -> OUTPUT_VIDEO_ENCODER=h264_qsv
# h264_nvenc available?  -> OUTPUT_VIDEO_ENCODER=h264_nvenc (not in this FaceFusion build)
# None of above?         -> OUTPUT_VIDEO_ENCODER=rawvideo
```

---

## Dependency Check & Install

### Check All Dependencies

```bash
python3 -c "
import sys
modules = {
    'telegram': 'python-telegram-bot',
    'cv2': 'opencv-python-headless',
    'numpy': 'numpy',
    'PIL': 'pillow',
    'insightface': 'insightface',
    'onnxruntime': 'onnxruntime-gpu',
    'fastapi': 'fastapi',
    'uvicorn': 'uvicorn',
    'mega': 'mega.py',
    'requests': 'requests',
    'psutil': 'psutil',
    'loguru': 'loguru',
    'dotenv': 'python-dotenv',
}
print(f'Python: {sys.version}')
for mod, pkg in modules.items():
    try:
        __import__(mod)
        print(f'OK: {pkg}')
    except ImportError:
        print(f'MISSING: {pkg} (pip install {pkg})')
"
```

### Check System Tools

```bash
# GPU
nvidia-smi 2>/dev/null || echo "NO GPU"

# CUDA
nvcc --version 2>/dev/null || echo "NO CUDA"

# FFmpeg
~/.local/bin/ffmpeg -version 2>/dev/null | head -1 || echo "NO FFMPEG"

# rclone
rclone version 2>/dev/null | head -1 || echo "NO RCLONE"
```

### Install Missing Dependencies

```bash
# All Python packages
pip install python-telegram-bot==20.7 pycryptodome==3.23.0
pip install onnxruntime-gpu==1.19.2 onnx==1.21.0 insightface==0.7.3
pip install opencv-python-headless==4.13.0.92 numpy==2.4.6 pillow==11.3.0
pip install scikit-image==0.26.0 scipy==1.17.1
pip install fastapi==0.135.1 uvicorn==0.42.0 aiofiles==24.1.0
pip install mega.py==1.0.8 gdown==6.0.0 requests==2.32.5
pip install psutil==7.2.2 loguru==0.7.3 python-dotenv==1.2.2

# PyTorch with CUDA
pip install torch torchvision --index-url https://download.pytorch.org/whl/cu121
```

---

## Testing & Verification

### Test 1: Health Check

```bash
curl http://localhost:8765/healthz
# Expected: ok
```

### Test 2: GPU Detection

```bash
python3 -c "
import torch
print(f'CUDA available: {torch.cuda.is_available()}')
if torch.cuda.is_available():
    print(f'GPU: {torch.cuda.get_device_name(0)}')
    print(f'VRAM: {torch.cuda.get_device_properties(0).total_mem / 1024**3:.1f} GB')
else:
    print('No GPU detected - will use CPU')
"
```

### Test 3: FaceFusion Import

```bash
cd app
python3 -c "from facefusion import face_analyser; print('FaceFusion OK')"
```

### Test 4: FFmpeg Encoder Test

```bash
# Test your configured encoder
ENCODER=$(grep OUTPUT_VIDEO_ENCODER .env | cut -d= -f2)
echo "Testing encoder: $ENCODER"
~/.local/bin/ffmpeg -f lavfi -i testsrc=duration=1:size=320x240:rate=30 -c:v $ENCODER -y /tmp/test.mp4 2>&1 | tail -5
# Should succeed without errors

# If it fails, try alternatives:
~/.local/bin/ffmpeg -encoders 2>/dev/null | grep -E "libx264|h264_qsv|libvpx-vp9|rawvideo"
```

### Test 5: rclone GDrive

```bash
rclone lsd gdrive:
# Should list your GDrive folders

# Test upload
echo "test" > /tmp/test_upload.txt
rclone copy /tmp/test_upload.txt gdrive:
rclone lsf gdrive: | grep test_upload
# Should show the file
rm /tmp/test_upload.txt
```

### Test 6: End-to-End Telegram Test

1. Open Telegram, find your bot
2. Send a face photo (clear face, well-lit)
3. Wait for bot to acknowledge
4. Send a video link (YouTube, MEGA, or direct MP4)
5. Wait for processing (check logs: `tail -f /tmp/swapmaster.log`)
6. Bot should send back the face-swapped video

---

## Bot Management

### Find Active Bot

```bash
# By process name
ps aux | grep "startup.py" | grep -v grep

# By port
lsof -i :8765

# By PID file
cat app/pipeline/logs/bot.pid 2>/dev/null && ps -p $(cat app/pipeline/logs/bot.pid)
```

### Kill Bot

```bash
# By PID
kill $(cat app/pipeline/logs/bot.pid 2>/dev/null)

# All startup.py processes
pkill -f "startup.py"

# Force kill
kill -9 $(pgrep -f "startup.py")
```

### Start Bot

```bash
# Foreground (for testing)
export PATH="$HOME/.local/bin:$PATH"
python3 app/startup.py

# Background (production)
export PATH="$HOME/.local/bin:$PATH"
nohup python3 app/startup.py > /tmp/swapmaster.log 2>&1 &

# Screen session
screen -S swapmaster
export PATH="$HOME/.local/bin:$PATH"
python3 app/startup.py
# Ctrl+A, D to detach

# tmux session
tmux new -s swapmaster
export PATH="$HOME/.local/bin:$PATH"
python3 app/startup.py
# Ctrl+B, D to detach
```

### Restart Bot

```bash
pkill -f "startup.py" 2>/dev/null
sleep 2
export PATH="$HOME/.local/bin:$PATH"
nohup python3 app/startup.py > /tmp/swapmaster.log 2>&1 &
```

### Check Logs

```bash
# Live logs
tail -f /tmp/swapmaster.log

# Recent logs
tail -50 /tmp/swapmaster.log

# Search for errors
grep -i "error\|fail\|exception" /tmp/swapmaster.log | tail -20
```

---

## Token Changes

### Change Telegram Bot Token

1. Get new token from @BotFather
2. Edit `.env`: `BOT_TOKEN=new_token_here`
3. Restart bot

### Change GDrive Token (rclone)

**Method 1: Re-authorize (recommended)**
```bash
rclone config
# Choose gdrive -> reconfigure -> follow browser flow
```

**Method 2: Manual token update**
```bash
# Edit rclone.conf
nano .config/rclone/rclone.conf

# Update the "token" field with new JSON:
# token = {"access_token":"ya29...","refresh_token":"1//...","token_type":"Bearer","scope":"https://www.googleapis.com/auth/drive","expires_in":3599}
```

**How GDrive token works in this project:**
- `startup.py` loads `.env` and sets `RCLONE_CONF` path
- `bot.py` reads `persistent/config.json` on startup
- If `drive_auth_token` exists in config, it overwrites `rclone.conf` with fresh token
- Token refresh happens automatically when rclone detects expiry
- If token is invalid, check `persistent/config.json` for stale token

### Change MEGA Credentials

1. Edit `.env`:
   ```
   MEGA_EMAIL=new_email@example.com
   MEGA_PASSWORD=new_password
   ```
2. Restart bot

---

## Troubleshooting

### Error: `output-video-encoder: invalid choice: 'libx264'`

This FaceFusion build doesn't support libx264. Fix:
```bash
# Check what's available
~/.local/bin/ffmpeg -encoders 2>/dev/null | grep -E "h264|hevc|vp9"

# Update encoder in .env
sed -i 's/OUTPUT_VIDEO_ENCODER=.*/OUTPUT_VIDEO_ENCODER=h264_qsv/' .env
```

### Error: `CUDA out of memory`

```bash
# Reduce thread count
sed -i 's/EXECUTION_THREAD_COUNT=4/EXECUTION_THREAD_COUNT=2/' .env

# Or switch to CPU mode
sed -i 's/EXECUTION_PROVIDER=cuda/EXECUTION_PROVIDER=cpu/' .env
sed -i 's/GPU_ONLY_MODE=true/GPU_ONLY_MODE=false/' .env
```

### Error: `ffmpeg: not found`

```bash
export PATH="$HOME/.local/bin:$PATH"
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
```

### Error: `rclone.conf not found`

```bash
PROJECT_DIR="$(pwd)"
sed -i "s|RCLONE_CONF=.*|RCLONE_CONF=$PROJECT_DIR/.config/rclone/rclone.conf|" .env
```

### Error: `No module named 'cv2'`

```bash
pip install opencv-python-headless
```

### Error: `GDrive upload fails`

```bash
# Check rclone config
rclone lsd gdrive:

# If auth error, re-authorize
rclone config

# Or check if persistent/config.json has stale token
cat app/persistent/config.json | python3 -m json.tool | grep drive_auth
```

### Bot starts but no response on Telegram

1. Check bot token: `grep BOT_TOKEN .env`
2. Check user ID: `grep ALLOWED_USER_ID .env`
3. Check bot running: `ps aux | grep startup.py`
4. Check logs: `tail -f /tmp/swapmaster.log`
5. Verify token with BotFather: `/mybots` -> select bot -> API Token

### FaceFusion exits with rc=2

```bash
# Check current encoder
grep OUTPUT_VIDEO_ENCODER .env

# Test encoder manually
ENCODER=$(grep OUTPUT_VIDEO_ENCODER .env | cut -d= -f2)
~/.local/bin/ffmpeg -f lavfi -i testsrc=duration=1:size=320x240:rate=30 -c:v $ENCODER -y /tmp/test.mp4 2>&1 | tail -5

# If fails, try rawvideo
sed -i 's/OUTPUT_VIDEO_ENCODER=.*/OUTPUT_VIDEO_ENCODER=rawvideo/' .env
```

### `persistent/config.json` overwriting rclone.conf

The bot auto-restores GDrive token from `persistent/config.json` on startup. If you manually edited `rclone.conf`, the bot may overwrite it. To prevent this:
```bash
# Option 1: Update persistent config instead
nano app/persistent/config.json
# Update "drive_auth_token" field

# Option 2: Clear stale token
python3 -c "
import json
cfg = json.load(open('app/persistent/config.json'))
cfg.pop('drive_auth_token', None)
json.dump(cfg, open('app/persistent/config.json', 'w'), indent=2)
print('Token cleared from persistent config')
"
```

### FFmpeg using conda version instead of static

If you see conda FFmpeg being used (lacks libx264), ensure `~/.local/bin` is FIRST in PATH:
```bash
# Check which ffmpeg is being used
which ffmpeg
# Should be: /home/user/.local/bin/ffmpeg

# Fix: ensure ~/.local/bin is first
export PATH="$HOME/.local/bin:$PATH"
```

---

## Project Structure

```
swapmaster-v1-native/
├── .env                    # Your config (BOT_TOKEN, paths, etc.) - DO NOT commit
├── .env.example            # Config template
├── .config/rclone/         # rclone config for GDrive
│   └── rclone.conf         # GDrive auth token (auto-managed by bot)
├── auto_setup.sh           # One-command auto setup
├── requirements.txt        # Python dependencies
├── README.md               # This file
├── SETTINGS_USED.md        # All face swap settings reference
├── setup.sh / setup.bat    # Manual setup scripts
├── run.sh / run.bat        # Bot start scripts
└── app/
    ├── startup.py           # Main entry point - loads .env, validates, starts bot
    ├── bot.py               # Telegram bot logic (~14K lines)
    ├── health_check.py      # Health endpoint (localhost:8765/healthz)
    ├── config/
    │   └── credentials.py   # Config loader - auto-adds gdrive: prefix
    ├── ops/
    │   ├── gpu_auto_detect.py
    │   ├── process_guard.py
    │   └── ... (other ops)
    ├── facefusion/
    │   ├── facefusion.py    # FaceFusion entry
    │   ├── .assets/models/  # ONNX models (~3.2GB)
    │   └── ... (FaceFusion code)
    ├── persistent/
    │   ├── config.json      # Runtime config (stores GDrive token)
    │   └── faces/           # Uploaded face photos
    ├── pipeline/
    │   ├── logs/            # Runtime logs
    │   ├── workspace/       # Temp processing files
    │   └── dashboard_sessions/
    ├── scripts/
    │   └── gdrive_upload.py
    └── faceswap_output/     # Output files
```

---

## License

Private project. All rights reserved.
