# SwapMaster V1 - Master AI Agent Setup Prompt

> Copy-paste this entire prompt to any AI agent (ChatGPT, Claude, Gemini, Copilot, etc.)
> The agent will perform a complete end-to-end setup including Telegram bot, GPU config, and output testing.

---

## THE PROMPT

```
You are setting up SwapMaster V1 (FaceFusion Telegram Bot) on a fresh Ubuntu/Linux system with NVIDIA GPU.
The full project backup is on Google Drive as a tar archive.

CRITICAL RULES:
- ALWAYS run commands, never just describe them
- ALWAYS verify each step before moving to the next
- If a step fails, FIX IT before continuing
- NEVER skip testing - the bot MUST produce output before you declare success
- Keep me informed of progress after each major step

═══════════════════════════════════════════════════════
STEP 1: DOWNLOAD AND EXTRACT BACKUP
═══════════════════════════════════════════════════════

Execute these commands in order:

```bash
# Navigate to workspace
cd /teamspace/studios/this_studio

# Download the 6.4GB backup from Google Drive (resumable, ~60MB/s)
curl -L -o swapmaster.tar "https://drive.google.com/uc?id=1r8kRQX9FwuhRip_m3NwDXYfwh1x4bmGA"

# Verify download (must be ~6.4GB = 6862120960 bytes)
ls -lh swapmaster.tar
stat -c%s swapmaster.tar  # Expected: 6862120960

# Extract (no compression, just archive - fast)
tar xf swapmaster.tar

# Enter project directory
cd swapmaster-v1-native

# Verify critical files exist
ls -la app/bot.py app/startup.py .env requirements.txt
wc -l app/bot.py  # Expected: ~13929 lines
```

IF download fails or file is wrong size: The Google Drive link may have expired. Ask user for a new link.

═══════════════════════════════════════════════════════
STEP 2: SYSTEM DETECTION
═══════════════════════════════════════════════════════

Run detection commands and report findings:

```bash
# System info
uname -a
cat /etc/os-release | head -3

# Python
python3 --version

# GPU
nvidia-smi 2>/dev/null || echo "NO GPU DETECTED"
nvidia-smi --query-gpu=name,memory.total --format=csv,noheader 2>/dev/null

# CUDA
nvcc --version 2>/dev/null || echo "nvcc not found"

# CPU cores
nproc

# Disk space
df -h . | tail -1
```

Report to user:
- GPU name and VRAM
- CUDA version
- Python version
- CPU cores
- Available disk space

═══════════════════════════════════════════════════════
STEP 3: INSTALL SYSTEM DEPENDENCIES
═══════════════════════════════════════════════════════

```bash
# Add ~/.local/bin to PATH permanently
export PATH="$HOME/.local/bin:$PATH"
grep -q '.local/bin' ~/.bashrc 2>/dev/null || echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc

# Install FFmpeg static build (with libx264/h264_qsv support)
mkdir -p ~/.local/bin
if ! command -v ~/.local/bin/ffmpeg &>/dev/null; then
    cd /tmp
    curl -L -o ffmpeg.tar.xz "https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-amd64-static.tar.xz"
    tar xf ffmpeg.tar.xz
    cp ffmpeg-*-static/ffmpeg ~/.local/bin/ffmpeg
    cp ffmpeg-*-static/ffprobe ~/.local/bin/ffprobe 2>/dev/null || true
    chmod +x ~/.local/bin/ffmpeg
    rm -rf ffmpeg*
fi

# Verify FFmpeg
~/.local/bin/ffmpeg -version | head -2

# Check available encoders
~/.local/bin/ffmpeg -encoders 2>/dev/null | grep -E "libx264|h264_qsv|h264_nvenc|libvpx-vp9"

# Install rclone (for Google Drive upload)
if ! command -v rclone &>/dev/null && [ ! -f ~/.local/bin/rclone ]; then
    curl -s https://rclone.org/install.sh | bash 2>/dev/null || {
        RCLONE_VER="v1.74.3"
        cd /tmp
        curl -L -o rclone.zip "https://downloads.rclone.org/current/rclone-${RCLONE_VER}-linux-amd64.zip"
        unzip -o rclone.zip
        cp rclone-*-linux-amd64/rclone ~/.local/bin/rclone
        chmod +x ~/.local/bin/rclone
        rm -rf rclone*
    }
fi
rclone version | head -1
```

═══════════════════════════════════════════════════════
STEP 4: INSTALL PYTHON DEPENDENCIES
═══════════════════════════════════════════════════════

```bash
cd /teamspace/studios/this_studio/swapmaster-v1-native

# Upgrade pip
python3 -m pip install --upgrade pip

# Install all requirements
python3 -m pip install -r requirements.txt

# Install PyTorch with CUDA (match your CUDA version)
# For CUDA 12.x:
python3 -m pip install torch torchvision --index-url https://download.pytorch.org/whl/cu121
# For CUDA 11.x:
# python3 -m pip install torch torchvision --index-url https://download.pytorch.org/whl/cu118

# Verify critical imports
python3 -c "
import sys; print(f'Python: {sys.version}')
import torch; print(f'PyTorch: {torch.__version__}, CUDA: {torch.cuda.is_available()}, GPU: {torch.cuda.get_device_name(0) if torch.cuda.is_available() else \"None\"}')
import onnxruntime as ort; print(f'ONNX Runtime: {ort.__version__}, Providers: {ort.get_available_providers()}')
import cv2; print(f'OpenCV: {cv2.__version__}')
import insightface; print(f'InsightFace: {insightface.__version__}')
import telegram; print(f'Telegram Bot: {telegram.__version__}')
import numpy; print(f'NumPy: {numpy.__version__}')
print('ALL IMPORTS OK')
"
```

IF any import fails: Install the missing package specifically and retry.

═══════════════════════════════════════════════════════
STEP 5: VERIFY MODELS (25 ONNX files, ~3.2GB)
═══════════════════════════════════════════════════════

```bash
cd /teamspace/studios/this_studio/swapmaster-v1-native

# List all ONNX models
echo "=== All ONNX models ==="
find app/facefusion/.assets/models -name "*.onnx" -exec ls -lh {} \; 2>/dev/null | awk '{print $5, $NF}'

# Count models (should be 25)
echo ""
echo "Total ONNX models: $(find app/facefusion/.assets/models -name '*.onnx' 2>/dev/null | wc -l)"

# Critical models check
echo ""
echo "=== Critical models ==="
for model in inswapper_128.onnx gfpgan_1.4.onnx yolo_face_1.0.onnx arcface_w600k_r50.onnx 2dfan4.onnx bisenet_resnet_34.onnx; do
    if [ -f "app/facefusion/.assets/models/$model" ]; then
        echo "  OK: $model ($(ls -lh "app/facefusion/.assets/models/$model" | awk '{print $5}'))"
    else
        echo "  MISSING: $model"
    fi
done

# Total models size
echo ""
echo "Total models size: $(du -sh app/facefusion/.assets/models/ 2>/dev/null | awk '{print $1}')"
```

EXPECTED: 25 ONNX models, ~3.2GB total. If any critical model is missing, the face swap will fail.

═══════════════════════════════════════════════════════
STEP 6: CONFIGURE .ENV
═══════════════════════════════════════════════════════

The .env is already configured from the backup. Verify and adjust:

```bash
cd /teamspace/studios/this_studio/swapmaster-v1-native

# Show current .env (all variables)
cat .env

# CRITICAL: Set correct RCLONE_CONF path (absolute path to YOUR installation)
ACTUAL_PATH="$(pwd)/.config/rclone/rclone.conf"
sed -i "s|RCLONE_CONF=.*|RCLONE_CONF=$ACTUAL_PATH|" .env
echo "RCLONE_CONF set to: $ACTUAL_PATH"

# CRITICAL: Set correct encoder based on your FFmpeg
# Check available encoders:
~/.local/bin/ffmpeg -encoders 2>/dev/null | grep -E "libx264|h264_qsv|h264_nvenc"

# Set encoder (choose ONE based on what's available):
# Option A - If libx264 available:
#   sed -i 's/OUTPUT_VIDEO_ENCODER=.*/OUTPUT_VIDEO_ENCODER=libx264/' .env
# Option B - If h264_qsv available (Intel GPU or fallback):
#   sed -i 's/OUTPUT_VIDEO_ENCODER=.*/OUTPUT_VIDEO_ENCODER=h264_qsv/' .env
# Option C - If h264_nvenc available (NVIDIA GPU):
#   sed -i 's/OUTPUT_VIDEO_ENCODER=.*/OUTPUT_VIDEO_ENCODER=h264_nvenc/' .env

# Auto-detect best encoder:
if ~/.local/bin/ffmpeg -encoders 2>/dev/null | grep -q "libx264"; then
    sed -i 's/OUTPUT_VIDEO_ENCODER=.*/OUTPUT_VIDEO_ENCODER=libx264/' .env
    echo "Encoder: libx264"
elif ~/.local/bin/ffmpeg -encoders 2>/dev/null | grep -q "h264_qsv"; then
    sed -i 's/OUTPUT_VIDEO_ENCODER=.*/OUTPUT_VIDEO_ENCODER=h264_qsv/' .env
    echo "Encoder: h264_qsv"
elif ~/.local/bin/ffmpeg -encoders 2>/dev/null | grep -q "h264_nvenc"; then
    sed -i 's/OUTPUT_VIDEO_ENCODER=.*/OUTPUT_VIDEO_ENCODER=h264_nvenc/' .env
    echo "Encoder: h264_nvenc"
else
    echo "WARNING: No hardware encoder found, using rawvideo"
    sed -i 's/OUTPUT_VIDEO_ENCODER=.*/OUTPUT_VIDEO_ENCODER=rawvideo/' .env
fi

# Set thread count to match CPU cores
CPU_CORES=$(nproc)
sed -i "s/EXECUTION_THREAD_COUNT=.*/EXECUTION_THREAD_COUNT=$CPU_CORES/" .env
sed -i "s/THREAD_COUNT=.*/THREAD_COUNT=$CPU_CORES/" .env
echo "Threads: $CPU_CORES"

# Verify final .env
echo ""
echo "=== Final .env ==="
grep -v '^#' .env | grep -v '^$'
```

═══════════════════════════════════════════════════════
STEP 7: CONFIGURE RCLONE FOR GDRIVE UPLOAD
═══════════════════════════════════════════════════════

The rclone config is included in the backup. Verify it works:

```bash
cd /teamspace/studios/this_studio/swapmaster-v1-native

# Check rclone config exists
cat .config/rclone/rclone.conf

# Test GDrive connection
rclone --config .config/rclone/rclone.conf lsd gdrive: 2>&1 | head -5

# If rclone fails (token expired), you need to refresh:
# Option 1: Use rclone's built-in auth
#   rclone config  -> update the gdrive remote -> re-authenticate
# Option 2: Get new token from user and update rclone.conf

# Test upload
echo "rclone-test-$(date +%s)" > /tmp/rclone_test.txt
rclone --config .config/rclone/rclone.conf copy /tmp/rclone_test.txt gdrive:
rclone --config .config/rclone/rclone.conf lsf gdrive: | grep rclone_test
echo "GDrive upload test: $?"
rm /tmp/rclone_test.txt
```

IF GDrive upload fails: Ask user for a fresh rclone config or OAuth token.

═══════════════════════════════════════════════════════
STEP 8: KILL OLD PROCESSES AND CREATE DIRECTORIES
═══════════════════════════════════════════════════════

```bash
cd /teamspace/studios/this_studio/swapmaster-v1-native

# Kill any existing bot processes
pkill -f "python3.*startup.py" 2>/dev/null || true
pkill -f "python3.*bot.py" 2>/dev/null || true
sleep 2

# Remove stale PID files
rm -f app/bot.pid app/health_monitor.pid app/process_guard.pid 2>/dev/null

# Create all required runtime directories
mkdir -p app/pipeline/logs
mkdir -p app/pipeline/workspace/temp
mkdir -p app/pipeline/workspace/output
mkdir -p app/pipeline/downloads/video
mkdir -p app/pipeline/downloads/face
mkdir -p app/pipeline/dashboard_sessions
mkdir -p app/persistent
mkdir -p app/pipeline/queue
mkdir -p app/pipeline/tasks
mkdir -p output

echo "Directories created"
```

═══════════════════════════════════════════════════════
STEP 9: START THE BOT
═══════════════════════════════════════════════════════

```bash
cd /teamspace/studios/this_studio/swapmaster-v1-native

# Start the bot in background
export PATH="$HOME/.local/bin:$PATH"
nohup python3 app/startup.py > /tmp/swapmaster_startup.log 2>&1 &
STARTUP_PID=$!
echo "Startup PID: $STARTUP_PID"

# Wait for startup (up to 60 seconds)
echo "Waiting for bot to start..."
for i in $(seq 1 60); do
    sleep 2
    # Check if health endpoint is up
    if curl -s http://localhost:8765/healthz 2>/dev/null | grep -q "ok"; then
        echo "Bot is HEALTHY after ${i}x2 seconds!"
        break
    fi
    # Check if process died
    if ! kill -0 $STARTUP_PID 2>/dev/null; then
        echo "Startup process DIED! Checking logs:"
        tail -50 /tmp/swapmaster_startup.log
        break
    fi
    echo "  Waiting... ($i/30)"
done

# Final health check
echo ""
echo "=== Health Check ==="
curl -s http://localhost:8765/healthz
echo ""

# Show bot process
echo ""
echo "=== Bot Processes ==="
ps aux | grep -E "startup.py|bot.py" | grep -v grep

# Show recent logs
echo ""
echo "=== Recent Logs ==="
tail -20 /tmp/swapmaster_startup.log
```

IF bot fails to start:
1. Check the log: `tail -100 /tmp/swapmaster_startup.log`
2. Common issues:
   - "BOT_TOKEN missing" -> Check .env has BOT_TOKEN
   - "No module named X" -> Run: `pip install X`
   - "CUDA out of memory" -> Set EXECUTION_PROVIDER=cpu in .env
   - "encoder not found" -> Change OUTPUT_VIDEO_ENCODER in .env
   - "rclone not found" -> Check PATH includes ~/.local/bin

═══════════════════════════════════════════════════════
STEP 10: RUN FULL VERIFICATION
═══════════════════════════════════════════════════════

```bash
cd /teamspace/studios/this_studio/swapmaster-v1-native

# Run the built-in verification script
python3 app/verify.py \
    --project-root "$(pwd)" \
    --json-out /tmp/verify_report.json \
    --md-out /tmp/verify_report.md

# Show results
cat /tmp/verify_report.md

# Parse JSON for quick status
python3 -c "
import json
with open('/tmp/verify_report.json') as f:
    r = json.load(f)
print(f\"Overall Ready: {r['overall_ready']}\")
for name, data in r['results'].items():
    status = 'PASS' if data['status'] == 'PASS' else 'FAIL'
    print(f'  {status}: {name} - {data[\"detail\"][:80]}')
"
```

EXPECTED: All checks should show PASS. If any FAIL, fix that specific issue.

═══════════════════════════════════════════════════════
STEP 11: END-TO-END OUTPUT TEST (CRITICAL)
═══════════════════════════════════════════════════════

This is the MOST IMPORTANT step. The bot MUST produce output files.

TEST MEGA LINKS (pre-loaded in bot for testing):
- FACE: https://mega.nz/file/0dpElBaa#6SfgxfDhmrO3N4TeyUcDKpebN4YDNbWQjvnxVplDLJw
- VIDEO: https://mega.nz/file/y9RElKiB#kHQimH4zXbuq0aCCgiBvU8vbgvnwD1CG8AYU1-Mghgw

### Test Method A: Via Telegram (Primary)

1. Open Telegram and find your bot (search for the bot name)
2. Send `/start` to the bot
3. Send a FACE IMAGE (a clear face photo) to the bot
4. Wait for bot to acknowledge face received
5. Send a VIDEO (or paste the MEGA video link above)
6. Wait for processing (may take 1-5 minutes depending on video length)
7. Bot should reply with the faceswapped video

### Test Method B: Direct Pipeline Test (if Telegram test is slow)

```bash
cd /teamspace/studios/this_studio/swapmaster-v1-native

# Download test face and video from MEGA
python3 -c "
from mega import Mega
mega = Mega()
m = mega.login()  # anonymous login
# Download test face
print('Downloading test face...')
m.download_url('https://mega.nz/file/0dpElBaa#6SfgxfDhmrO3N4TeyUcDKpebN4YDNbWQjvnxVplDLJw', '/tmp/test_face.jpg')
print('Downloading test video...')
m.download_url('https://mega.nz/file/y9RElKiB#kHQimH4zXbuq0aCCgiBvU8vbgvnwD1CG8AYU1-Mghgw', '/tmp/test_video.mp4')
print('Downloads complete')
" 2>&1

# Verify downloads
ls -lh /tmp/test_face.jpg /tmp/test_video.mp4 2>/dev/null

# Check FFmpeg can encode with configured encoder
ENCODER=$(grep OUTPUT_VIDEO_ENCODER .env | cut -d= -f2)
echo "Testing encoder: $ENCODER"
~/.local/bin/ffmpeg -y -f lavfi -i testsrc=size=320x240:rate=24 -t 2 -c:v $ENCODER -pix_fmt yuv420p /tmp/test_encode.mp4 2>&1 | tail -5
ls -lh /tmp/test_encode.mp4 2>/dev/null && echo "Encoder test: PASS" || echo "Encoder test: FAIL"

# Check GPU memory
nvidia-smi --query-gpu=memory.used,memory.total --format=csv,noheader 2>/dev/null
```

### Test Method C: Verify Output Directory

```bash
# After sending a test job via Telegram, check output
ls -lh /teamspace/studios/this_studio/swapmaster-v1-native/output/ 2>/dev/null
ls -lh /teamspace/studios/this_studio/swapmaster-v1-native/app/pipeline/workspace/output/ 2>/dev/null

# Check bot logs for processing
tail -50 /tmp/swapmaster_startup.log | grep -E "processing|output|upload|success|error|fail"

# Check GDrive for uploaded output
rclone --config .config/rclone/rclone.conf lsf gdrive: --max-depth 1 2>/dev/null | head -10
```

═══════════════════════════════════════════════════════
STEP 12: VERIFY GDRIVE UPLOAD WORKS
═══════════════════════════════════════════════════════

```bash
cd /teamspace/studios/this_studio/swapmaster-v1-native

# After a successful face swap, check if output was uploaded to GDrive
echo "=== GDrive output files ==="
rclone --config .config/rclone/rclone.conf lsf gdrive: --max-depth 2 2>/dev/null | head -20

# Check bot logs for upload confirmation
grep -i "upload\|gdrive\|drive" /tmp/swapmaster_startup.log | tail -10
```

═══════════════════════════════════════════════════════
STEP 13: FINAL REPORT
═══════════════════════════════════════════════════════

After all steps complete, generate a final status report:

```bash
cd /teamspace/studios/this_studio/swapmaster-v1-native

echo "=========================================="
echo " SWAPMASTER V1 - SETUP COMPLETE"
echo "=========================================="
echo ""

# System
echo "SYSTEM:"
echo "  GPU: $(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null || echo 'None')"
echo "  VRAM: $(nvidia-smi --query-gpu=memory.total --format=csv,noheader 2>/dev/null || echo 'N/A')"
echo "  CUDA: $(nvcc --version 2>/dev/null | grep release | awk '{print $6}' || echo 'N/A')"
echo "  Python: $(python3 --version 2>&1)"
echo "  FFmpeg: $(~/.local/bin/ffmpeg -version 2>/dev/null | head -1 || echo 'Not found')"
echo ""

# Bot status
echo "BOT STATUS:"
HEALTH=$(curl -s http://localhost:8765/healthz 2>/dev/null)
echo "  Health: ${HEALTH:-NOT RESPONDING}"
PROCS=$(ps aux | grep -c "[b]ot.py\|[s]tartup.py" 2>/dev/null)
echo "  Processes running: $PROCS"
echo ""

# Config
echo "CONFIG:"
echo "  Encoder: $(grep OUTPUT_VIDEO_ENCODER .env | cut -d= -f2)"
echo "  Threads: $(grep EXECUTION_THREAD_COUNT .env | cut -d= -f2)"
echo "  GDrive: $(grep GDRIVE_ENABLED .env | cut -d= -f2)"
echo "  Dashboard: http://localhost:$(grep DASHBOARD_PORT .env | cut -d= -f2)"
echo ""

# Output
echo "OUTPUT TEST:"
echo "  Output dir: $(ls output/ 2>/dev/null | wc -l) files"
echo "  GDrive files: $(rclone --config .config/rclone/rclone.conf lsf gdrive: --max-depth 1 2>/dev/null | wc -l) files"
echo ""

echo "=========================================="
echo " Bot is ready for face swap operations!"
echo " Send /start to your Telegram bot to test."
echo "=========================================="
```

Report the final status to the user with:
1. All setup steps completed (YES/NO for each)
2. Bot running and healthy (YES/NO)
3. Output test passed (YES/NO) - include file paths of generated outputs
4. GDrive upload working (YES/NO)
5. Any issues found and how they were fixed
6. The Telegram bot link to test manually

---

## TROUBLESHOOTING REFERENCE

### Common Issues and Fixes

| Issue | Fix |
|-------|-----|
| `No module named 'telegram'` | `pip install python-telegram-bot==20.7` |
| `No module named 'onnxruntime'` | `pip install onnxruntime-gpu==1.19.2` |
| `No module named 'insightface'` | `pip install insightface==0.7.3` |
| `No module named 'cv2'` | `pip install opencv-python-headless==4.13.0.92` |
| `CUDA out of memory` | Set `EXECUTION_PROVIDER=cpu` in .env, or reduce `EXECUTION_THREAD_COUNT` |
| `encoder not found: h264_qsv` | Change `OUTPUT_VIDEO_ENCODER=libx264` in .env |
| `encoder not found: libx264` | Change `OUTPUT_VIDEO_ENCODER=h264_qsv` in .env |
| `rclone: command not found` | `export PATH="$HOME/.local/bin:$PATH"` |
| `rclone: token expired` | Run `rclone config` and re-authenticate the gdrive remote |
| Bot starts but no response | Check `ALLOWED_USER_ID` matches your Telegram user ID |
| Health endpoint not responding | Check port 8765: `curl http://localhost:8765/healthz` |
| Face swap produces no output | Check FFmpeg encoder matches .env setting |
| MEGA download fails | Check `MEGA_EMAIL` and `MEGA_PASSWORD` in .env (can be dummy for anonymous) |
| `BOT_TOKEN invalid` | Get new token from @BotFather on Telegram |

### Useful Commands

```bash
# Check bot logs
tail -100 /tmp/swapmaster_startup.log

# Find bot process
ps aux | grep -E "startup.py|bot.py"

# Kill bot
pkill -f "startup.py"; pkill -f "bot.py"

# Restart bot
cd /teamspace/studios/this_studio/swapmaster-v1-native
export PATH="$HOME/.local/bin:$PATH"
nohup python3 app/startup.py > /tmp/swapmaster_startup.log 2>&1 &

# Health check
curl http://localhost:8765/healthz

# Check GPU
nvidia-smi

# Check encoder
grep OUTPUT_VIDEO_ENCODER .env
~/.local/bin/ffmpeg -encoders 2>/dev/null | grep -E "libx264|h264_qsv|h264_nvenc"

# Check models
find app/facefusion/.assets/models -name "*.onnx" | wc -l

# Check GDrive
rclone --config .config/rclone/rclone.conf lsd gdrive:
```

### Environment Variables Reference

| Variable | Description | Default |
|----------|-------------|---------|
| `BOT_TOKEN` | Telegram bot token from @BotFather | Required |
| `ALLOWED_USER_ID` | Your Telegram user ID | Required |
| `MEGA_EMAIL` | MEGA account email (dummy ok for anon) | Optional |
| `MEGA_PASSWORD` | MEGA account password | Optional |
| `GDRIVE_ENABLED` | Enable GDrive upload | `true` |
| `GDRIVE_FOLDER` | GDrive folder path | `gdrive:faceswap_output` |
| `RCLONE_CONF` | Absolute path to rclone.conf | Required |
| `EXECUTION_PROVIDER` | `cuda` or `cpu` | `cuda` |
| `GPU_ONLY_MODE` | Skip CPU fallback | `true` |
| `FACE_SWAPPER_MODEL` | Model: inswapper_128 | `inswapper_128` |
| `FACE_ENHANCER_MODEL` | Model: gfpgan_1.4 | `gfpgan_1.4` |
| `FACE_ENHANCER_BLEND` | Enhancement strength 0-100 | `80` |
| `ENABLE_FACE_ENHANCER` | Enable face enhancement | `true` |
| `OUTPUT_VIDEO_ENCODER` | FFmpeg encoder | `h264_qsv` |
| `EXECUTION_THREAD_COUNT` | CPU threads for processing | `4` |
| `THREAD_COUNT` | General thread count | `4` |
| `AUTO_SLEEP_ENABLED` | Auto-sleep when idle | `true` |
| `AUTO_SLEEP_MINUTES` | Minutes before sleep | `30` |
| `DASHBOARD_ENABLED` | Enable health dashboard | `true` |
| `DASHBOARD_PORT` | Dashboard port | `8765` |
| `PIPELINE_WATCHDOG_PROCESSING_SEC` | Processing timeout | `600` |
| `PIPELINE_WATCHDOG_MERGING_SEC` | Merging timeout | `300` |
| `PIPELINE_WATCHDOG_UPLOADING_SEC` | Upload timeout | `300` |

### MEGA Test Links (Hardcoded in Bot)

| Type | Link |
|------|------|
| Test Face | `https://mega.nz/file/0dpElBaa#6SfgxfDhmrO3N4TeyUcDKpebN4YDNbWQjvnxVplDLJw` |
| Test Video | `https://mega.nz/file/y9RElKiB#kHQimH4zXbuq0aCCgiBvU8vbgvnwD1CG8AYU1-Mghgw` |
