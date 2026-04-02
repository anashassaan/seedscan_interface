import struct, os

path = r"C:\Users\anash\OneDrive\Desktop\UI\seedscan_ui\assets\models\seedscan_ai.gguf"
size = os.path.getsize(path)
print(f"File size: {size / (1024 * 1024):.1f} MB")

with open(path, "rb") as f:
    magic = f.read(4)
    print(f"Magic: {magic}")
    version = struct.unpack("<I", f.read(4))[0]
    print(f"GGUF Version: {version}")
    tensor_count = struct.unpack("<Q", f.read(8))[0]
    print(f"Tensor count: {tensor_count}")
    kv_count = struct.unpack("<Q", f.read(8))[0]
    print(f"KV count: {kv_count}")

    for i in range(min(20, kv_count)):
        try:
            key_len = struct.unpack("<Q", f.read(8))[0]
            key = f.read(key_len).decode("utf-8", errors="replace")
            val_type = struct.unpack("<I", f.read(4))[0]
            if val_type == 8:
                val_len = struct.unpack("<Q", f.read(8))[0]
                val = f.read(val_len).decode("utf-8", errors="replace")
                print(f"  {key} = {val!r}")
            elif val_type == 4:
                val = struct.unpack("<I", f.read(4))[0]
                print(f"  {key} = {val}")
            elif val_type == 6:
                val = struct.unpack("<f", f.read(4))[0]
                print(f"  {key} = {val}")
            elif val_type == 5:
                val = struct.unpack("<i", f.read(4))[0]
                print(f"  {key} = {val}")
            elif val_type == 7:
                val = struct.unpack("<B", f.read(1))[0]
                print(f"  {key} = {bool(val)}")
            elif val_type == 10:
                val = struct.unpack("<Q", f.read(8))[0]
                print(f"  {key} = {val}")
            elif val_type == 12:
                arr_type = struct.unpack("<I", f.read(4))[0]
                arr_len = struct.unpack("<Q", f.read(8))[0]
                sizes = {4: 4, 5: 4, 6: 4, 7: 1, 10: 8, 11: 8}
                if arr_type in sizes:
                    f.read(arr_len * sizes[arr_type])
                    print(f"  {key} = [array of {arr_len} type={arr_type}]")
                else:
                    print(f"  {key} = [complex array, stopping]")
                    break
            else:
                print(f"  {key} = (unknown type {val_type})")
                break
        except Exception as e:
            print(f"  Error at kv {i}: {e}")
            break
