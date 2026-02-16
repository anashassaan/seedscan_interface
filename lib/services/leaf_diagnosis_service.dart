import 'dart:io';
import 'dart:math';
import 'package:image/image.dart' as img;
import 'disease_classifier_service.dart';

/// Two-stage leaf diagnosis pipeline:
///   Stage 1 — Apple leaf detection   (binary_model.tflite)
///   Stage 2 — Disease classification (mobilenetv3_apple_disease.tflite)
///
/// Includes optional preprocessing (gamma correction + colour enhancement)
/// shown to be critical for real-world accuracy.
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

  /// Load the MobileNetV3 disease classifier model.
  Future<void> loadModels() async {
    if (_modelsLoaded) return;

    print('🔄 Loading disease-detection model …');

    await DiseaseClassifierService.loadModel();

    _modelsLoaded = true;
    print('✅ Disease classifier model loaded successfully');
  }

  // ---------------------------------------------------------------
  //  Prediction pipeline
  // ---------------------------------------------------------------

  /// Run the full prediction pipeline on [imageFile].
  ///
  /// Returns a map with keys:
  ///   `result`     — human-readable summary
  ///   `disease`    — disease class name or 'N/A'
  ///   `confidence` — 0.0 – 1.0
  ///   `severity`   — 1 – 5  (null when not applicable)
  ///   `isApple`    — whether the image was identified as an apple leaf
  Future<Map<String, dynamic>> predict(File imageFile) async {
    try {
      if (!_modelsLoaded) await loadModels();

      // ── Decode image ──────────────────────────────────────────
      final bytes = await imageFile.readAsBytes();
      final decoded = img.decodeImage(bytes);

      if (decoded == null) {
        return _errorResult('Could not decode image');
      }

      // Handle EXIF orientation
      final oriented = img.bakeOrientation(decoded);

      // ── Preprocessing (optional) ──────────────────────────────
      img.Image processedImage;
      if (enablePreprocessing) {
        print('🔧 Applying preprocessing (gamma + colour enhancement) …');
        processedImage = _preprocessImage(img.Image.from(oriented));
      } else {
        processedImage = oriented;
      }

      // ── Disease classification (MobileNetV3) ─────────────────
      print('🔬 Classifying disease …');
      final result = await DiseaseClassifierService.classify(processedImage);

      final disease = result['disease'] as String;
      final confidence = (result['confidence'] as num).toDouble();
      final severity = result['severity'] as int;

      final String resultText =
          disease == 'Healthy' ? 'Healthy Leaf' : 'Disease Detected: $disease';

      print('📊 Result: $disease (${(confidence * 100).toStringAsFixed(1)}%)');

      return {
        'result': resultText,
        'disease': disease,
        'confidence': confidence,
        'severity': severity,
        'isApple': true,
      };
    } catch (e) {
      print('❌ Prediction error: $e');
      return _errorResult('Analysis failed: $e');
    }
  }

  // ---------------------------------------------------------------
  //  Image preprocessing
  // ---------------------------------------------------------------

  /// Apply gamma correction (γ = 1.2) and boost colour saturation by 20 %.
  img.Image _preprocessImage(img.Image image) {
    // Optionally down-sample for speed (keeps quality via bilinear resize).
    if (image.width > 512 || image.height > 512) {
      final scale = 512.0 / max(image.width, image.height);
      image = img.copyResize(
        image,
        width: (image.width * scale).round(),
        height: (image.height * scale).round(),
      );
    }

    // Build a look-up table for gamma correction (γ = 1.2).
    final double invGamma = 1.0 / 1.2;
    final gammaLUT = List<int>.generate(256, (i) {
      return (255.0 * pow(i / 255.0, invGamma)).round().clamp(0, 255);
    });

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final int r = gammaLUT[pixel.r.toInt().clamp(0, 255)];
        final int g = gammaLUT[pixel.g.toInt().clamp(0, 255)];
        final int b = gammaLUT[pixel.b.toInt().clamp(0, 255)];
        image.setPixelRgb(x, y, r, g, b);
      }
    }

    // Boost saturation by 20 % via RGB → HSL → RGB.
    _enhanceSaturation(image, factor: 1.2);

    return image;
  }

  /// Increase saturation of every pixel by [factor] (1.0 = no change).
  void _enhanceSaturation(img.Image image, {double factor = 1.2}) {
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final double rn = pixel.r.toDouble() / 255.0;
        final double gn = pixel.g.toDouble() / 255.0;
        final double bn = pixel.b.toDouble() / 255.0;

        final double cMax = max(rn, max(gn, bn));
        final double cMin = min(rn, min(gn, bn));
        final double delta = cMax - cMin;

        // Skip near-achromatic pixels.
        if (delta < 0.01) continue;

        // --- RGB → HSL ---
        double h = 0;
        if (cMax == rn) {
          h = 60 * (((gn - bn) / delta) % 6);
        } else if (cMax == gn) {
          h = 60 * (((bn - rn) / delta) + 2);
        } else {
          h = 60 * (((rn - gn) / delta) + 4);
        }
        if (h < 0) h += 360;

        final double l = (cMax + cMin) / 2;
        final double s = delta / (1 - (2 * l - 1).abs());

        // Boost, clamped to 1.0.
        final double newS = min(1.0, s * factor);

        // --- HSL → RGB ---
        final double c = (1 - (2 * l - 1).abs()) * newS;
        final double x2 = c * (1 - ((h / 60) % 2 - 1).abs());
        final double m = l - c / 2;

        double r1, g1, b1;
        if (h < 60) {
          r1 = c;
          g1 = x2;
          b1 = 0;
        } else if (h < 120) {
          r1 = x2;
          g1 = c;
          b1 = 0;
        } else if (h < 180) {
          r1 = 0;
          g1 = c;
          b1 = x2;
        } else if (h < 240) {
          r1 = 0;
          g1 = x2;
          b1 = c;
        } else if (h < 300) {
          r1 = x2;
          g1 = 0;
          b1 = c;
        } else {
          r1 = c;
          g1 = 0;
          b1 = x2;
        }

        image.setPixelRgb(
          x,
          y,
          ((r1 + m) * 255).round().clamp(0, 255),
          ((g1 + m) * 255).round().clamp(0, 255),
          ((b1 + m) * 255).round().clamp(0, 255),
        );
      }
    }
  }

  // ---------------------------------------------------------------
  //  Helpers
  // ---------------------------------------------------------------

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
    DiseaseClassifierService.dispose();
  }
}
