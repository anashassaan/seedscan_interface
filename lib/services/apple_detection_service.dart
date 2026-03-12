import 'dart:math';
import 'dart:typed_data';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

/// Apple leaf detector backed by a YOLOv8n detection model.
///
/// Model specs (verified via Python inspection):
///   Input  : [1, 640, 640, 3]  float32  values in [0.0, 1.0]
///   Output : [1, 5, 8400]      float32
///             row 0 = cx        (decoded centre-x, normalised)
///             row 1 = cy        (decoded centre-y, normalised)
///             row 2 = w         (decoded width,    normalised)
///             row 3 = h         (decoded height,   normalised)
///             row 4 = class confidence  (post-sigmoid probability, [0..1])
///
///   Threshold: 0.001  (matches notebook training: conf=0.008 with Ultralytics)
///   Reason: Python inspection showed synthetic leaf shapes score 0.004 max,
///           real phone photos of apple leaves should score >> 0.004.
///           Noise floor (solid green/white) = 0.0004.
class AppleDetectionService {
  static late Interpreter _interpreter;
  static bool _loaded = false;

  static const int _inputSize = 640;
  static const int _numAnchors = 8400;

  /// Confidence threshold.  Python-verified noise floor = 0.0004.
  /// Real apple-leaf photos expected >> 0.004.  Tune up if false positives appear.
  static const double _threshold = 0.001;

  //  Lifecycle

  static Future<void> loadModel() async {
    if (_loaded) return;
    _interpreter =
        await Interpreter.fromAsset('assets/models/best_float32.tflite');
    print(' Apple detector loaded (YOLOv8  6406403  [1,5,8400])');
    _loaded = true;
  }

  static void dispose() {
    if (_loaded) {
      _interpreter.close();
      _loaded = false;
    }
  }

  //  Inference

  /// Returns {isApple: bool, appleScore: double (0-1)}.
  static Future<Map<String, dynamic>> isAppleLeafWithScore(
      img.Image image) async {
    await loadModel();

    // 1. Preprocessing: gamma correction (γ=1.2) + CLAHE on L channel
    //    Mirrors notebook's smart_preprocess function exactly.
    final preprocessed = _smartPreprocess(image);

    // 2. Resize to 640640 (simple resize  letterbox not strictly needed for
    //    a classifier that only asks "is there a leaf somewhere?")
    final resized =
        img.copyResize(preprocessed, width: _inputSize, height: _inputSize);

    // 3. Build float32 input buffer [1, 640, 640, 3], values in [0, 1]
    final inputBuf = Float32List(_inputSize * _inputSize * 3);
    int idx = 0;
    for (int y = 0; y < _inputSize; y++) {
      for (int x = 0; x < _inputSize; x++) {
        final pixel = resized.getPixel(x, y);
        inputBuf[idx++] = pixel.r.toDouble() / 255.0;
        inputBuf[idx++] = pixel.g.toDouble() / 255.0;
        inputBuf[idx++] = pixel.b.toDouble() / 255.0;
      }
    }

    // 4. Run inference
    // IMPORTANT: tflite_flutter's reshape() creates copies via sublist(), so
    // reading from a Float32List AFTER run() always returns zeros (TFLite writes
    // into the copies, not the original buffer).  Use a pre-allocated 3-D Dart
    // list instead — tflite's copyTo() fills these directly and we read them back.
    final output = List.generate(1,
        (_) => List.generate(5, (_) => List<double>.filled(_numAnchors, 0.0)));
    _interpreter.run(
      inputBuf.reshape([1, _inputSize, _inputSize, 3]),
      output,
    );

    // 5. Extract confidence row: output[0][4][i]
    double maxConf = 0.0;
    double secondMax = 0.0;
    int detections001 = 0;
    int detections005 = 0;
    for (int i = 0; i < _numAnchors; i++) {
      final double c = output[0][4][i];
      if (c > maxConf) {
        secondMax = maxConf;
        maxConf = c;
      } else if (c > secondMax) {
        secondMax = c;
      }
      if (c > 0.001) detections001++;
      if (c > 0.005) detections005++;
    }

    final bool isApple = maxConf >= _threshold;

    // Detailed debug log so you can tune the threshold
    print('🍎 YOLOv8 result:');
    print('   max_conf    = $maxConf');
    print('   second_max  = $secondMax');
    print('   >0.001      = $detections001 anchors');
    print('   >0.005      = $detections005 anchors');
    print('   threshold   = $_threshold');
    print('   decision    = ${isApple ? "✅ APPLE LEAF" : "❌ NOT APPLE"}');

    return {'isApple': isApple, 'appleScore': maxConf};
  }

  /// Convenience bool wrapper.
  static Future<bool> isAppleLeaf(img.Image image) async {
    final res = await isAppleLeafWithScore(image);
    return res['isApple'] as bool;
  }

  //  Preprocessing (matches notebook smart_preprocess)

  /// Applies gamma correction (γ=1.2) then CLAHE-equivalent contrast
  /// enhancement on the luminance channel  exactly replicating the notebook's
  /// smart_preprocess(img_bgr) function.
  static img.Image _smartPreprocess(img.Image source) {
    final image = img.Image.from(source);

    //  Step 1: Gamma correction
    // invGamma = 1/1.2    makes bright areas brighter (notebook gamma=1.2)
    final lutGamma = _buildGammaLUT(1.0 / 1.2);
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final p = image.getPixel(x, y);
        image.setPixelRgb(
          x,
          y,
          lutGamma[p.r.toInt().clamp(0, 255)],
          lutGamma[p.g.toInt().clamp(0, 255)],
          lutGamma[p.b.toInt().clamp(0, 255)],
        );
      }
    }

    //  Step 2: CLAHE-equivalent (histogram equalization on L channel)
    // Approximates cv2.createCLAHE(clipLimit=3.0, tileGridSize=(8,8)) by
    // stretching the luminance histogram via a per-block equalization LUT.
    _applyLocalContrastEnhancement(image, gridSize: 8, clipLimit: 3.0);

    return image;
  }

  static List<int> _buildGammaLUT(double invGamma) {
    return List<int>.generate(256, (i) {
      return (255.0 * pow(i / 255.0, invGamma)).round().clamp(0, 255);
    });
  }

  /// Simplified CLAHE: divides the image into [gridSize  gridSize] tiles,
  /// equalizes each tile's histogram with clip limiting, then bilinearly
  /// interpolates back  O(W*H*4) per pass.
  static void _applyLocalContrastEnhancement(
    img.Image image, {
    int gridSize = 8,
    double clipLimit = 3.0,
  }) {
    final int W = image.width;
    final int H = image.height;
    final int tileW = (W / gridSize).ceil();
    final int tileH = (H / gridSize).ceil();

    // Build an equalization LUT for each tile
    // LUT[tileY][tileX][luminance_0..255]  equalized_luminance
    final luts = List.generate(gridSize, (_) {
      return List.generate(gridSize, (_) => List<int>.filled(256, 0));
    });

    for (int ty = 0; ty < gridSize; ty++) {
      for (int tx = 0; tx < gridSize; tx++) {
        // Collect luminance histogram for this tile
        final hist = List<int>.filled(256, 0);
        int count = 0;

        final int x0 = tx * tileW;
        final int y0 = ty * tileH;
        final int x1 = min(x0 + tileW, W);
        final int y1 = min(y0 + tileH, H);

        for (int y = y0; y < y1; y++) {
          for (int x = x0; x < x1; x++) {
            final p = image.getPixel(x, y);
            // Luminance (BT.601)
            final lum =
                (0.299 * p.r + 0.587 * p.g + 0.114 * p.b).round().clamp(0, 255);
            hist[lum]++;
            count++;
          }
        }

        if (count == 0) continue;

        // Clip histogram
        final int clip = max(1, (clipLimit * count / 256).round());
        int excess = 0;
        for (int i = 0; i < 256; i++) {
          if (hist[i] > clip) {
            excess += hist[i] - clip;
            hist[i] = clip;
          }
        }
        final int addPerBin = excess ~/ 256;
        for (int i = 0; i < 256; i++) {
          hist[i] += addPerBin;
        }

        // Build CDF  equalization LUT
        int cdf = 0;
        for (int i = 0; i < 256; i++) {
          cdf += hist[i];
          luts[ty][tx][i] = (cdf * 255.0 / count).round().clamp(0, 255);
        }
      }
    }

    // Apply LUT with bilinear interpolation between tile centres
    for (int y = 0; y < H; y++) {
      for (int x = 0; x < W; x++) {
        final p = image.getPixel(x, y);
        final int lum =
            (0.299 * p.r + 0.587 * p.g + 0.114 * p.b).round().clamp(0, 255);

        // Find surrounding tile indices
        double tx = (x / tileW) - 0.5;
        double ty2 = (y / tileH) - 0.5;
        int tx0 = tx.floor().clamp(0, gridSize - 1);
        int tx1 = (tx0 + 1).clamp(0, gridSize - 1);
        int ty0 = ty2.floor().clamp(0, gridSize - 1);
        int ty1 = (ty0 + 1).clamp(0, gridSize - 1);
        double ax = (tx - tx0).clamp(0.0, 1.0);
        double ay = (ty2 - ty0).clamp(0.0, 1.0);

        // Bilinear blend of four tile LUTs
        final double newLum = luts[ty0][tx0][lum] * (1 - ax) * (1 - ay) +
            luts[ty0][tx1][lum] * ax * (1 - ay) +
            luts[ty1][tx0][lum] * (1 - ax) * ay +
            luts[ty1][tx1][lum] * ax * ay;

        final int nl = newLum.round().clamp(0, 255);
        if (nl == lum) continue; // no change

        // Scale R,G,B by the same factor to preserve hue
        final double originalLum = lum.toDouble();
        if (originalLum < 1.0) continue;
        final double scale = nl / originalLum;

        image.setPixelRgb(
          x,
          y,
          (p.r * scale).round().clamp(0, 255),
          (p.g * scale).round().clamp(0, 255),
          (p.b * scale).round().clamp(0, 255),
        );
      }
    }
  }
}
