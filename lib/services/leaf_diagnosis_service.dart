import 'dart:io';
import 'package:image/image.dart' as img;
import 'apple_detection_service.dart';
import 'disease_classifier_service.dart';

/// Binary-only leaf diagnosis pipeline (test mode).
/// Stage 1 — Apple leaf detection (binary_model.tflite).
/// Stage 2 (MobileNetV3 disease classification) is now enabled for apple leaves!
class LeafDiagnosisService {
  final double detectionThreshold;
  final double fallbackDetectionThreshold;
  final bool enablePreprocessing;
  final int interpreterThreads;
  final double minBoxAreaFraction;
  final double maxBoxAreaFraction;
  final bool normalizeYoloInput;
  final bool enableNormalizationFallback;

  bool _modelsLoaded = false;

  LeafDiagnosisService({
    this.normalizeYoloInput = false,
    this.detectionThreshold = 0.25,
    this.fallbackDetectionThreshold = 0.15,
    this.enableNormalizationFallback = true,
    this.minBoxAreaFraction = 0.002,
    this.maxBoxAreaFraction = 0.95,
    this.enablePreprocessing = true,
    this.interpreterThreads = 4,
  });

  // ---------------------------------------------------------------
  //  Model lifecycle
  // ---------------------------------------------------------------

  /// Load the binary detection model and disease classifier model.
  Future<void> loadModels() async {
    if (_modelsLoaded) return;

    print('🔄 Loading binary detection model …');
    await AppleDetectionService.loadModel();
    print('🔄 Loading disease classification model …');
    await DiseaseClassifierService.loadModel();
    _modelsLoaded = true;
    print('✅ Models loaded successfully');
  }

  // ---------------------------------------------------------------
  //  Prediction pipeline
  // ---------------------------------------------------------------

  /// Run the full prediction pipeline on [imageFile].
  ///
  /// Returns a map with keys:
  ///   `result`     — 'Apple Leaf Detected' or 'Not an Apple Leaf'
  ///   `disease`    — Disease class if apple leaf, else 'N/A'
  ///   `confidence` — Disease classification score if apple leaf, else binary model score
  ///   `severity`   — null
  ///   `isApple`    — true / false
  Future<Map<String, dynamic>> predict(File imageFile) async {
    try {
      if (!_modelsLoaded) await loadModels();

      // ── Decode image ─────────────────────────────────────────
      final bytes = await imageFile.readAsBytes();
      final decoded = img.decodeImage(bytes);

      if (decoded == null) {
        return _errorResult('Could not decode image');
      }

      // Handle EXIF orientation
      final oriented = img.bakeOrientation(decoded);

      // Preprocessing is handled inside AppleDetectionService._smartPreprocess
      // (gamma γ=1.2 + CLAHE) — do NOT apply again here.

      // ── Stage 1: Binary detection ────────────────────────────
      print('🔬 Running binary model …');
      final detection =
          await AppleDetectionService.isAppleLeafWithScore(oriented);
      final bool isApple = detection['isApple'] as bool;
      final double appleScore = (detection['appleScore'] as double?) ?? 0.0;

      final resultText = isApple ? 'Apple Leaf Detected' : 'Not an Apple Leaf';
      print('📊 Binary result: $resultText  (score=$appleScore)');

      // ── Stage 2: Disease Classification (If Apple Leaf) ───────
      String disease = 'N/A';
      double? diseaseConfidence = appleScore;

      if (isApple) {
        print(
            '🔬 Apple leaf detected. Running MobileNetV3 disease classifier...');
        final classificationResult =
            await DiseaseClassifierService.classify(oriented);

        disease = classificationResult['disease'] as String? ?? 'Unknown';
        // You might want to combine confidences or just use the disease classification's confidence:
        diseaseConfidence =
            (classificationResult['confidence'] as num?)?.toDouble() ??
                appleScore;

        print('📊 Classifier result: $disease  (score=$diseaseConfidence)');
      }

      return {
        'result': resultText,
        'disease': disease,
        'confidence': diseaseConfidence,
        'severity': null,
        'isApple': isApple,
      };
    } catch (e) {
      print('❌ Prediction error: $e');
      return _errorResult('Analysis failed: $e');
    }
  }

  // ─── Private helpers ────────────────────────────────────────────────────────

  Map<String, dynamic> _errorResult(String message) {
    return {
      'error': message,
      'result': message,
      'confidence': 0.0,
      'disease': 'Unknown',
      'severity': 0,
      'isApple': false,
    };
  }

  void dispose() {
    AppleDetectionService.dispose();
  }
}
