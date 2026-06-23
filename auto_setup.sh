#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# SwapMaster V1 - Native Auto Setup Script
# One-command full setup: dependencies, models, paths, config
# ============================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

log()  { echo -e "${GREEN}[OK]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
err()  { echo -e "${RED}[ERROR]${NC} $*"; }
info() { echo -e "${CYAN}[INFO]${NC} $*"; }

# ---- Step 1: System Detection ----
echo ""
echo "=========================================="
echo " SwapMaster V1 - Auto Setup"
echo "=========================================="
echo ""

info "Detecting system..."
OS="$(uname -s)"
ARCH="$(uname -m)"
info "OS: $OS | Arch: $ARCH"

# Python
PYTHON=""
for p in python3.12 python3.11 python3.10 python3; do
    if command -v "$p" &>/dev/null; then
        PYTHON="$p"
        break
    fi
done
if [ -z "$PYTHON" ]; then
    err "Python 3.10+ not found. Install Python first."
    exit 1
fi
PY_VER="$($PYTHON --version 2>&1 | awk '{print $2}')"
log "Python: $PYTHON ($PY_VER)"

# GPU
GPU_NAME="None"
GPU_VRAM="0"
if command -v nvidia-smi &>/dev/null; then
    GPU_NAME="$(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null | head -1)"
    GPU_VRAM="$(nvidia-smi --query-gpu=memory.total --format=csv,noheader 2>/dev/null | head -1)"
    log "GPU: $GPU_NAME ($GPU_VRAM)"
else
    warn "No NVIDIA GPU detected. Will use CPU mode."
fi

# CUDA
CUDA_VER="None"
if command -v nvcc &>/dev/null; then
    CUDA_VER="$(nvcc --version 2>/dev/null | grep 'release' | awk '{print $6}' | cut -c2-)"
    log "CUDA: $CUDA_VER"
else
    warn "CUDA not found. GPU acceleration may not work."
fi

# ---- Step 2: Install System Dependencies ----
echo ""
info "Installing system dependencies..."

# FFmpeg
FFMPEG_PATH="$HOME/.local/bin/ffmpeg"
if [ -x "$FFMPEG_PATH" ]; then
    log "FFmpeg already installed: $FFMPEG_PATH"
elif command -v ffmpeg &>/dev/null; then
    FFMPEG_PATH="$(which ffmpeg)"
    log "FFmpeg found: $FFMPEG_PATH"
else
    info "Installing FFmpeg (static build)..."
    mkdir -p "$HOME/.local/bin"
    FFMPEG_URL="https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-amd64-static.tar.xz"
    cd /tmp
    curl -L -o ffmpeg.tar.xz "$FFMPEG_URL" 2>/dev/null
    tar xf ffmpeg.tar.xz
    cp ffmpeg-*-static/ffmpeg "$HOME/.local/bin/ffmpeg"
    cp ffmpeg-*-static/ffprobe "$HOME/.local/bin/ffprobe" 2>/dev/null || true
    chmod +x "$HOME/.local/bin/ffmpeg"
    rm -rf ffmpeg* 
    cd "$SCRIPT_DIR"
    FFMPEG_PATH="$HOME/.local/bin/ffmpeg"
    log "FFmpeg installed: $FFMPEG_PATH"
fi

# Verify FFmpeg has libx264
if "$FFMPEG_PATH" -encoders 2>/dev/null | grep -q "libx264"; then
    log "FFmpeg has libx264 support"
else
    warn "FFmpeg missing libx264. Using h264_qsv encoder instead."
fi

# rclone
RCLONE_PATH=""
if command -v rclone &>/dev/null; then
    RCLONE_PATH="$(which rclone)"
    log "rclone found: $RCLONE_PATH"
else
    info "Installing rclone..."
    curl -s https://rclone.org/install.sh | bash 2>/dev/null || {
        # Fallback: download binary directly
        RCLONE_VER="v1.74.3"
        mkdir -p "$HOME/.local/bin"
        cd /tmp
        curl -L -o rclone.zip "https://downloads.rclone.org/current/rclone-${RCLONE_VER}-linux-amd64.zip" 2>/dev/null
        unzip -o rclone.zip 2>/dev/null
        cp rclone-*-linux-amd64/rclone "$HOME/.local/bin/rclone"
        chmod +x "$HOME/.local/bin/rclone"
        rm -rf rclone*
        cd "$SCRIPT_DIR"
    }
    RCLONE_PATH="$(which rclone 2>/dev/null || echo "$HOME/.local/bin/rclone")"
    log "rclone installed: $RCLONE_PATH"
fi

# Ensure ~/.local/bin is in PATH
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    export PATH="$HOME/.local/bin:$PATH"
    warn "Added ~/.local/bin to PATH for this session"
    warn "Add to ~/.bashrc: export PATH=\"\$HOME/.local/bin:\$PATH\""
fi

# ---- Step 3: Install Python Dependencies ----
echo ""
info "Installing Python dependencies..."

if [ -f "requirements.txt" ]; then
    $PYTHON -m pip install --quiet --upgrade pip 2>/dev/null
    $PYTHON -m pip install --quiet -r requirements.txt 2>&1 | tail -5
    log "Python dependencies installed"
else
    err "requirements.txt not found!"
    exit 1
fi

# Install PyTorch with CUDA (if GPU available)
if [ "$GPU_NAME" != "None" ]; then
    info "Installing PyTorch with CUDA support..."
    $PYTHON -m pip install --quiet torch torchvision --index-url https://download.pytorch.org/whl/cu121 2>&1 | tail -3
    log "PyTorch with CUDA installed"
fi

# ---- Step 4: Verify Models ----
echo ""
info "Checking face swap models..."

MODELS_DIR="app/facefusion/.assets/models"
if [ ! -d "$MODELS_DIR" ]; then
    mkdir -p "$MODELS_DIR"
fi

REQUIRED_MODELS=(
    "inswapper_128.onnx"
    "gfpgan_1.4.onnx"
    "yolo_face_1.0.onnx"
    "arcface_w600k_r50.onnx"
    "2dfan4.onnx"
    "bisenet_resnet_34.onnx"
)

MISSING=0
for model in "${REQUIRED_MODELS[@]}"; do
    if [ -f "$MODELS_DIR/$model" ]; then
        log "Model found: $model"
    else
        warn "Model missing: $model"
        MISSING=$((MISSING + 1))
    fi
done

if [ "$MISSING" -gt 0 ]; then
    warn "$MISSING models missing. They should be in the backup zip."
    warn "If missing, download from: https://github.com/facefusion/facefusion-assets"
fi

# ---- Step 5: Setup .env ----
echo ""
info "Configuring .env..."

if [ ! -f ".env" ]; then
    if [ -f ".env.example" ]; then
        cp .env.example .env
        log "Created .env from .env.example"
    else
        err ".env.example not found!"
        exit 1
    fi
fi

# Auto-set paths in .env
RCLONE_CONF_PATH="$(pwd)/.config/rclone/rclone.conf"

# Update RCLONE_CONF in .env
if grep -q "RCLONE_CONF=" .env; then
    sed -i "s|RCLONE_CONF=.*|RCLONE_CONF=$RCLONE_CONF_PATH|" .env
    log "Updated RCLONE_CONF in .env"
fi

# Update OUTPUT_VIDEO_ENCODER based on available encoders
if [ -f "$FFMPEG_PATH" ]; then
    if "$FFMPEG_PATH" -encoders 2>/dev/null | grep -q "libx264"; then
        sed -i 's/OUTPUT_VIDEO_ENCODER=.*/OUTPUT_VIDEO_ENCODER=libx264/' .env
        log "Encoder set to: libx264"
    elif "$FFMPEG_PATH" -encoders 2>/dev/null | grep -q "h264_qsv"; then
        sed -i 's/OUTPUT_VIDEO_ENCODER=.*/OUTPUT_VIDEO_ENCODER=h264_qsv/' .env
        log "Encoder set to: h264_qsv"
    fi
fi

# ---- Step 6: Setup rclone config ----
echo ""
info "Checking rclone config..."

RCLONE_CONF_DIR=".config/rclone"
mkdir -p "$RCLONE_CONF_DIR"

if [ -f "$RCLONE_CONF_PATH" ]; then
    log "rclone.conf found: $RCLONE_CONF_PATH"
else
    warn "rclone.conf not found. GDrive upload will be disabled."
    warn "To setup GDrive: run 'rclone config' and create a remote named 'gdrive'"
    warn "Or copy rclone.conf from the backup zip"
fi

# ---- Step 7: Validate Installation ----
echo ""
info "Validating installation..."

ERRORS=0

# Check Python imports
for module in telegram cv2 numpy PIL insightface onnxruntime fastapi uvicorn; do
    if $PYTHON -c "import $module" 2>/dev/null; then
        log "Python module: $module"
    else
        warn "Python module missing: $module"
        ERRORS=$((ERRORS + 1))
    fi
done

# Check binary
if [ -f "app/startup.py" ]; then
    log "startup.py found"
else
    err "startup.py not found!"
    ERRORS=$((ERRORS + 1))
fi

# Check bot.py
if [ -f "app/bot.py" ]; then
    log "bot.py found"
else
    err "bot.py not found!"
    ERRORS=$((ERRORS + 1))
fi

# ---- Step 8: Summary ----
echo ""
echo "=========================================="
echo " Setup Complete!"
echo "=========================================="
echo ""
echo "System:"
echo "  OS:       $OS ($ARCH)"
echo "  Python:   $PY_VER"
echo "  GPU:      $GPU_NAME"
echo "  CUDA:     $CUDA_VER"
echo "  FFmpeg:   $FFMPEG_PATH"
echo "  rclone:   $RCLONE_PATH"
echo ""
echo "Next steps:"
echo "  1. Edit .env with your BOT_TOKEN and ALLOWED_USER_ID"
echo "  2. Setup rclone for GDrive (if needed): rclone config"
echo "  3. Start the bot:"
echo "     PATH=\"\$HOME/.local/bin:\$PATH\" $PYTHON app/startup.py"
echo ""
echo "Quick start command:"
echo "  export PATH=\"\$HOME/.local/bin:\$PATH\" && $PYTHON app/startup.py"
echo ""

if [ "$ERRORS" -gt 0 ]; then
    warn "$ERRORS issues found. Check warnings above."
fi

echo "=========================================="
