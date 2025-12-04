import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class AppleDetectionService {
  static late Interpreter _interpreter;
  static bool _loaded = false;

  static Future<void> loadModel() async {
    if (_loaded) return;

    _interpreter = await Interpreter.fromAsset('models/apple_detector.tflite');
    _loaded = true;
  }

  /// Returns true if Apple Leaf, false if Non-Apple Leaf
  static Future<bool> isAppleLeaf(img.Image image) async {
    await loadModel();

    // YOLO classification expecting 224x224 input (confirm after conversion)
    final resized = img.copyResize(image, width: 224, height: 224);

    var input = List.generate(
      1,
      (_) => List.generate(
        224,
        (_) => List.generate(
          224,
          (_) => 0.0,
        ),
      ),
    );

    for (int y = 0; y < 224; y++) {
      for (int x = 0; x < 224; x++) {
        final pixel = resized.getPixel(x, y);
        input[0][y][x] = (img.getLuminance(pixel)) / 255.0; // grayscale
      }
    }

    var output = List.filled(1 * 2, 0.0).reshape([1, 2]);

    _interpreter.run(input, output);

    double nonApple = output[0][0];
    double apple = output[0][1];

    return apple > nonApple;
  }
}
