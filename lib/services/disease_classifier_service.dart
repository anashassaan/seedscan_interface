import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

/// MobileNetV3-based disease classifier for apple leaves.
/// Classifies into 9 disease categories including "Healthy".
class DiseaseClassifierService {
  static Interpreter? _interpreter;
  static bool _loaded = false;
  static List<int> _inputShape = [];
  static List<int> _outputShape = [];

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

    try {
      // Load model bytes via rootBundle (most reliable cross-platform)
      final modelData = await rootBundle
          .load('assets/models/mobilenetv3_large_disease_updted.tflite');
      final buffer = modelData.buffer.asUint8List();

      _interpreter = Interpreter.fromBuffer(buffer);
      _inputShape = _interpreter!.getInputTensor(0).shape;
      _outputShape = _interpreter!.getOutputTensor(0).shape;

      print('🔬 Disease Classifier loaded');
      print('   Input shape: $_inputShape');
      print('   Output shape: $_outputShape');

      _loaded = true;
    } catch (e) {
      print('❌ Failed to load disease classifier: $e');
      rethrow;
    }
  }

  /// Perform disease classification on an image.
  /// Returns { disease, confidence, severity }.
  static Future<Map<String, dynamic>> classify(img.Image image) async {
    await loadModel();

    if (_interpreter == null) {
      return {"disease": "Unknown", "confidence": 0.0, "severity": 0};
    }

    final int height = _inputShape[1];
    final int width = _inputShape[2];
    final int channels = _inputShape.length > 3 ? _inputShape[3] : 1;

    final int minSide = math.min(image.width, image.height);
    final int cropX = (image.width - minSide) ~/ 2;
    final int cropY = (image.height - minSide) ~/ 2;

    // First crop to square to prevent distortion, then use linear interpolation
    // to match Keras PIL Bilinear resizing.
    final cropped = img.copyCrop(image,
        x: cropX, y: cropY, width: minSide, height: minSide);
    final resized = img.copyResize(cropped,
        width: width, height: height, interpolation: img.Interpolation.linear);

    // Build input tensor matching model's expected shape
    var input = _buildInputTensor(resized, height, width, channels);

    // Build output tensor from model's output shape
    final int numClasses = _outputShape.last;
    var output = List.filled(1 * numClasses, 0.0).reshape([1, numClasses]);

    _interpreter!.run(input, output);

    // Debug: print raw output scores for all classes
    print('🔬 Raw model output scores:');
    for (int i = 0; i < numClasses && i < classes.length; i++) {
      final score = (output[0][i] as num).toDouble();
      print('   ${classes[i]}: ${score.toStringAsFixed(6)}');
    }

    // Apply softmax if output looks like raw logits (values outside 0-1 or not summing to ~1)
    List<double> probs =
        List.generate(numClasses, (i) => (output[0][i] as num).toDouble());

    double sum = probs.fold(0.0, (a, b) => a + b);
    bool looksLikeLogits =
        probs.any((v) => v < 0 || v > 1.0) || (sum - 1.0).abs() > 0.1;

    if (looksLikeLogits) {
      print('   ⚠️ Raw logits detected, applying softmax...');
      probs = _softmax(probs);
      print('   After softmax:');
      for (int i = 0; i < probs.length && i < classes.length; i++) {
        print('   ${classes[i]}: ${probs[i].toStringAsFixed(6)}');
      }
    }

    // Find the class with highest probability
    double maxProb = -1;
    int maxIndex = 0;

    for (int i = 0; i < probs.length && i < classes.length; i++) {
      if (probs[i] > maxProb) {
        maxProb = probs[i];
        maxIndex = i;
      }
    }

    String disease = maxIndex < classes.length ? classes[maxIndex] : "Unknown";
    int severity = _calculateSeverity(maxProb);

    print('   ✅ Prediction: $disease (${(maxProb * 100).toStringAsFixed(1)}%)');

    return {
      "disease": disease,
      "confidence": maxProb,
      "severity": severity,
    };
  }

  /// Softmax function for converting logits to probabilities
  static List<double> _softmax(List<double> logits) {
    final double maxLogit = logits.reduce((a, b) => a > b ? a : b);
    final List<double> exps =
        logits.map((l) => math.exp(l - maxLogit)).toList();
    final double sumExp = exps.fold(0.0, (a, b) => a + b);
    return exps.map((e) => e / sumExp).toList();
  }

  /// Builds the input tensor based on model's channel requirements.
  /// Uses ImageNet normalization (mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])
  /// which is standard for MobileNetV3 models trained with PyTorch/torchvision.
  static List _buildInputTensor(
      img.Image image, int height, int width, int channels) {
    // ⚠️ Keras MobileNetV3 expects raw [0-255] floats because tf.keras Rescaling is built-in.
    // Removed the incorrect PyTorch ImageNet normalize (mean/std subtraction).
    if (channels >= 3) {
      // RGB input [1, H, W, 3] with [0.0, 255.0] mapping
      return List.generate(
        1,
        (_) => List.generate(
          height,
          (y) => List.generate(width, (x) {
            final pixel = image.getPixel(x, y);
            return [
              pixel.r.toDouble(),
              pixel.g.toDouble(),
              pixel.b.toDouble(),
            ];
          }),
        ),
      );
    } else if (channels == 1) {
      // Grayscale [1, H, W, 1]
      return List.generate(
        1,
        (_) => List.generate(
          height,
          (y) => List.generate(width, (x) {
            final pixel = image.getPixel(x, y);
            final lum = img.getLuminance(pixel);
            return [lum.toDouble()]; // 0-255 scale
          }),
        ),
      );
    } else {
      // Fallback: 3D tensor [1, H, W] grayscale without channel dim
      return List.generate(
        1,
        (_) => List.generate(
          height,
          (y) => List.generate(width, (x) {
            final pixel = image.getPixel(x, y);
            return img.getLuminance(pixel).toDouble();
          }),
        ),
      );
    }
  }

  /// Severity scale 1–5 based on confidence.
  static int _calculateSeverity(double confidence) {
    if (confidence < 0.20) return 1; // Very mild
    if (confidence < 0.40) return 2; // Mild
    if (confidence < 0.60) return 3; // Moderate
    if (confidence < 0.80) return 4; // Severe
    return 5; // Very severe
  }

  static void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _loaded = false;
  }
}
