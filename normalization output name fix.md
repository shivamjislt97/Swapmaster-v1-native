# Normalization Output Name Fix — Documentation

## Issue

Bot Telegram par normalize notification me **intermediate processing name** dikhata tha, final output name nahi. Saath hi, output files ka naam same hota tha agar same file dubara process karo — overwrite ka risk tha.

---

## Root Cause

### Problem 1: Normalize notification me galat naam

**Before Fix:**
```
normalize_processing_target() function target file ko rename karta tha:
video.mp4 → video_1751234.mp4   (short timestamp suffix)

Lekin notification me ye intermediate name dikhata tha:
"Target filename normalize ki gayi: video.mp4 → video_1751234.mp4"

User ko samajh nahi aata tha ki final output ka naam kya hoga.
```

### Problem 2: Output files overwrite hota tha

**Before Fix:**
```python
# Same filename har baar
out = f"{OUTPUTS_DIR}/{stem}_faceswapped.mp4"
# Agar same file 2 baar process karo → pehla output overwrite!
```

---

## Fix Applied

### Fix 1: Timestamp-based unique output names

**File:** `app/bot.py`

**Change:** Har output filename me **DDMMYY_HHMMSS** timestamp add kiya.

**Line 11713-11714** (Main output):
```python
_ts = datetime.now().strftime("%d%m%y_%H%M%S")
out = f"{OUTPUTS_DIR}/{orig_stem}_faceswapped_{_ts}{out_ext}"
```

**Example:**
```
Input:  video.mp4
Output: video_faceswapped_280626_143025.mp4
                 (DDMMYY) (HHMMSS)
```

### Fix 2: Selective mode output naming

**Line 12226:**
```python
pass_out = f"{OUTPUTS_DIR}/{orig_stem}_faceswapped_sel{pass_idx}_{_ts}{out_ext}"
```

**Example:**
```
video_faceswapped_sel1_280626_143025.mp4  (Pass 1)
video_faceswapped_sel2_280626_143025.mp4  (Pass 2)
```

### Fix 3: Segment mode output naming

**Line 12307:**
```python
seg_out = f"{OUTPUTS_DIR}/{orig_stem}_faceswapped_seg{seg_idx}_{_ts}.mp4"
```

**Example:**
```
video_faceswapped_seg1_280626_143025.mp4  (Segment 1)
video_faceswapped_seg2_280626_143025.mp4  (Segment 2)
```

### Fix 4: GPU retry segment naming

**Line 12118:**
```python
seg_out = f"{OUTPUTS_DIR}/{orig_stem}_gpu_l{retry_level}_seg{seg_idx}.mp4"
```

### Fix 5: Normalize notification final name dikhata hai

**Line 11574-11579:**
```python
_out_ts = datetime.now().strftime("%d%m%y_%H%M%S")
_preview_name = f"{_out_stem}_faceswapped_{_out_ts}.mp4"
await notify(
    "ℹ️ Target filename normalize ki gayi for stable processing:\n"
    f"`{original_target_name}` → `{_preview_name}`"
)
```

**Before:**
```
Target filename normalize ki gayi: video.mp4 → video_1751234.mp4
```

**After:**
```
Target filename normalize ki gayi for stable processing:
video.mp4 → video_faceswapped_280626_143025.mp4
```

User ko ab **final output ka naam pehle se pata chal jata hai**.

### Fix 6: Final success notification me output name

**Line 13642:**
```python
f"📁 `{os.path.basename(upload_path)}`\n"
```

**Example notification:**
```
━━━━━━━━━━━━━━━━━━━━━
✅ FaceSwap Completed Successfully
━━━━━━━━━━━━━━━━━━━━━
📥 Download  → 12s
⚙️ FaceSwap → 3m 45s
⬆️ Upload    → 45s
⏱ Total    → 4m 42s

📁 video_faceswapped_280626_143025.mp4
📦 25.3 MB
🖥 GPU: YES
☁️ Google Drive
🔗 Google Drive Link: https://drive.google.com/...

⏱ Job complete. Studio 30 min baad auto-sleep hoga.
```

---

## Key Code Sections

### 1. normalize_processing_target() — Line 4283-4306

```python
def normalize_processing_target(target_path, chat_id):
    """Rename target to a glob-safe filename preserving original name keywords."""
    src = Path(target_path)
    ext = src.suffix.lower()
    safe_stem = re.sub(r"[^A-Za-z0-9._-]+", "_", src.stem).strip("._-")
    _mega_id_only = re.match(r"^mega_[A-Za-z0-9]{6,12}$", safe_stem)
    if not safe_stem or _mega_id_only:
        safe_stem = "video"
    safe_stem = safe_stem[:40].strip("._-")
    unique = str(int(time.time()))[-6:]  # Short timestamp for uniqueness
    safe_name = f"{safe_stem}_{unique}{ext}"
    dst = src.with_name(safe_name)
    if dst == src:
        return str(src), src.name
    src.rename(dst)
    return str(dst), src.name
```

**Purpose:** Target file ko safe naam deta hai processing ke liye. MEGA links ke random IDs ko "video" me convert karta hai.

### 2. Output filename generation — Line 11707-11714

```python
# Use the ORIGINAL filename stem (before normalize_processing_target mangling)
orig_stem = re.sub(r"[^A-Za-z0-9._-]+", "_", Path(original_target_name).stem).strip("._-") or "output"
# Strip MEGA file-ID-only stems (no useful keywords)
if re.match(r"^mega_[A-Za-z0-9]{6,12}$", orig_stem):
    orig_stem = "video"
orig_stem = orig_stem[:40].strip("._-") or "output"
_ts = datetime.now().strftime("%d%m%y_%H%M%S")
out = f"{OUTPUTS_DIR}/{orig_stem}_faceswapped_{_ts}{out_ext}"
```

**Purpose:** Original filename stem use karta hai (normalize se pehle ka), timestamp add karta hai uniqueness ke liye.

### 3. Timestamp format

```python
datetime.now().strftime("%d%m%y_%H%M%S")
# %d = day (01-31)
# %m = month (01-12)
# %y = year (2 digits)
# %H = hour (00-23)
# %M = minute (00-59)
# %S = second (00-59)
# Example: 280626_143025 = 28 June 2026, 14:30:25
```

---

## Output Filename Patterns

| Mode | Pattern | Example |
|------|---------|---------|
| Main swap | `{stem}_faceswapped_{DDMMYY_HHMMSS}{ext}` | `video_faceswapped_280626_143025.mp4` |
| Selective swap | `{stem}_faceswapped_sel{N}_{DDMMYY_HHMMSS}{ext}` | `video_faceswapped_sel1_280626_143025.mp4` |
| Segment swap | `{stem}_faceswapped_seg{N}_{DDMMYY_HHMMSS}.mp4` | `video_faceswapped_seg1_280626_143025.mp4` |
| GPU retry | `{stem}_gpu_l{L}_seg{N}.mp4` | `video_gpu_l1_seg2.mp4` |
| Normalize preview | `{stem}_faceswapped_{DDMMYY_HHMMSS}.mp4` | `video_faceswapped_280626_143025.mp4` |

---

## Why This Fix Matters

1. **No overwrites** — Same file 10 baar process karo, har baar alag output
2. **User knows final name** — Normalize notification me final naam dikhta hai
3. **Organized outputs** — Timestamp se pata chalta hai kab process hua
4. **Debugging easy** — Har output ka unique identifier hai
5. **MEGA links handled** — Random MEGA IDs ko "video" me convert karta hai

---

## Files Modified

| File | Lines | Change |
|------|-------|--------|
| `app/bot.py` | 11574-11579 | Normalize notification me final name |
| `app/bot.py` | 11707-11714 | Main output filename with timestamp |
| `app/bot.py` | 12226 | Selective mode output with timestamp |
| `app/bot.py` | 12307 | Segment mode output with timestamp |
| `app/bot.py` | 12118 | GPU retry segment naming |
| `app/bot.py` | 13642 | Final success notification me output name |
| `app/bot.py` | 4283-4306 | normalize_processing_target() function |

---

## Testing

To verify the fix works:
1. Send same video twice to the bot
2. Check that both outputs have different timestamps
3. Check that normalize notification shows final output name
4. Check that success notification shows correct output filename

```
Video 1 → video_faceswapped_280626_143025.mp4
Video 2 → video_faceswapped_280626_143102.mp4
(No overwrite!)
```
