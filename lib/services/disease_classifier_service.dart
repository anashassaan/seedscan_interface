import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class DiseaseClassifierService {
  static late Interpreter _interpreter;
  static bool _loaded = false;

  static const List<String> classes = [
    "Alternaria Leaf Spot",
    "Apple Scab",
    "Black Rot",
    "Brown Spot",
    "Cedar Apple Rust",
    "Grey Spot",
    "Healthy",
    "Mosaic",
    "Powdery Mildew"
  ];

  static Future<void> loadModel() async {
    if (_loaded) return;

    _interpreter =
        await Interpreter.fromAsset('models/disease_classifier.tflite');
    _loaded = true;
  }

  /// Perform disease classification
  static Future<Map<String, dynamic>> classify(img.Image image) async {
    await loadModel();

    final resized = img.copyResize(image, width: 224, height: 224);

    var input = List.generate(
        1, (_) => List.generate(224, (_) => List.generate(224, (_) => 0.0)));

    for (int y = 0; y < 224; y++) {
      for (int x = 0; x < 224; x++) {
        final pixel = resized.getPixel(x, y);
        input[0][y][x] = img.getLuminance(pixel) / 255.0;
      }
    }

    var output = List.filled(1 * 9, 0.0).reshape([1, 9]);
    _interpreter.run(input, output);

    double maxProb = -1;
    int maxIndex = -1;

    for (int i = 0; i < 9; i++) {
      if (output[0][i] > maxProb) {
        maxProb = output[0][i];
        maxIndex = i;
      }
    }

    String disease = classes[maxIndex];
    int severity = _calculateSeverity(maxProb);

    return {
      "disease": disease,
      "confidence": maxProb,
      "severity": severity,
    };
  }

  /// Severity scale 1–5
  static int _calculateSeverity(double confidence) {
    if (confidence < 0.20) return 1; // Very mild
    if (confidence < 0.40) return 2; // Mild
    if (confidence < 0.60) return 3; // Moderate
    if (confidence < 0.80) return 4; // Severe
    return 5; // Very severe
  }
}
