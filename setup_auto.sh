#!/bin/bash
# ============================================================
# SwapMaster V1 - Auto Setup Script
# Run this on a fresh Lightning AI Studio to set up everything
# ============================================================
set -e

PROJECT_DIR="/teamspace/studios/this_studio/swapmaster-v1-native"
BACKUP_GDRIVE_ID="1jZ72M7Kx91Y1VxQO8d6YbJqQK3bJZxQO"

echo "=========================================="
echo " SwapMaster V1 - Auto Setup"
echo "=========================================="

# Step 1: Check if already installed
if [ -f "$PROJECT_DIR/app/bot.py" ]; then
    echo "[OK] Project files exist at $PROJECT_DIR"
else
    echo "[!] Project files not found. Please ensure backup is extracted."
    echo "    Expected: $PROJECT_DIR/app/bot.py"
    exit 1
fi

# Step 2: Install system dependencies
echo ""
echo "[1/8] Installing system dependencies..."
apt-get update -qq && apt-get install -y -qq ffmpeg > /dev/null 2>&1 || true
echo "  [OK] apt packages"

# Step 3: Install FFmpeg static build (with libx264)
echo ""
echo "[2/8] Installing FFmpeg static build..."
mkdir -p ~/.local/bin
if [ ! -f ~/.local/bin/ffmpeg ]; then
    cd /tmp
    curl -sL https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-amd64-static.tar.xz -o ffmpeg.tar.xz
    tar xf ffmpeg.tar.xz
    cp ffmpeg-*-static/ffmpeg ~/.local/bin/ffmpeg
    cp ffmpeg-*-static/ffprobe ~/.local/bin/ffprobe
    chmod +x ~/.local/bin/ffmpeg ~/.local/bin/ffprobe
    rm -rf ffmpeg* 
    echo "  [OK] FFmpeg installed"
else
    echo "  [OK] FFmpeg already installed"
fi
cd "$PROJECT_DIR"

# Step 4: Install rclone
echo ""
echo "[3/8] Installing rclone..."
if ! command -v rclone &> /dev/null; then
    curl -s https://rclone.org/install.sh | bash > /dev/null 2>&1
    echo "  [OK] rclone installed"
else
    echo "  [OK] rclone already installed ($(rclone version | head -1))"
fi

# Step 5: Install Python dependencies
echo ""
echo "[4/8] Installing Python dependencies..."
pip install -q python-telegram-bot==20.7 pycryptodome==3.23.0 2>/dev/null || true
pip install -q onnx==1.21.0 insightface==0.7.3 opencv-python-headless==4.13.0.92 2>/dev/null || true
pip install -q numpy==2.4.6 pillow==11.3.0 scikit-image==0.26.0 scipy==1.17.1 2>/dev/null || true
pip install -q fastapi==0.135.1 uvicorn==0.42.0 aiofiles==24.1.0 2>/dev/null || true
pip install -q mega.py==1.0.8 gdown==6.0.0 requests==2.32.5 beautifulsoup4==4.14.3 2>/dev/null || true
pip install -q psutil==7.2.2 loguru==0.7.3 python-dotenv==1.2.2 tqdm==4.67.3 colorama==0.4.6 2>/dev/null || true
pip install -q torch torchvision --index-url https://download.pytorch.org/whl/cu121 2>/dev/null || true
pip install -q onnxruntime-gpu==1.19.2 2>/dev/null || true
echo "  [OK] Python packages installed"

# Step 6: Configure .env
echo ""
echo "[5/8] Configuring .env..."
if [ ! -f "$PROJECT_DIR/.env" ]; then
    cat > "$PROJECT_DIR/.env" << 'ENVEOF'
# === SwapMaster V1 - Native Installation ===
# === REQUIRED ===
BOT_TOKEN=YOUR_BOT_TOKEN_FROM_BOTFATHER
ALLOWED_USER_ID=YOUR_TELEGRAM_USER_ID

# === MEGA ===
MEGA_EMAIL=your_email@gmail.com
MEGA_PASSWORD=your_password

# === GDRIVE ===
GDRIVE_ENABLED=true
GDRIVE_REMOTE_NAME=gdrive
GDRIVE_FOLDER=gdrive:faceswap_output
RCLONE_BIN=rclone
RCLONE_CONF=/teamspace/studios/this_studio/swapmaster-v1-native/.config/rclone/rclone.conf

# === GPU / FACEFUSION ===
EXECUTION_PROVIDER=cuda
GPU_ONLY_MODE=true
FACE_SWAPPER_MODEL=inswapper_128
FACE_ENHANCER_MODEL=gfpgan_1.4
FACE_ENHANCER_BLEND=80
ENABLE_FACE_ENHANCER=true
OUTPUT_VIDEO_ENCODER=libx264
EXECUTION_THREAD_COUNT=6
THREAD_COUNT=6

# === BOT BEHAVIOUR ===
AUTO_SLEEP_ENABLED=true
AUTO_SLEEP_MINUTES=30
POST_JOB_AUTO_SLEEP_SECONDS=120
DASHBOARD_ENABLED=true
DASHBOARD_PORT=8765
BYPASS_CONTENT_ANALYSER=false

# === WATCHDOG ===
PIPELINE_WATCHDOG_PROCESSING_SEC=600
PIPELINE_WATCHDOG_MERGING_SEC=300
PIPELINE_WATCHDOG_UPLOADING_SEC=300
ENVEOF
    echo "  [OK] .env created - EDIT IT with your tokens!"
    echo "  !! IMPORTANT: Edit $PROJECT_DIR/.env with your BOT_TOKEN and USER_ID !!"
else
    echo "  [OK] .env already exists"
fi

# Step 7: Configure rclone for GDrive
echo ""
echo "[6/8] Setting up GDrive (rclone)..."
mkdir -p "$PROJECT_DIR/.config/rclone"
if [ ! -f "$PROJECT_DIR/.config/rclone/rclone.conf" ]; then
    cat > "$PROJECT_DIR/.config/rclone/rclone.conf" << 'RCLONEEOF'
[gdrive]
type = drive
scope = drive
token = {"access_token":"YOUR_ACCESS_TOKEN","token_type":"Bearer","refresh_token":"YOUR_REFRESH_TOKEN","expires_in":3599}
RCLONEEOF
    echo "  [OK] rclone.conf created - EDIT IT with your GDrive tokens!"
    echo "  !! IMPORTANT: Edit $PROJECT_DIR/.config/rclone/rclone.conf !!"
else
    echo "  [OK] rclone.conf already exists"
fi

# Step 8: Set PATH
echo ""
echo "[7/8] Setting PATH..."
export PATH="$HOME/.local/bin:$PATH"
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
echo "  [OK] PATH updated"

# Step 9: Verify
echo ""
echo "[8/8] Verifying installation..."
echo "  FFmpeg: $(~/.local/bin/ffmpeg -version 2>&1 | head -1)"
echo "  rclone: $(rclone version 2>&1 | head -1)"
echo "  Python: $(python3 --version)"
echo "  GPU: $(nvidia-smi --query-gpu=name,memory.total --format=csv,noheader 2>/dev/null || echo 'No GPU detected')"
echo "  CUDA: $(python3 -c 'import onnxruntime as ort; print("Available" if "CUDAExecutionProvider" in ort.get_available_providers() else "Not available")' 2>/dev/null || echo 'Check manually')"

echo ""
echo "=========================================="
echo " Setup Complete!"
echo "=========================================="
echo ""
echo "NEXT STEPS:"
echo "  1. Edit .env with your BOT_TOKEN and ALLOWED_USER_ID"
echo "  2. Edit .config/rclone/rclone.conf with your GDrive tokens"
echo "  3. Set up ngrok: ngrok config add-authtoken YOUR_TOKEN"
echo "  4. Start the bot:"
echo "     cd $PROJECT_DIR"
echo "     source ~/.bashrc"
echo "     python3 app/process_guard.py"
echo ""
echo "  OR use the start script:"
echo "     cd $PROJECT_DIR && bash start.sh"
echo ""
