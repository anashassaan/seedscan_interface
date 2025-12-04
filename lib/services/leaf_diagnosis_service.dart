import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

/// Dual-Pipeline Leaf Diagnosis Service
///
/// Based on Netron graph analysis:
/// - YOLO: Requires 640x640 input, normalized 0-1
/// - MobileNet: Requires 224x224 input, RAW 0-255 (has built-in normalization)
class LeafDiagnosisService {
  Interpreter? _yoloInterpreter;
  Interpreter? _mobilenetInterpreter;

  // Disease labels for MobileNetV3 (9 classes) - adjust to match your training
  final List<String> _diseaseLabels = [
    'Altenaria Leaf Spot',
    'Apple Scab',
    'Black Rot',
    'Brown Spot',
    'Cedar Apple Rust',
    'Grey Spot',
    'Healthy',
    'Mosaic',
    'Powdery Mildew'
  ];

  Future<void> loadModels() async {
    print("\n🔄 Loading ML Models...");
    try {
      final options = InterpreterOptions()..threads = 4;

      // 1. Load YOLO (640x640 input expected)
      print("📦 Loading YOLOv8 (Binary Classifier)...");
      _yoloInterpreter = await Interpreter.fromAsset(
        'assets/models/yolov8_apple_classifier.tflite',
        options: options,
      );

      final yoloInputShape = _yoloInterpreter!.getInputTensor(0).shape;
      final yoloOutputShape = _yoloInterpreter!.getOutputTensor(0).shape;
      print("   ✅ YOLO Loaded");
      print("      Input: $yoloInputShape");
      print("      Output: $yoloOutputShape");

      // 2. Load MobileNet (224x224 input expected)
      print("📦 Loading MobileNetV3 (Disease Classifier)...");
      _mobilenetInterpreter = await Interpreter.fromAsset(
        'assets/models/mobilenetv3_apple_disease.tflite',
        options: options,
      );

      final mobileInputShape = _mobilenetInterpreter!.getInputTensor(0).shape;
      final mobileOutputShape = _mobilenetInterpreter!.getOutputTensor(0).shape;
      print("   ✅ MobileNet Loaded");
      print("      Input: $mobileInputShape");
      print("      Output: $mobileOutputShape");

      print("✅ All models loaded successfully!\n");
    } catch (e, stackTrace) {
      print("❌ Error loading models: $e");
      print("Stack trace: $stackTrace");
      rethrow;
    }
  }

  /// Complete prediction pipeline with both models
  Future<Map<String, dynamic>> predict(File imageFile) async {
    if (_yoloInterpreter == null || _mobilenetInterpreter == null) {
      return {'error': 'Models not loaded'};
    }

    try {
      // Load original image
      final bytes = imageFile.readAsBytesSync();
      var originalImage = img.decodeImage(bytes);
      if (originalImage == null) {
        return {'error': 'Failed to decode image'};
      }

      // Fix orientation (critical for custom camera images)
      originalImage = img.bakeOrientation(originalImage);

      print("\n🔍 Starting Dual-Pipeline Inference...");

      // ==========================================
      // STEP 1: YOLO INFERENCE (Binary Check)
      // ==========================================
      print("🎯 Step 1: YOLO - Is this an apple leaf?");

      // CRITICAL: Resize to 640x640 for YOLO (NOT 224!)
      final yoloImage = img.copyResize(originalImage, width: 640, height: 640);

      // CRITICAL: Normalize to 0-1 for YOLO
      final yoloInput = _imageToFloat32List(yoloImage, 640, normalize: true);

      // Get output shape dynamically
      final yoloOutputShape = _yoloInterpreter!.getOutputTensor(0).shape;
      final yoloOutputSize = yoloOutputShape.reduce((a, b) => a * b);
      var yoloOutput =
          List.filled(yoloOutputSize, 0.0).reshape(yoloOutputShape);

      // Run YOLO inference
      _yoloInterpreter!.run(yoloInput, yoloOutput);

      // Parse YOLO output
      final isLeafDetected = _parseYoloOutput(yoloOutput);
      print(
          "   ${isLeafDetected ? '✅ Apple Leaf Detected' : '❌ Not an Apple Leaf'}");

      // ==========================================
      // STEP 2: MOBILENET INFERENCE (Disease ID)
      // ==========================================
      print("🦠 Step 2: MobileNet - Disease Classification");

      // CRITICAL: Resize to 224x224 for MobileNet
      final mobileNetImage =
          img.copyResize(originalImage, width: 224, height: 224);

      // CRITICAL: Do NOT normalize for MobileNet! Use RAW 0-255 values
      final mobileNetInput =
          _imageToFloat32List(mobileNetImage, 224, normalize: false);

      // Output buffer for 9 classes
      var mobileNetOutput = List.filled(9, 0.0).reshape([1, 9]);

      // Run MobileNet inference
      _mobilenetInterpreter!.run(mobileNetInput, mobileNetOutput);

      // Get top prediction
      List<double> probs = List<double>.from(mobileNetOutput[0]);
      int maxIndex = 0;
      double maxProb = 0.0;

      for (int i = 0; i < probs.length; i++) {
        if (probs[i] > maxProb) {
          maxProb = probs[i];
          maxIndex = i;
        }
      }

      final disease = _diseaseLabels[maxIndex];
      final severity = (maxProb * 5).clamp(1, 5).toInt();

      print(
          "   MobileNet Result: $disease (${(maxProb * 100).toStringAsFixed(1)}%)");

      // ==========================================
      // HYBRID DECISION LOGIC
      // ==========================================
      // If YOLO says "Not Apple" but MobileNet is very confident (>70%), trust MobileNet.
      // This handles cases where YOLO misses the leaf but the disease classifier is sure.

      bool finalIsApple = isLeafDetected;
      if (!isLeafDetected && maxProb > 0.70) {
        print(
            "   ⚠️ YOLO missed, but MobileNet is confident ($disease). Overriding.");
        finalIsApple = true;
      }

      if (!finalIsApple) {
        return {
          'result': 'No Apple Leaf Detected',
          'confidence': 0.0,
          'disease': 'N/A',
          'severity': 0
        };
      }

      print("✅ Inference Complete: $disease\n");

      return {
        'result': disease,
        'confidence': maxProb,
        'disease': disease,
        'severity': severity,
      };
    } catch (e, stackTrace) {
      print("❌ Prediction error: $e");
      print("Stack: $stackTrace");
      return {'error': e.toString()};
    }
  }

  /// Legacy method - maintained for backward compatibility
  Future<bool> isAppleLeaf(File imageFile) async {
    final result = await predict(imageFile);
    return result['disease'] != 'N/A';
  }

  /// Legacy method - maintained for backward compatibility
  Future<Map<String, dynamic>> diagnoseDisease(File imageFile) async {
    return await predict(imageFile);
  }

  /// Convert image to Float32List with optional normalization
  /// @param normalize: true for YOLO (0-1), false for MobileNet (0-255)
  List<dynamic> _imageToFloat32List(img.Image image, int size,
      {required bool normalize}) {
    var convertedBytes = Float32List(1 * size * size * 3);
    var buffer = Float32List.view(convertedBytes.buffer);
    int pixelIndex = 0;

    for (var i = 0; i < size; i++) {
      for (var j = 0; j < size; j++) {
        var pixel = image.getPixel(j, i);

        // CRITICAL DISTINCTION:
        // - YOLO: needs 0-1 range (divide by 255)
        // - MobileNet: needs 0-255 range (keep as-is, model normalizes internally)
        final divisor = normalize ? 255.0 : 1.0;
        buffer[pixelIndex++] = pixel.r / divisor;
        buffer[pixelIndex++] = pixel.g / divisor;
        buffer[pixelIndex++] = pixel.b / divisor;
      }
    }

    return convertedBytes.reshape([1, size, size, 3]);
  }

  /// Parse YOLO v8 output: [1, 5, 8400] format
  /// Row 4 contains confidence scores for apple leaf detection
  bool _parseYoloOutput(List<dynamic> output) {
    try {
      const double confidenceThreshold =
          0.25; // Lowered to 25% to be more permissive

      if (output.isEmpty || output[0].isEmpty) {
        print("   ⚠️ YOLO output empty");
        return false;
      }

      // YOLOv8 format: [1, 5, 8400]
      // - Rows 0-3: Bounding box coordinates (x, y, w, h)
      // - Row 4: Confidence scores for 8400 anchor points
      var features = output[0]; // Get the 5 feature rows

      if (features is! List || features.length < 5) {
        print("   ⚠️ Unexpected YOLO structure (need 5 rows)");
        return false;
      }

      // Extract confidence scores from row index 4
      var confidenceRow = features[4];

      if (confidenceRow is! List) {
        print("   ⚠️ Confidence row not accessible");
        return false;
      }

      // Find maximum confidence across all 8400 anchor points
      double maxConfidence = 0.0;
      for (var conf in confidenceRow) {
        if (conf is num) {
          double confValue = conf.toDouble();
          if (confValue > maxConfidence) {
            maxConfidence = confValue;
          }
        }
      }

      // Decision: Is this an apple leaf?
      bool isAppleLeaf = maxConfidence > confidenceThreshold;

      print("   📊 YOLO Result:");
      print(
          "      Max Confidence: ${(maxConfidence * 100).toStringAsFixed(1)}%");
      print(
          "      Threshold: ${(confidenceThreshold * 100).toStringAsFixed(0)}%");
      print(
          "      Decision: ${isAppleLeaf ? 'APPLE LEAF ✅' : 'NOT APPLE LEAF ❌'}");

      return isAppleLeaf;
    } catch (e) {
      print("   ❌ YOLO parsing error: $e");
      return false; // Reject on error
    }
  }

  void dispose() {
    _yoloInterpreter?.close();
    _mobilenetInterpreter?.close();
    print("🔒 Models disposed");
  }
}
