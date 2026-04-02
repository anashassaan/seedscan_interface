import json

with open("apple_leaf_detection_yolov8n.ipynb", "r", encoding="utf-8") as f:
    nb = json.load(f)

keywords = [
    "class_names",
    "DISEASE",
    "disease_names",
    "Blotch",
    "Scab",
    "Black_rot",
    "Cedar",
    "rust",
    "class_to_idx",
    "idx_to_class",
    "train_dataset.class",
    "dataset.class",
    "Healthy",
    "ImageFolder",
    "mobilenet",
    "MobileNet",
    "num_classes",
    "disease_dir",
]

for i, cell in enumerate(nb["cells"]):
    src = "".join(cell["source"])
    if any(kw.lower() in src.lower() for kw in keywords):
        print(f"--- Cell {i} (type={cell['cell_type']}) ---")
        print(src[:1000])
        print()
