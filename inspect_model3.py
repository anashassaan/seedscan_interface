"""
Deep-dive: check ALL tensors in TFLite model and test multiple input formats
systematically to find what produces VALID apple-leaf detections.
"""

import numpy as np
import cv2
from ai_edge_litert.interpreter import Interpreter
from PIL import Image

model = (
    r"C:\Users\anash\OneDrive\Desktop\UI\seedscan_ui\assets\models\best_float32.tflite"
)
interp = Interpreter(model_path=model)
interp.allocate_tensors()
inp_d = interp.get_input_details()[0]
out_d = interp.get_output_details()[0]

# ── All tensors ───────────────────────────────────────────────────────────────
print("=== ALL TENSORS IN THE MODEL ===")
all_tensors = interp.get_tensor_details()
print(f"Total tensors: {len(all_tensors)}")
for t in all_tensors[:20]:  # show first 20
    shape = t["shape"].tolist() if hasattr(t["shape"], "tolist") else t["shape"]
    print(
        f"  [{t['index']:3d}] {t['name']:<40} shape={shape} dtype={t['dtype'].__name__ if hasattr(t['dtype'], '__name__') else t['dtype']}"
    )

print()

# ── Check if output needs sigmoid ────────────────────────────────────────────
print("=== OUTPUT RANGE ANALYSIS ===")
print("Input shape:", inp_d["shape"].tolist())
print("Output shape:", out_d["shape"].tolist())
print()

# Test: what does the notebook's test data look like after preprocessing?
# We know training used YOLOv8n on Roboflow dataset
# Key: training images went through Ultralytics auto-augment
# conf=0.008 means post-sigmoid value was ≥ 0.008

# Simulate what Ultralytics does internally:
#   1. letterbox(img, 640, color=(114,114,114))
#   2. im = im[np.newaxis, ...] / 255.0
#   3. in [B, H, W, C] for TFLite


def letterbox_np(img_rgb_np, size=640, fill=114):
    """Exact Ultralytics letterbox with gray padding."""
    h0, w0 = img_rgb_np.shape[:2]
    r = size / max(h0, w0)
    # Prevent scaling up if not needed (optional, matches Ultralytics default usually)
    # if r > 1: r = 1

    h1, w1 = int(round(h0 * r)), int(round(w0 * r))
    # Resize
    img_resized = cv2.resize(img_rgb_np, (w1, h1), interpolation=cv2.INTER_LINEAR)
    # Pad
    canvas = np.full((size, size, 3), fill, dtype=img_resized.dtype)
    dy = (size - h1) // 2
    dx = (size - w1) // 2
    canvas[dy : dy + h1, dx : dx + w1] = img_resized
    return canvas


def run_and_report(label, arr_float01):
    # Ensure input is float32 0-1 range
    data = arr_float01[np.newaxis, ...].astype(np.float32)
    interp.set_tensor(inp_d["index"], data)
    interp.invoke()

    # Get raw output [1, C, A] or [1, A, C]
    raw_out = interp.get_tensor(out_d["index"])[0]

    # ─── DYNAMIC SHAPE HANDLING ──────────────────────────────────────────────
    # YOLOv8 binary output is usually 5 channels: [x, y, w, h, conf]
    # Shape could be (5, 8400) or (8400, 5).

    if raw_out.shape[0] > raw_out.shape[-1]:
        # Case: (8400, 5) -> Channels Last. Transpose to (5, 8400) for consistency
        out = raw_out.T
        shape_type = "(Anchors, Channels) -> Transposed"
    else:
        # Case: (5, 8400) -> Channels First. Use as is.
        out = raw_out
        shape_type = "(Channels, Anchors)"

    # Index 4 is confidence in binary classification (x,y,w,h,conf)
    # Be careful: if you have >1 class, indices start at 4.
    # Assuming binary model (1 class), channel 4 is the class probability.
    r4 = out[4, :]

    max_val = float(r4.max())
    above_008 = int((r4 > 0.008).sum())
    above_001 = int((r4 > 0.001).sum())
    top5 = [float(v) for v in sorted(r4, reverse=True)[:5]]
    print(f"  {label}")
    print(f"    Shape detected: {raw_out.shape} {shape_type}")
    print(f"    row4: max={max_val:.7f}  >0.001:{above_001}  >0.008:{above_008}")
    print(f"    top5: {[f'{v:.6f}' for v in top5]}")
    return max_val


# Make a pure bright green leaf-colored patch
# An apple leaf is typically HSV: H≈90-130°, S≈0.4-0.8, V≈0.3-0.7
print("=== TEST 1: COLOR-ACCURATE LEAF PATCHES ===")


# HSV to RGB
def hsv_to_rgb(h, s, v):
    """h: 0-360, s: 0-1, v: 0-1 → RGB floats"""
    import colorsys

    r, g, b = colorsys.hsv_to_rgb(h / 360.0, s, v)
    return r, g, b


# Apple leaf colors
leaf_colors = [(100, 0.6, 0.4), (110, 0.5, 0.5), (120, 0.65, 0.35), (90, 0.4, 0.45)]
for h, s, v in leaf_colors:
    r, g, b = hsv_to_rgb(h, s, v)
    canvas = np.zeros((640, 640, 3), dtype=np.float32)
    # Draw an ellipse (like leaf shape)
    cv2.ellipse(canvas, (320, 320), (200, 280), 0, 0, 360, (r, g, b), -1)
    run_and_report(f"Leaf ellipse HSV({h},{s},{v})", canvas)

print()
print("=== TEST 2: VARIOUS GREEN GRADIENTS ===")
for g_val in [0.2, 0.3, 0.4, 0.5]:
    img = np.zeros((640, 640, 3), dtype=np.float32)
    img[:, :, 1] = g_val
    img[:, :, 0] = g_val * 0.3
    run_and_report(f"Green (R={g_val * 0.3:.1f} G={g_val:.1f} B=0)", img)

print()
print("=== TEST 3: RAW 0-255 uint8-as-float tests ===")
canvas255 = np.zeros((640, 640, 3), dtype=np.float32)
r, g, b = hsv_to_rgb(110, 0.6, 0.5)
cv2.ellipse(
    canvas255, (320, 320), (200, 280), 0, 0, 360, (r * 255, g * 255, b * 255), -1
)
run_and_report("Leaf ellipse raw 0-255", canvas255)

print()
print("=== TEST 4: ALL INTERMEDIATE TENSOR VALUES ===")
# Run with the leaf ellipse and inspect what activations look like
canvas_leaf = np.zeros((640, 640, 3), dtype=np.float32)
r, g, b = hsv_to_rgb(110, 0.6, 0.5)
cv2.ellipse(canvas_leaf, (320, 320), (200, 280), 0, 0, 360, (r, g, b), -1)
data = canvas_leaf[np.newaxis, ...].astype(np.float32)
interp.set_tensor(inp_d["index"], data)
interp.invoke()

raw_out = interp.get_tensor(out_d["index"])[0]
# Normalize shape for inspection
if raw_out.shape[0] > raw_out.shape[-1]:
    out = raw_out.T
else:
    out = raw_out

print("All 5 rows stats (leaf ellipse, /255):")
for i in range(5):
    row = out[i]
    print(f"  Row {i}: min={row.min():.5f}  max={row.max():.5f}  mean={row.mean():.5f}")

# Try reading in the anchors that fired highest (index 4)
top_anchors_idx = np.argsort(out[4])[::-1][:10]
print("\nTop 10 anchor details [cx, cy, w, h, conf]:")
for ai in top_anchors_idx:
    print(
        f"  anchor {ai:4d}: cx={out[0][ai]:.3f} cy={out[1][ai]:.3f} w={out[2][ai]:.3f} h={out[3][ai]:.3f} conf={out[4][ai]:.6f}"
    )

print()
print("=== CONCLUSION ===")
max_seen = []
for h, s, v in [(100, 0.6, 0.4), (110, 0.5, 0.5)]:
    r, g, b = hsv_to_rgb(h, s, v)
    c = np.zeros((640, 640, 3), dtype=np.float32)
    cv2.ellipse(c, (320, 320), (200, 280), 0, 0, 360, (r, g, b), -1)
    d = c[np.newaxis, ...].astype(np.float32)
    interp.set_tensor(inp_d["index"], d)
    interp.invoke()

    res = interp.get_tensor(out_d["index"])[0]
    # Robust check
    if res.shape[0] > res.shape[-1]:
        max_seen.append(res[:, 4].max())  # (8400, 5) -> take col 4
    else:
        max_seen.append(res[4, :].max())  # (5, 8400) -> take row 4

overall_max = max(max_seen)
print(f"Best confidence seen on synthetic leaf: {overall_max:.7f}")
if overall_max < 0.001:
    print("DIAGNOSIS: Model outputs near-zero for all inputs.")
    print("ROOT CAUSE: TFLite model may have been exported incorrectly,")
    print("  OR the model requires a fundamentally different preprocessing.")
    print("  The notebook's conf=0.008 was for the PyTorch .pt model,")
    print("  not this TFLite export.")
    print()
    print("RECOMMENDATION: Re-export the .pt model to TFLite using:")
    print("  from ultralytics import YOLO")
    print("  model = YOLO('best.pt')")
    print("  model.export(format='tflite')")
