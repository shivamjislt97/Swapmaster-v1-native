# SwapMaster V1 - Native Installation

FaceFusion Telegram Bot with GPU support, GDrive upload, MEGA download, and auto-sleep.

## Download

**GDrive Backup (3.1GB):** [SwapMaster V1 Native Backup](https://drive.google.com/drive/folders/YOUR_FOLDER_ID)

Extract the zip to get the full project with all models, configs, and code.

---

## Quick Start (AI Prompt)

Copy-paste this prompt to any AI assistant to auto-setup everything:

```
I have a SwapMaster V1 Native project (FaceFusion Telegram Bot). I need you to set it up on a new Lightning AI studio (Ubuntu, CUDA GPU).

Steps to execute:
1. Extract the project zip to the working directory
2. Run: chmod +x auto_setup.sh && ./auto_setup.sh
3. Edit .env file: set BOT_TOKEN, ALLOWED_USER_ID, RCLONE_CONF path
4. Setup rclone for GDrive: run "rclone config" and create remote named "gdrive"
5. Start bot: export PATH="$HOME/.local/bin:$PATH" && python3 app/startup.py

Requirements:
- Python 3.10+, CUDA GPU, internet access
- Bot token from @BotFather
- Your Telegram user ID from @userinfobot

Key paths in .env:
- RCLONE_CONF=/full/path/to/swapmaster-v1-native/.config/rclone/rclone.conf
- OUTPUT_VIDEO_ENCODER=h264_qsv (for Intel QSV) or libx264 (if available)
- EXECUTION_PROVIDER=cuda

Verify working: curl http://localhost:8765/healthz (should return "ok")
```

---

## Manual Setup

### Step 1: Extract Backup

```bash
# Download from GDrive, then:
cd /teamspace/studios/this_studio
tar xzf swapmaster-v1-native-23-06-2026.tar.gz
cd swapmaster-v1-native
```

### Step 2: Install System Dependencies

```bash
# Add ~/.local/bin to PATH (for FFmpeg and rclone)
export PATH="$HOME/.local/bin:$PATH"
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc

# FFmpeg (static build with libx264)
mkdir -p ~/.local/bin
cd /tmp
curl -L -o ffmpeg.tar.xz https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-amd64-static.tar.xz
tar xf ffmpeg.tar.xz
cp ffmpeg-*-static/ffmpeg ~/.local/bin/
cp ffmpeg-*-static/ffprobe ~/.local/bin/
chmod +x ~/.local/bin/ffmpeg ~/.local/bin/ffprobe
rm -rf ffmpeg*
cd -

# rclone
curl -s https://rclone.org/install.sh | sudo bash
# OR if no sudo:
curl -L -o /tmp/rclone.zip https://downloads.rclone.org/current/rclone-v1.74.3-linux-amd64.zip
cd /tmp && unzip -o rclone.zip && cp rclone-*-linux-amd64/rclone ~/.local/bin/
chmod +x ~/.local/bin/rclone
cd -
```

### Step 3: Install Python Dependencies

```bash
pip install --upgrade pip
pip install -r requirements.txt

# PyTorch with CUDA
pip install torch torchvision --index-url https://download.pytorch.org/whl/cu121
```

### Step 4: Configure .env

```bash
cp .env.example .env
nano .env  # Edit with your values
```

Required changes:
- `BOT_TOKEN` - Get from @BotFather on Telegram
- `ALLOWED_USER_ID` - Your Telegram user ID (get from @userinfobot)
- `RCLONE_CONF` - Full path to `.config/rclone/rclone.conf`

### Step 5: Setup rclone for GDrive

```bash
# Interactive setup
rclone config

# When prompted:
# - Name: gdrive
# - Type: Google Drive
# - Client ID: (leave blank)
# - Client Secret: (leave blank)
# - Scope: 1 (full access)
# - Root folder ID: (leave blank)
# - Service account: No
# - Edit advanced config: No
# - Auto config: Yes (opens browser)
# - Shared with me: No
# - Team drive: No
```

### Step 6: Start the Bot

```bash
export PATH="$HOME/.local/bin:$PATH"
python3 app/startup.py
```

---

## Path Setup Guide

All paths must be absolute. Here's how to set them:

### Finding Your Paths

```bash
# Find Python
which python3
# Output: /usr/bin/python3 or /opt/conda/bin/python3

# Find FFmpeg
which ffmpeg
# Output: ~/.local/bin/ffmpeg or /usr/bin/ffmpeg

# Find rclone
which rclone
# Output: /usr/bin/rclone or ~/.local/bin/rclone

# Find project root (where .env is)
pwd
# Output: /teamspace/studios/this_studio/swapmaster-v1-native
```

### Setting Paths in .env

```bash
# Get absolute path of project
PROJECT_DIR="$(pwd)"

# Set in .env
sed -i "s|RCLONE_CONF=.*|RCLONE_CONF=$PROJECT_DIR/.config/rclone/rclone.conf|" .env
```

### Common Path Issues

| Error | Fix |
|-------|-----|
| `ffmpeg: not found` | Add `~/.local/bin` to PATH |
| `rclone: not found` | Install rclone or add to PATH |
| `rclone.conf not found` | Use absolute path in RCLONE_CONF |
| `No module named 'cv2'` | Run `pip install opencv-python-headless` |
| `CUDA out of memory` | Reduce EXECUTION_THREAD_COUNT to 2 |

---

## GPU Change Guide

If you switch to a different GPU:

### Check New GPU

```bash
nvidia-smi
# Note: GPU name and VRAM
```

### Update .env Based on GPU

| GPU Type | VRAM | Settings |
|----------|------|----------|
| Tesla T4 | 16GB | `EXECUTION_THREAD_COUNT=4`, `GPU_ONLY_MODE=true` |
| Tesla V100 | 16/32GB | `EXECUTION_THREAD_COUNT=6`, `GPU_ONLY_MODE=true` |
| Tesla A100 | 40/80GB | `EXECUTION_THREAD_COUNT=8`, `GPU_ONLY_MODE=true` |
| RTX 3060 | 12GB | `EXECUTION_THREAD_COUNT=2`, `GPU_ONLY_MODE=true` |
| RTX 3090 | 24GB | `EXECUTION_THREAD_COUNT=4`, `GPU_ONLY_MODE=true` |
| No GPU | - | `EXECUTION_PROVIDER=cpu`, `EXECUTION_THREAD_COUNT=2`, `GPU_ONLY_MODE=false` |

### Update Encoder Based on GPU

```bash
# Check available encoders
ffmpeg -encoders 2>/dev/null | grep -E "libx264|h264_qsv|h264_nvenc"

# NVIDIA GPU (NVENC):
# OUTPUT_VIDEO_ENCODER=h264_nvenc

# Intel CPU (QSV):
# OUTPUT_VIDEO_ENCODER=h264_qsv

# Software (no hardware acceleration):
# OUTPUT_VIDEO_ENCODER=libx264
```

---

## Dependency Check & Install

### Check All Dependencies

```bash
# Python version
python3 --version

# Required modules
python3 -c "
modules = ['telegram', 'cv2', 'numpy', 'PIL', 'insightface', 'onnxruntime', 'fastapi', 'uvicorn', 'mega', 'requests', 'psutil', 'loguru']
for m in modules:
    try:
        __import__(m)
        print(f'OK: {m}')
    except ImportError:
        print(f'MISSING: {m}')
"

# GPU
nvidia-smi

# CUDA
nvcc --version

# FFmpeg
ffmpeg -version | head -1

# rclone
rclone version | head -1
```

### Install Missing Dependencies

```bash
# Python packages
pip install python-telegram-bot==20.7 pycryptodome==3.23.0
pip install onnxruntime-gpu==1.19.2 onnx==1.21.0 insightface==0.7.3
pip install opencv-python-headless==4.13.0.92 numpy==2.4.6 pillow==11.3.0
pip install scikit-image==0.26.0 scipy==1.17.1
pip install fastapi==0.135.1 uvicorn==0.42.0 aiofiles==24.1.0
pip install mega.py==1.0.8 gdown==6.0.0 requests==2.32.5
pip install psutil==7.2.2 loguru==0.7.3 python-dotenv==1.2.2

# PyTorch with CUDA
pip install torch torchvision --index-url https://download.pytorch.org/whl/cu121

# System packages (if needed)
apt-get update && apt-get install -y ffmpeg  # or use static build
```

---

## Testing & Verification

### Test 1: Health Check

```bash
# Start bot first, then:
curl http://localhost:8765/healthz
# Expected: "ok"
```

### Test 2: GPU Detection

```bash
python3 -c "
import torch
print(f'CUDA available: {torch.cuda.is_available()}')
print(f'GPU: {torch.cuda.get_device_name(0) if torch.cuda.is_available() else \"None\"}')
print(f'VRAM: {torch.cuda.get_device_properties(0).total_mem / 1024**3:.1f} GB' if torch.cuda.is_available() else '')
"
```

### Test 3: FaceFusion Import

```bash
cd app
python3 -c "
from facefusion import face_analyser
print('FaceFusion imported successfully')
"
```

### Test 4: FFmpeg Encoder Test

```bash
# Test h264_qsv
ffmpeg -f lavfi -i testsrc=duration=1:size=320x240:rate=30 -c:v h264_qsv -y /tmp/test_qsv.mp4 2>&1 | tail -3

# Test libx264
ffmpeg -f lavfi -i testsrc=duration=1:size=320x240:rate=30 -c:v libx264 -y /tmp/test_x264.mp4 2>&1 | tail -3
```

### Test 5: Send Test Job via Telegram

1. Open Telegram, find your bot
2. Send a face photo
3. Send a video/MEGA link
4. Wait for processing
5. Check if output is received

---

## Bot Management

### Find Active Bot Process

```bash
# Find by process name
ps aux | grep "startup.py" | grep -v grep

# Find by port
lsof -i :8765

# Find by PID file
cat app/pipeline/logs/bot.pid 2>/dev/null && ps -p $(cat app/pipeline/logs/bot.pid)
```

### Kill Active Bot

```bash
# Kill by PID
kill $(cat app/pipeline/logs/bot.pid 2>/dev/null)

# Kill all startup.py processes
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

# With screen
screen -S swapmaster
export PATH="$HOME/.local/bin:$PATH"
python3 app/startup.py
# Ctrl+A, D to detach

# With tmux
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

---

## Token Changes

### Change Telegram Bot Token

1. Open `.env`
2. Update `BOT_TOKEN=your_new_token`
3. Restart bot

### Change GDrive Token (rclone)

```bash
# Re-authorize rclone
rclone config
# Choose: gdrive -> reconfigure -> follow browser flow

# Or manually update token in rclone.conf
nano .config/rclone/rclone.conf
# Update the "token" field with new JSON
```

### Change MEGA Credentials

1. Open `.env`
2. Update `MEGA_EMAIL` and `MEGA_PASSWORD`
3. Restart bot

---

## Troubleshooting

### Error: `output-video-encoder: invalid choice: 'libx264'`

This FaceFusion build doesn't support libx264. Fix:
```bash
# Check available encoders
ffmpeg -encoders 2>/dev/null | grep -E "h264|hevc|vp9"

# Update .env
sed -i 's/OUTPUT_VIDEO_ENCODER=libx264/OUTPUT_VIDEO_ENCODER=h264_qsv/' .env
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
# Set absolute path in .env
PROJECT_DIR="$(pwd)"
sed -i "s|RCLONE_CONF=.*|RCLONE_CONF=$PROJECT_DIR/.config/rclone/rclone.conf|" .env
```

### Error: `No module named 'cv2'`

```bash
pip install opencv-python-headless
```

### Error: `GDrive upload fails (token expired)`

```bash
# Re-authorize rclone
rclone config
# Follow the browser flow to get new token
```

### Bot starts but no response on Telegram

1. Check bot token is correct in `.env`
2. Check `ALLOWED_USER_ID` matches your Telegram user ID
3. Check bot is running: `ps aux | grep startup.py`
4. Check logs: `tail -f /tmp/swapmaster.log`

### FaceFusion exits with rc=2

```bash
# Check encoder
grep OUTPUT_VIDEO_ENCODER .env

# Test encoder manually
ffmpeg -f lavfi -i testsrc=duration=1:size=320x240:rate=30 -c:v $(grep OUTPUT_VIDEO_ENCODER .env | cut -d= -f2) -y /tmp/test.mp4 2>&1 | tail -5

# Try different encoder
sed -i 's/OUTPUT_VIDEO_ENCODER=.*/OUTPUT_VIDEO_ENCODER=rawvideo/' .env
```

---

## Project Structure

```
swapmaster-v1-native/
├── .env                    # Your config (BOT_TOKEN, paths, etc.)
├── .env.example            # Config template
├── .config/rclone/         # rclone config for GDrive
├── auto_setup.sh           # One-command auto setup
├── requirements.txt        # Python dependencies
├── README.md               # This file
├── SETTINGS_USED.md        # All face swap settings reference
├── setup.sh / setup.bat    # Manual setup scripts
├── run.sh / run.bat        # Bot start scripts
└── app/
    ├── startup.py           # Main entry point
    ├── bot.py               # Telegram bot logic (~14K lines)
    ├── health_check.py      # Health endpoint
    ├── config/
    │   └── credentials.py   # Config loader
    ├── ops/
    │   ├── gpu_auto_detect.py
    │   ├── process_guard.py
    │   └── ... (other ops)
    ├── facefusion/
    │   ├── facefusion.py    # FaceFusion entry
    │   ├── .assets/models/  # ONNX models (~3.2GB)
    │   └── ... (FaceFusion code)
    ├── persistent/
    │   ├── config.json      # Runtime config
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
