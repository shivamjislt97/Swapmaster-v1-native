# SwapMaster V1 - Native

Telegram bot for AI-powered face swap with GPU acceleration. Runs on Lightning AI Studio with NVIDIA L40S.

---

## Features

- **Face Swap** — Upload photo/video, swap faces using AI models
- **Selective Face Swap** — Choose specific faces to swap in group photos/videos
- **Segment Face Swap** — Swap faces in specific segments of videos
- **Face Enhancement** — GFPGAN auto-enhancement after swap
- **GPU Accelerated** — CUDA with ONNX Runtime for fast processing
- **Auto-upload** — Results auto-uploaded to Google Drive with shareable links
- **Auto-sleep** — Bot sleeps after inactivity to save GPU credits
- **Web Dashboard** — Monitor jobs via ngrok public URL

---

## Requirements

- **GPU:** NVIDIA GPU with ≥6GB VRAM (L40S, A100, 4090, 3080, etc.)
- **OS:** Linux (tested on Lightning AI Studio / Ubuntu)
- **Python:** 3.12+
- **Storage:** ~10GB for models and dependencies

---

## Quick Start (Auto Setup)

```bash
# 1. Clone or extract backup
# 2. Run auto-setup
chmod +x setup_auto.sh
./setup_auto.sh

# 3. Edit configuration
nano .env  # Add your BOT_TOKEN and ALLOWED_USER_ID
nano .config/rclone/rclone.conf  # Add your GDrive tokens

# 4. Start the bot
python3 app/process_guard.py
```

---

## Manual Setup

### 1. Install System Dependencies

```bash
# FFmpeg
apt update && apt install -y ffmpeg

# FFmpeg static build (with libx264)
mkdir -p ~/.local/bin
cd /tmp
curl -sL https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-amd64-static.tar.xz -o ffmpeg.tar.xz
tar xf ffmpeg.tar.xz
cp ffmpeg-*-static/ffmpeg ~/.local/bin/ffmpeg
cp ffmpeg-*-static/ffprobe ~/.local/bin/ffprobe
chmod +x ~/.local/bin/ffmpeg ~/.local/bin/ffprobe
rm -rf ffmpeg*
export PATH="$HOME/.local/bin:$PATH"
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc

# rclone
curl https://rclone.org/install.sh | bash
```

### 2. Install Python Dependencies

```bash
# Core
pip install python-telegram-bot==20.7 pycryptodome==3.23.0

# AI / FaceFusion
pip install onnxruntime-gpu==1.19.2 onnx==1.21.0 insightface==0.7.3
pip install opencv-python-headless==4.13.0.92 numpy==2.4.6 pillow==11.3.0
pip install scikit-image==0.26.0 scipy==1.17.1

# CUDA
pip install torch torchvision --index-url https://download.pytorch.org/whl/cu121

# Web Dashboard
pip install fastapi==0.135.1 uvicorn==0.42.0 aiofiles==24.1.0

# File handling
pip install mega.py==1.0.8 gdown==6.0.0 requests==2.32.5 beautifulsoup4==4.14.3

# Utilities
pip install psutil==7.2.2 loguru==0.7.3 python-dotenv==1.2.2 tqdm==4.67.3 colorama==0.4.6
```

### 3. Configure .env

```bash
cp .env.example .env  # or create manually
nano .env
```

Required values:
- `BOT_TOKEN` — Get from [@BotFather](https://t.me/BotFather)
- `ALLOWED_USER_ID` — Your Telegram user ID (get from [@userinfobot](https://t.me/userinfobot))
- `MEGA_EMAIL` / `MEGA_PASSWORD` — MEGA account for downloading user-sent MEGA links

### 4. Configure Google Drive

```bash
# Create rclone config
mkdir -p .config/rclone
nano .config/rclone/rclone.conf
```

Add your GDrive OAuth tokens:
```
[gdrive]
type = drive
scope = drive
token = {"access_token":"...","refresh_token":"..."}
```

**To get tokens:** Use [rclone authorize](https://rclone.org/remote_setup/) or existing refresh token.

### 5. Start the Bot

```bash
# Start with auto-restart watchdog
python3 app/process_guard.py

# OR start directly
python3 app/bot.py
```

### 6. Set Up ngrok (Optional)

```bash
# Install ngrok
curl -s https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.tgz | tar xz -C ~/.local/bin/

# Configure
ngrok config add-authtoken YOUR_TOKEN

# Start tunnel
ngrok http 8765
```

---

## Configuration Reference

See [Settings Used in This Project.md](Settings%20Used%20in%20This%20Project.md) for all current values.

---

## GPU Configuration

See [GPU Configuration Knowledge.md](GPU%20Configuration%20Knowledge.md) for GPU setup details.

---

## Project Structure

```
swapmaster-v1-native/
├── .env                          # Main configuration
├── .config/rclone/rclone.conf    # GDrive OAuth tokens
├── app/
│   ├── bot.py                    # Main Telegram bot
│   ├── process_guard.py          # Auto-restart watchdog
│   ├── startup.py                # Startup orchestrator
│   ├── facefusion/               # FaceFusion AI engine
│   ├── ops/
│   │   └── gpu_auto_detect.py    # GPU detection & config
│   └── persistent/
│       └── config.json           # Persistent state
├── requirements.txt              # Python dependencies
├── setup_auto.sh                 # Auto-setup script
├── Settings Used in This Project.md
├── GPU Configuration Knowledge.md
└── README.md                     # This file
```

---

## Troubleshooting

### Bot won't start
```bash
# Check Python packages
python3 -c "import torch; print(torch.cuda.is_available())"
python3 -c "import onnxruntime as ort; print(ort.get_available_providers())"

# Check FFmpeg
~/.local/bin/ffmpeg -encoders | grep libx264

# Check GPU
nvidia-smi
```

### GDrive upload fails
```bash
# Test rclone
rclone ls gdrive:faceswap_output

# Refresh token
rclone authorize "drive"
```

### CUDA errors
- Set `ORT_CUDA_GRAPH=0` in `gpu_auto_detect.py`
- Reduce `EXECUTION_THREAD_COUNT` to 4
- See [GPU Configuration Knowledge.md](GPU%20Configuration%20Knowledge.md)

---

## AI Setup Prompt

Copy this prompt to an AI assistant to set up the project on a new machine:

```
I need to set up SwapMaster V1 (Telegram face swap bot) on a [MACHINE TYPE] with [GPU MODEL] ([VRAM]GB VRAM).

Requirements:
1. Install Python 3.12, FFmpeg (with libx264), rclone, ngrok
2. Install all Python dependencies from requirements.txt
3. Configure .env with:
   - BOT_TOKEN: [YOUR BOT TOKEN]
   - ALLOWED_USER_ID: [YOUR TELEGRAM USER ID]
   - MEGA_EMAIL: [YOUR MEGA EMAIL]
   - MEGA_PASSWORD: [YOUR MEGA PASSWORD]
   - EXECUTION_PROVIDER=cuda
   - GPU_ONLY_MODE=true
   - OUTPUT_VIDEO_ENCODER=libx264
4. Configure .config/rclone/rclone.conf with GDrive OAuth tokens:
   - Refresh token: [YOUR REFRESH TOKEN]
5. Set GPU auto-detect in app/ops/gpu_auto_detect.py:
   - If VRAM ≥20GB: hyperswap_1a_256, 6 threads
   - If VRAM ≥12GB: hyperswap_1a_256, 4 threads
   - If VRAM <12GB: inswapper_128_fp16, 4 threads
6. Disable CUDA graphs (ORT_CUDA_GRAPH=0) for stability
7. Start with: python3 app/process_guard.py
8. Set up ngrok tunnel for dashboard: ngrok http 8765

Key paths:
- Project: /teamspace/studios/this_studio/swapmaster-v1-native/
- FFmpeg: ~/.local/bin/ffmpeg
- Config: .env and .config/rclone/rclone.conf
```

---

## License

Private project. All rights reserved.
