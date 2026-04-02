import json

path = (
    r"C:\Users\anash\OneDrive\Desktop\UI\seedscan_ui\mobilenetv3_large_training.ipynb"
)
with open(path, "r", encoding="utf-8") as f:
    nb = json.load(f)

for i, cell in enumerate(nb["cells"]):
    src = "".join(cell["source"])
    print(f"=== Cell {i} [{cell['cell_type']}] ===")
    print(src[:1200])
    print()
