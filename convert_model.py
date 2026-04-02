import os

os.environ["TF_USE_LEGACY_KERAS"] = "1"

import tensorflow as tf
import tf_keras as keras
import numpy as np
from PIL import Image


def main():
    h5_path = "assets/models/best_model_fold_5.h5"
    print(f"Loading {h5_path} with legacy Keras...")

    # Load model
    model = keras.models.load_model(h5_path, compile=False)
    print("Model loaded successfully!")
    print(f"Input shape: {model.input_shape}, Output shape: {model.output_shape}")

    # Run prediction
    img_path = "assets/images/plant1.avif"
    if os.path.exists(img_path):
        print(f"Testing prediction on {img_path}...")
        img = Image.open(img_path).convert("RGB")
        img = img.resize((224, 224))
        img_array = np.array(img, dtype=np.float32) / 255.0
        img_array = np.expand_dims(img_array, axis=0)

        preds = model.predict(img_array)
        print("Raw predictions:", preds[0])
        print("Predicted class index:", np.argmax(preds[0]))

    # Save as .keras
    keras_path = "assets/models/best_model_fold_5.keras"
    model.save(keras_path)
    print(f"Saved modern Keras format to {keras_path}")

    # Convert to TFLite
    print("Converting to TFLite...")
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    # Optional: quantization
    # converter.optimizations = [tf.lite.Optimize.DEFAULT]
    tflite_model = converter.convert()

    tflite_path = "assets/models/best_model_fold_5.tflite"
    with open(tflite_path, "wb") as f:
        f.write(tflite_model)
    print(f"Successfully exported TFLite model to {tflite_path}")


if __name__ == "__main__":
    main()
