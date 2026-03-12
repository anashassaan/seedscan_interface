import numpy as np
from ai_edge_litert.interpreter import Interpreter
from PIL import Image

model = (
    r"C:\Users\anash\OneDrive\Desktop\UI\seedscan_ui\assets\models\best_float32.tflite"
)
interp = Interpreter(model_path=model)
interp.allocate_tensors()
inp = interp.get_input_details()[0]
out_idx = interp.get_output_details()[0]["index"]

img_path = r"C:\Users\anash\OneDrive\Desktop\UI\seedscan_ui\assets\images\plant1.avif"
im = Image.open(img_path).resize((640, 640)).convert("RGB")
rgb = np.array(im, dtype=np.float32)  # 0-255


def run(label, arr):
    data = arr[np.newaxis, ...].astype(np.float32)
    interp.set_tensor(inp["index"], data)
    interp.invoke()
    out = interp.get_tensor(out_idx)[0]  # [5, 8400]
    row4 = out[4]
    n25 = (row4 > 0.25).sum()
    n5 = (row4 > 0.5).sum()
    n01 = (row4 > 0.01).sum()
    n001 = (row4 > 0.001).sum()
    print(f"{label}")
    print(f"  Row4: max={row4.max():.6f}  mean={row4.mean():.8f}")
    print(f"  Anchors >0.001={n001}  >0.01={n01}  >0.25={n25}  >0.5={n5}")
    if row4.max() > 0.001:
        top5 = sorted(row4, reverse=True)[:5]
        print(f"  Top5: {[f'{v:.4f}' for v in top5]}")
    print()


mean_in = np.array([0.485, 0.456, 0.406])
std_in = np.array([0.229, 0.224, 0.225])
bgr = rgb[..., ::-1]

print("=== PLANT IMAGE ===")
run("/255 RGB (0-1)", rgb / 255.0)
run("Raw RGB (0-255)", rgb)
run("/255 BGR (0-1)", bgr / 255.0)
run("Raw BGR (0-255)", bgr)
run("ImageNet RGB", (rgb / 255.0 - mean_in) / std_in)
run("ImageNet BGR", (bgr / 255.0 - mean_in) / std_in)
run("[-1,1] RGB", rgb / 127.5 - 1.0)
run("[-1,1] BGR", bgr / 127.5 - 1.0)

print("=== PURE GREEN IMAGE (non-apple baseline) ===")
green = np.zeros((640, 640, 3), dtype=np.float32)
green[..., 1] = 180
run("Green /255", green / 255.0)
run("Green raw", green)
run("Green ImageNet", (green / 255.0 - mean_in) / std_in)
run("Green [-1,1]", green / 127.5 - 1.0)

print("=== WHITE IMAGE ===")
white = np.full((640, 640, 3), 255, dtype=np.float32)
run("White /255", white / 255.0)
run("White raw", white)

print("=== ALL OUTPUT ROWS STATS for /255 RGB ===")
interp.set_tensor(inp["index"], (rgb / 255.0)[np.newaxis, ...].astype(np.float32))
interp.invoke()
out = interp.get_tensor(out_idx)[0]
for i in range(5):
    print(
        f"  Row {i}: min={out[i].min():.4f}  max={out[i].max():.4f}  mean={out[i].mean():.4f}"
    )

print()
print("=== ALL OUTPUT ROWS STATS for raw 0-255 RGB ===")
interp.set_tensor(inp["index"], rgb[np.newaxis, ...].astype(np.float32))
interp.invoke()
out2 = interp.get_tensor(out_idx)[0]
for i in range(5):
    print(
        f"  Row {i}: min={out2[i].min():.4f}  max={out2[i].max():.4f}  mean={out2[i].mean():.4f}"
    )
