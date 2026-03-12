"""
Complete model analysis using the training notebook knowledge.

Key facts from training code:
- YOLOv8n trained with Ultralytics, imgsz=640
- Binary detection: single class 'apple-leaf'
- conf=0.008 used in all inference (very low threshold)
- smart_preprocess: gamma(1.2) + CLAHE applied BEFORE inference
- model.predict() handles: letterbox + /255 internally
- TFLite output [1, 5, 8400]: rows 0-3 = decoded bbox, row 4 = class confidence (post-sigmoid)
"""

import numpy as np
import urllib.request
import io
import os
from ai_edge_litert.interpreter import Interpreter
from PIL import Image, ImageEnhance, ImageFilter
import cv2

model = (
    r"C:\Users\anash\OneDrive\Desktop\UI\seedscan_ui\assets\models\best_float32.tflite"
)
interp = Interpreter(model_path=model)
interp.allocate_tensors()
inp = interp.get_input_details()[0]
out_idx = interp.get_output_details()[0]["index"]


def infer(label, arr_float01):
    """arr_float01: numpy [640,640,3] float32 in [0,1]"""
    data = arr_float01[np.newaxis, ...].astype(np.float32)
    interp.set_tensor(inp["index"], data)
    interp.invoke()
    out = interp.get_tensor(out_idx)[0]  # [5, 8400]
    row4 = out[4]
    top10 = sorted(row4, reverse=True)[:10]
    n_above = {
        t: int((row4 > t).sum()) for t in [0.001, 0.005, 0.008, 0.01, 0.05, 0.1, 0.25]
    }
    print(f"\n>>> {label}")
    print(
        f"    Row4: max={row4.max():.6f}  mean={row4.mean():.8f}  std={row4.std():.8f}"
    )
    print(f"    Top10: {[f'{v:.5f}' for v in top10]}")
    for t, cnt in n_above.items():
        print(f"    > {t}: {cnt} anchors")
    return row4.max()


def smart_preprocess_pil(pil_img_rgb):
    """
    Replicate notebook's smart_preprocess:
    1. Gamma correction (gamma=1.2, invGamma=1/1.2 makes image BRIGHTER)
    2. CLAHE on L channel of LAB
    """
    img_np = np.array(pil_img_rgb)

    # Convert to BGR for OpenCV
    img_bgr = cv2.cvtColor(img_np, cv2.COLOR_RGB2BGR)

    # 1. Gamma correction
    gamma = 1.2
    invGamma = 1.0 / gamma
    table = np.array([((i / 255.0) ** invGamma) * 255 for i in range(256)]).astype(
        "uint8"
    )
    img_bright = cv2.LUT(img_bgr, table)

    # 2. CLAHE on LAB L channel
    clahe = cv2.createCLAHE(clipLimit=3.0, tileGridSize=(8, 8))
    lab = cv2.cvtColor(img_bright, cv2.COLOR_BGR2LAB)
    l, a, b = cv2.split(lab)
    l2 = clahe.apply(l)
    lab_merged = cv2.merge((l2, a, b))
    img_final = cv2.cvtColor(lab_merged, cv2.COLOR_LAB2RGB)

    return img_final  # uint8 RGB [0-255]


def load_and_letterbox(pil_img, size=640):
    """Exact Ultralytics letterbox: resize with aspect-ratio preservation + gray padding."""
    iw, ih = pil_img.size
    scale = size / max(iw, ih)
    nw, nh = int(iw * scale), int(ih * scale)
    resized = pil_img.resize((nw, nh), Image.BILINEAR)
    canvas = Image.new("RGB", (size, size), (114, 114, 114))
    canvas.paste(resized, ((size - nw) // 2, (size - nh) // 2))
    return canvas


# ─── Download Apple Leaf images to test ──────────────────────────────────────
print("=" * 70)
print("DOWNLOADING REAL APPLE LEAF IMAGES FOR TESTING")
print("=" * 70)

test_urls = [
    (
        "Apple leaf (Wikimedia)",
        "https://upload.wikimedia.org/wikipedia/commons/thumb/4/43/Apple_leaves_texture.jpg/640px-Apple_leaves_texture.jpg",
    ),
    (
        "Apple leaf 2",
        "https://upload.wikimedia.org/wikipedia/commons/thumb/6/6b/Apple_Leaf_Anatomy.jpg/640px-Apple_Leaf_Anatomy.jpg",
    ),
]

downloaded_images = {}
for name, url in test_urls:
    try:
        req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
        with urllib.request.urlopen(req, timeout=10) as r:
            data = r.read()
        img = Image.open(io.BytesIO(data)).convert("RGB")
        downloaded_images[name] = img
        print(f"  ✅ {name}: {img.size}")
    except Exception as e:
        print(f"  ❌ {name}: {e}")

# ─── Also test with a synthetic apple-leaf-like patch ────────────────────────
print("\n=== SYNTHETIC TEST IMAGES ===")
# Make a realistic green leaf: green gradient with some texture
leaf_synth = np.zeros((640, 640, 3), dtype=np.float32)
for y in range(640):
    for x in range(640):
        # Create leaf-like green gradient
        cy, cx = 320, 320
        dist = ((y - cy) ** 2 / 200**2 + (x - cx) ** 2 / 250**2) ** 0.5
        if dist < 1.0:
            leaf_synth[y, x, 0] = max(0, 0.1 - 0.05 * dist)  # R
            leaf_synth[y, x, 1] = max(0, 0.4 - 0.1 * dist)  # G
            leaf_synth[y, x, 2] = max(0, 0.05 - 0.02 * dist)  # B
        else:
            leaf_synth[y, x] = [0.48, 0.48, 0.48]  # gray background

print("Synthetic shapes done")

# ─── Run inference ────────────────────────────────────────────────────────────
print("\n" + "=" * 70)
print("INFERENCE RESULTS — /255 normalization, simple resize 640x640")
print("=" * 70)

# Test downloaded images
for name, pil_img in downloaded_images.items():
    arr = np.array(pil_img.resize((640, 640), Image.BILINEAR), dtype=np.float32) / 255.0
    score = infer(f"{name} (simple resize /255)", arr)

    # With letterbox
    lb = load_and_letterbox(pil_img)
    arr_lb = np.array(lb, dtype=np.float32) / 255.0
    score_lb = infer(f"{name} (letterbox /255)", arr_lb)

    # With smart_preprocess
    arr_np = np.array(pil_img.resize((640, 640), Image.BILINEAR))
    preprocessed = smart_preprocess_pil(Image.fromarray(arr_np))
    arr_pre = np.array(preprocessed, dtype=np.float32) / 255.0
    score_pre = infer(f"{name} (smart_preprocess /255)", arr_pre)

# Synthetic leaf
infer("Synthetic leaf /255", leaf_synth)

# ─── Key stats ───────────────────────────────────────────────────────────────
print("\n" + "=" * 70)
print("SUMMARY: Correct threshold to use")
print("=" * 70)
print("If apple leaf images give row4.max > 0.008 → threshold should be 0.008")
print(
    "If values are near-zero → model needs different input or is not working via TFLite"
)
print()
print("Training notebook used: conf=0.008 with Ultralytics .predict()")
print("Recommendation: match this threshold in Flutter")
