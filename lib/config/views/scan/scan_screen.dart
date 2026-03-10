// // lib/config/views/scan/scan_screen.dart
// import 'package:flutter/material.dart';
// import 'package:mobile_scanner/mobile_scanner.dart';
// import 'package:provider/provider.dart';
// import '../../controllers/scan_controller.dart';

// class ScanScreen extends StatefulWidget {
//   const ScanScreen({super.key});

//   @override
//   State<ScanScreen> createState() => _ScanScreenState();
// }

// class _ScanScreenState extends State<ScanScreen>
//     with SingleTickerProviderStateMixin {
//   late final AnimationController _laserCtrl =
//       AnimationController(vsync: this, duration: const Duration(seconds: 2))
//         ..repeat(reverse: true);
//   @override
//   void dispose() {
//     _laserCtrl.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final scan = Provider.of<ScanController>(context);
//     final cs = Theme.of(context).colorScheme;

//     return Scaffold(
//       extendBodyBehindAppBar: true,
//       appBar: AppBar(
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         leading: BackButton(color: cs.onBackground),
//         actions: [
//           IconButton(
//             onPressed: () => scan.toggleTorch(),
//             icon: Icon(scan.isTorchOn ? Icons.flash_on : Icons.flash_off,
//                 color: cs.onBackground),
//           ),
//           IconButton(
//             onPressed: () => scan.switchCamera(),
//             icon: Icon(Icons.cameraswitch_rounded, color: cs.onBackground),
//           ),
//           const SizedBox(width: 8),
//         ],
//       ),
//       body: Stack(
//         children: [
//           // Camera preview (fills the screen)
//           Positioned.fill(
//             child: Builder(builder: (_) {
//               // MobileScanner may throw on web — guard with kIsWeb in your app-level code.
//               return MobileScanner(
//                 controller: scan.cameraController,
//                 fit: BoxFit.cover,
//                 onDetect: (capture) {
//                   if (!scan.isQrMode) return; // only process in QR mode
//                   for (final barcode in capture.barcodes) {
//                     final String? raw = barcode.rawValue;
//                     if (raw != null && raw.isNotEmpty) {
//                       scan.handleQr(raw);
//                     }
//                   }
//                 },
//               );
//             }),
//           ),

//           // Dark overlay with transparent cutout
//           Positioned.fill(child: _OverlayCutout(cornerRadius: 20)),

//           // Laser animation inside the cutout
//           Center(
//             child: SizedBox(
//               width: 300,
//               height: 300,
//               child: ClipRRect(
//                 borderRadius: BorderRadius.circular(20),
//                 child: Stack(
//                   children: [
//                     // laser
//                     AnimatedBuilder(
//                       animation: _laserCtrl,
//                       builder: (context, child) {
//                         return Align(
//                           alignment: Alignment(0, (_laserCtrl.value * 2) - 1),
//                           child: Container(
//                             width: double.infinity,
//                             height: 2.4,
//                             decoration: BoxDecoration(
//                               gradient: LinearGradient(
//                                 colors: [
//                                   cs.primary.withOpacity(0.0),
//                                   cs.primary.withOpacity(0.95),
//                                   cs.primary.withOpacity(0.0),
//                                 ],
//                               ),
//                             ),
//                           ),
//                         );
//                       },
//                     ),
//                     // border for the cutout
//                     Positioned.fill(
//                       child: Container(
//                         decoration: BoxDecoration(
//                           borderRadius: BorderRadius.circular(20),
//                           border: Border.all(
//                               color: cs.onBackground.withOpacity(0.18),
//                               width: 2),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),

//           // Top status/result pill
//           Positioned(
//             top: 100,
//             left: 0,
//             right: 0,
//             child: Center(child: _StatusPill(scan: scan)),
//           ),

//           // Capture / Analyze button (visible in Disease mode)
//           if (!scan.isQrMode)
//             Positioned(
//               bottom: 36,
//               left: 0,
//               right: 0,
//               child: Center(
//                 child: ElevatedButton.icon(
//                   onPressed: scan.isProcessing
//                       ? null
//                       : () => _onCapture(context, scan),
//                   icon: const Icon(Icons.camera_alt_outlined),
//                   label: Text(
//                       scan.isProcessing ? 'Analyzing...' : 'Capture & Analyze'),
//                   style: ElevatedButton.styleFrom(
//                     padding: const EdgeInsets.symmetric(
//                         horizontal: 20, vertical: 14),
//                     shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(16)),
//                   ),
//                 ),
//               ),
//             ),

//           // Floating mode switch (QR <-> Disease)
//           Positioned(
//             bottom: 16,
//             right: 16,
//             child: FloatingActionButton.extended(
//               onPressed: () => scan.toggleMode(),
//               label: Text(scan.isQrMode ? 'QR Mode' : 'Disease Mode'),
//               icon: Icon(scan.isQrMode ? Icons.qr_code : Icons.bug_report),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   void _onCapture(BuildContext context, ScanController scan) async {
//     // Simulate capture flow: show bottom sheet "Analyzing..." then show result
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: false,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       builder: (context) => Padding(
//         padding: const EdgeInsets.all(18.0),
//         child: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: const [
//             CircularProgressIndicator(),
//             SizedBox(width: 12),
//             Text('Analyzing…'),
//           ],
//         ),
//       ),
//     );

//     // simulate model analysis
//     await scan.analyzeImageForDisease(imageBytes: null);

//     // close the progress sheet
//     if (mounted) Navigator.of(context).pop();

//     // show result sheet
//     if (mounted) {
//       showModalBottomSheet(
//         context: context,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         builder: (context) {
//           return Padding(
//             padding: const EdgeInsets.all(18.0),
//             child: Column(mainAxisSize: MainAxisSize.min, children: [
//               Text('Analysis Result',
//                   style: Theme.of(context).textTheme.titleLarge),
//               const SizedBox(height: 12),
//               Text('${scan.lastDetectionLabel ?? 'No issue detected'}',
//                   style: Theme.of(context).textTheme.bodyLarge),
//               const SizedBox(height: 8),
//               if (scan.lastDetectionConfidence != null)
//                 Text(
//                     'Confidence: ${(scan.lastDetectionConfidence! * 100).toStringAsFixed(0)}%'),
//               const SizedBox(height: 16),
//               ElevatedButton(
//                 onPressed: () => Navigator.of(context).pop(),
//                 child: const Text('Close'),
//               ),
//             ]),
//           );
//         },
//       );
//     }
//   }
// }

// /// Widget that paints a dark overlay with a transparent square cutout in the center
// class _OverlayCutout extends StatelessWidget {
//   final double cornerRadius;
//   const _OverlayCutout({this.cornerRadius = 20});

//   @override
//   Widget build(BuildContext context) {
//     return IgnorePointer(
//       child: LayoutBuilder(builder: (context, constraints) {
//         final w = constraints.maxWidth;
//         final h = constraints.maxHeight;
//         final cutoutSize = (w < h ? w : h) * 0.6; // square
//         final left = (w - cutoutSize) / 2;
//         final top = (h - cutoutSize) / 2;

//         return Stack(children: [
//           // full dark overlay
//           Container(color: Colors.black.withOpacity(0.45)),
//           // clear rectangle by using a hole with BlendMode.dstOut via a CustomPaint
//           Positioned.fill(
//             child: CustomPaint(
//               painter: _CutoutPainter(
//                   Rect.fromLTWH(left, top, cutoutSize, cutoutSize),
//                   cornerRadius),
//             ),
//           ),
//         ]);
//       }),
//     );
//   }
// }

// class _CutoutPainter extends CustomPainter {
//   final Rect rect;
//   final double radius;
//   _CutoutPainter(this.rect, this.radius);

//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint()..color = Colors.black.withOpacity(0.45);
//     // draw full rect
//     canvas.drawRect(Offset.zero & size, paint);

//     // use clear blend mode to punch hole
//     final clearPaint = Paint()..blendMode = BlendMode.clear;
//     final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
//     canvas.drawRRect(rrect, clearPaint);
//   }

//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
// }

// /// Small status pill that shows last QR or scanning status
// class _StatusPill extends StatelessWidget {
//   final ScanController scan;
//   const _StatusPill({required this.scan});

//   @override
//   Widget build(BuildContext context) {
//     final cs = Theme.of(context).colorScheme;
//     final text = scan.isQrMode
//         ? (scan.lastQr != null ? 'Last QR: ${scan.lastQr}' : 'QR mode — ready')
//         : (scan.lastDetectionLabel != null
//             ? '${scan.lastDetectionLabel} ${(scan.lastDetectionConfidence != null ? '(${(scan.lastDetectionConfidence! * 100).toStringAsFixed(0)}%)' : '')}'
//             : 'Disease mode — ready');

//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
//       decoration: BoxDecoration(
//         color: cs.surface.withOpacity(0.85),
//         borderRadius: BorderRadius.circular(999),
//         boxShadow: [
//           BoxShadow(
//               color: Colors.black.withOpacity(0.06),
//               blurRadius: 8,
//               offset: const Offset(0, 4))
//         ],
//       ),
//       child: Row(mainAxisSize: MainAxisSize.min, children: [
//         Icon(scan.isQrMode ? Icons.qr_code : Icons.bug_report,
//             size: 16, color: cs.primary),
//         const SizedBox(width: 8),
//         Text(text, style: Theme.of(context).textTheme.bodySmall),
//       ]),
//     );
//   }
// }
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:geolocator/geolocator.dart';
import '../../controllers/scan_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/community_controller.dart';
import '../../../services/database_service.dart';
import '../../../models/community_model.dart';
import '../../../models/my_garden_qr_model.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
// Import the new unified diagnosis service
import '../../../services/leaf_diagnosis_service.dart';
// Import premium UI widgets
import 'widgets/result_header.dart';
import 'widgets/severity_indicator.dart';
import 'widgets/disease_card.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _laserCtrl =
      AnimationController(vsync: this, duration: const Duration(seconds: 2))
        ..repeat(reverse: true);

  // Local camera controller — created fresh each time this screen opens
  late final MobileScannerController _cameraController =
      MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  bool _hasScanned = false; // guard: only process one QR per session
  bool _isTorchOn = false;

  // Enhanced service with optimized parameters for reliable detection
  final diagnosisService = LeafDiagnosisService(
    detectionThreshold: 0.25, // Balanced threshold (25%)
    fallbackDetectionThreshold: 0.15, // Lower fallback for challenging images
    enablePreprocessing: true, // Gamma correction + color enhancement
    interpreterThreads: 4, // Multi-threading for faster inference
    minBoxAreaFraction: 0.002, // Allow smaller leaf detections
    maxBoxAreaFraction: 0.95, // Allow larger detections
  );

  // State variables for results
  String? classificationResult;
  String? diseaseName;
  int? severityLevel;
  double? confidenceLevel;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    diagnosisService.loadModels();
  }

  @override
  void dispose() {
    _laserCtrl.dispose();
    _cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scan = Provider.of<ScanController>(context);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: cs.onBackground),
        actions: [
          IconButton(
            onPressed: () async {
              try {
                await _cameraController.toggleTorch();
                setState(() => _isTorchOn = !_isTorchOn);
              } catch (_) {}
            },
            icon: Icon(_isTorchOn ? Icons.flash_on : Icons.flash_off,
                color: cs.onBackground),
          ),
          IconButton(
            onPressed: () async {
              try {
                await _cameraController.switchCamera();
              } catch (_) {}
            },
            icon: Icon(Icons.cameraswitch_rounded, color: cs.onBackground),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // Camera preview (fills the screen)
          Positioned.fill(
            child: Builder(builder: (_) {
              return MobileScanner(
                controller: _cameraController,
                fit: BoxFit.cover,
                onDetect: (capture) {
                  if (!scan.isQrMode) return; // only process in QR mode
                  if (_hasScanned) return; // only process once
                  for (final barcode in capture.barcodes) {
                    final String? raw = barcode.rawValue;
                    if (raw != null && raw.isNotEmpty) {
                      _hasScanned = true;
                      _cameraController.stop();
                      scan.handleQr(raw);
                      _showQRResult(context, raw, scan);
                      return;
                    }
                  }
                },
              );
            }),
          ),

          // Dark overlay with transparent cutout
          Positioned.fill(child: _OverlayCutout(cornerRadius: 20)),

          // Laser animation inside the cutout
          Center(
            child: SizedBox(
              width: 300,
              height: 300,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    // laser
                    AnimatedBuilder(
                      animation: _laserCtrl,
                      builder: (context, child) {
                        return Align(
                          alignment: Alignment(0, (_laserCtrl.value * 2) - 1),
                          child: Container(
                            width: double.infinity,
                            height: 2.4,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  cs.primary.withOpacity(0.0),
                                  cs.primary.withOpacity(0.95),
                                  cs.primary.withOpacity(0.0),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    // border for the cutout
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: cs.onBackground.withOpacity(0.18),
                              width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Top status/result pill
          Positioned(
            top: 100,
            left: 0,
            right: 0,
            child: Center(child: _StatusPill(scan: scan)),
          ),

          // Capture / Analyze button (visible in Disease mode)
          if (!scan.isQrMode)
            Positioned(
              bottom: 36,
              left: 0,
              right: 0,
              child: Center(
                child: ElevatedButton.icon(
                  onPressed: scan.isProcessing
                      ? null
                      : () => _onCapture(context, scan),
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: Text(
                      scan.isProcessing ? 'Analyzing...' : 'Capture & Analyze'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ),

          // Floating mode switch (QR <-> Disease)
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton.extended(
              onPressed: () => scan.toggleMode(),
              label: Text(scan.isQrMode ? 'QR Mode' : 'Disease Mode'),
              icon: Icon(scan.isQrMode ? Icons.qr_code : Icons.bug_report),
            ),
          ),
        ],
      ),
    );
  }

  /// Show QR scan result — detects My Garden and Community plant QR codes.
  void _showQRResult(BuildContext context, String qrData, ScanController scan) {
    // ── Community plant QR: SEEDSCAN|communityId|id|plantName|plantType|bestSeason|SEED/PLANT|plantAge|timestamp
    if (qrData.startsWith('SEEDSCAN|')) {
      final parts = qrData.split('|');
      if (parts.length >= 9) {
        _showCommunityQRDialog(context, parts);
        return;
      }
    }

    // ── My Garden QR (JSON)
    Map<String, dynamic>? parsed;
    try {
      parsed = jsonDecode(qrData) as Map<String, dynamic>;
    } catch (_) {
      parsed = null;
    }

    final isMyGardenQR = parsed != null &&
        parsed['source'] == 'my_garden' &&
        parsed['id'] != null;

    if (isMyGardenQR) {
      _showMyGardenQRDialog(context, parsed);
    } else {
      _showGenericQRDialog(context, qrData);
    }
  }

  /// Show dialog for a community plant QR code.
  void _showCommunityQRDialog(BuildContext context, List<String> parts) {
    final communityId = parts[1];
    final qrId = parts[2];
    final plantName = parts[3];
    final plantType = parts[4];
    final bestSeason = parts[5];
    final isSeed = parts[6] == 'SEED';
    final plantAge = parts[7] == 'N/A' ? null : parts[7];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return _ScanCommunityQRDialog(
          communityId: communityId,
          qrId: qrId,
          plantName: plantName,
          plantType: plantType,
          bestSeason: bestSeason,
          isSeed: isSeed,
          plantAge: plantAge,
          onDone: () {
            setState(() => _hasScanned = false);
            _cameraController.start();
          },
        );
      },
    );
  }

  void _showMyGardenQRDialog(
      BuildContext context, Map<String, dynamic> qrPayload) {
    final dbService = DatabaseService();
    final uniqueCode = qrPayload['id'] as String;
    final plantName = qrPayload['plantName'] ?? 'Unknown';
    final localName = qrPayload['localName'] ?? '';
    final category = qrPayload['category'] ?? '';
    final bestSeason = qrPayload['bestSeason'] ?? '';
    final qrType = qrPayload['qrType'] ?? 'Seed';
    final plantAge = qrPayload['plantAge'];
    final ownerName = qrPayload['owner'] ?? 'Unknown';
    final isPlant = qrType == 'Plant';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return _ScanMyGardenQRDialog(
          dbService: dbService,
          uniqueCode: uniqueCode,
          plantName: plantName,
          localName: localName,
          category: category,
          bestSeason: bestSeason,
          qrType: qrType,
          plantAge: plantAge,
          ownerName: ownerName,
          isPlant: isPlant,
          onDone: () {
            // Allow scanning again
            setState(() => _hasScanned = false);
            _cameraController.start();
          },
        );
      },
    );
  }

  void _showGenericQRDialog(BuildContext context, String qrData) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.qr_code_scanner,
                color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            const Text('QR Code Scanned',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
          ],
        ),
        content: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(qrData, style: const TextStyle(fontSize: 13)),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _hasScanned = false);
              _cameraController.start();
            },
            child: const Text('Scan Again'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _onCapture(BuildContext context, ScanController scan) async {
    setState(() {
      isLoading = true;
    });

    // Show analyzing dialog
    showModalBottomSheet(
      context: context,
      isScrollControlled: false,
      isDismissible: false,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(18.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            CircularProgressIndicator(),
            SizedBox(width: 12),
            Text('Analyzing…'),
          ],
        ),
      ),
    );

    // Get the image from the camera controller
    // Get the image from the camera controller
    final XFile? pickedFile =
        await ImagePicker().pickImage(source: ImageSource.camera);

    // Check if image was captured
    if (pickedFile == null) {
      if (mounted) {
        Navigator.of(context).pop(); // close the progress sheet
        setState(() {
          isLoading = false;
        });
      }
      return;
    }

    // Convert to File
    final imageFile = File(pickedFile.path);

    // Run prediction which handles both apple detection and disease classification
    final result = await diagnosisService.predict(imageFile);

    if (result.containsKey('error')) {
      setState(() {
        classificationResult = "Error: ${result['error']}";
        diseaseName = null;
        severityLevel = null;
        confidenceLevel = null;
        isLoading = false;
      });
      if (mounted) Navigator.of(context).pop();
    } else if (result['result'] == 'No Apple Leaf Detected') {
      setState(() {
        classificationResult = "Non-Apple Leaf";
        diseaseName = null;
        severityLevel = null;
        confidenceLevel = null;
        isLoading = false;
      });
      if (mounted) Navigator.of(context).pop();
    } else {
      setState(() {
        classificationResult = "Apple Leaf Detected";
        diseaseName = result["disease"];
        severityLevel = result["severity"];
        confidenceLevel = result["confidence"];
        isLoading = false;
      });
      if (mounted) Navigator.of(context).pop();
    }

    // Show premium result sheet
    if (mounted) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context) {
          return Container(
            padding: const EdgeInsets.all(24.0),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                ResultHeader(
                  title: classificationResult ?? "No Result",
                  subtitle: diseaseName != null ? "Detected Disease" : null,
                ),
                const SizedBox(height: 22),

                // Disease Card
                if (diseaseName != null && confidenceLevel != null)
                  DiseaseCard(
                    disease: diseaseName!,
                    confidence: confidenceLevel!,
                  ),

                const SizedBox(height: 22),

                // Severity Indicator
                if (severityLevel != null)
                  SeverityIndicator(severity: severityLevel!),

                const SizedBox(height: 24),

                // Close Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          );
        },
      );
    }
  }
}

/// Widget that paints a dark overlay with a transparent square cutout in the center
class _OverlayCutout extends StatelessWidget {
  final double cornerRadius;
  const _OverlayCutout({this.cornerRadius = 20});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final cutoutSize = (w < h ? w : h) * 0.6; // square
        final left = (w - cutoutSize) / 2;
        final top = (h - cutoutSize) / 2;

        return Stack(children: [
          // full dark overlay
          Container(color: Colors.black.withOpacity(0.45)),
          // clear rectangle by using a hole with BlendMode.dstOut via a CustomPaint
          Positioned.fill(
            child: CustomPaint(
              painter: _CutoutPainter(
                  Rect.fromLTWH(left, top, cutoutSize, cutoutSize),
                  cornerRadius),
            ),
          ),
        ]);
      }),
    );
  }
}

class _CutoutPainter extends CustomPainter {
  final Rect rect;
  final double radius;
  _CutoutPainter(this.rect, this.radius);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withOpacity(0.45);
    // draw full rect
    canvas.drawRect(Offset.zero & size, paint);

    // use clear blend mode to punch hole
    final clearPaint = Paint()..blendMode = BlendMode.clear;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    canvas.drawRRect(rrect, clearPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Small status pill that shows last QR or scanning status
class _StatusPill extends StatelessWidget {
  final ScanController scan;
  const _StatusPill({required this.scan});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // Access state from ancestor
    final state = context.findAncestorStateOfType<_ScanScreenState>();

    final text = scan.isQrMode
        ? (scan.lastQr != null ? 'Last QR: ${scan.lastQr}' : 'QR mode — ready')
        : (state?.classificationResult != null
            ? state!.classificationResult!
            : 'Disease mode — ready');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surface.withOpacity(0.85),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(scan.isQrMode ? Icons.qr_code : Icons.bug_report,
            size: 16, color: cs.primary),
        const SizedBox(width: 8),
        Text(text, style: Theme.of(context).textTheme.bodySmall),
      ]),
    );
  }
}

/// Stateful dialog for My Garden QR scan results with DB check + add-to-garden.
class _ScanMyGardenQRDialog extends StatefulWidget {
  final DatabaseService dbService;
  final String uniqueCode;
  final String plantName;
  final String localName;
  final String category;
  final String bestSeason;
  final String qrType;
  final String? plantAge;
  final String ownerName;
  final bool isPlant;
  final VoidCallback onDone;

  const _ScanMyGardenQRDialog({
    required this.dbService,
    required this.uniqueCode,
    required this.plantName,
    required this.localName,
    required this.category,
    required this.bestSeason,
    required this.qrType,
    required this.plantAge,
    required this.ownerName,
    required this.isPlant,
    required this.onDone,
  });

  @override
  State<_ScanMyGardenQRDialog> createState() => _ScanMyGardenQRDialogState();
}

class _ScanMyGardenQRDialogState extends State<_ScanMyGardenQRDialog> {
  bool _isChecking = true;
  bool _existsInDb = false;
  MyGardenQRModel? _foundQr;
  bool _isPlanting = false;
  bool _planted = false;
  String? _capturedImagePath;

  @override
  void initState() {
    super.initState();
    _checkDatabase();
  }

  Future<void> _checkDatabase() async {
    final found =
        await widget.dbService.findMyGardenQRByUniqueCode(widget.uniqueCode);

    if (mounted) {
      setState(() {
        _isChecking = false;
        _existsInDb = found != null;
        _foundQr = found;
      });
    }
  }

  Future<void> _plantNow() async {
    setState(() => _isPlanting = true);

    try {
      // 1. Capture photo of the plant
      final picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (photo == null) {
        if (mounted) setState(() => _isPlanting = false);
        return;
      }

      _capturedImagePath = photo.path;

      // 2. Get GPS location — force enable if location service is off
      double lat = 0.0;
      double lng = 0.0;
      try {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          // Prompt user to enable location services
          await Geolocator.openLocationSettings();
          await Future.delayed(const Duration(seconds: 3));
          serviceEnabled = await Geolocator.isLocationServiceEnabled();
        }
        if (serviceEnabled) {
          LocationPermission perm = await Geolocator.checkPermission();
          if (perm == LocationPermission.denied) {
            perm = await Geolocator.requestPermission();
          }
          if (perm == LocationPermission.deniedForever) {
            await Geolocator.openAppSettings();
            await Future.delayed(const Duration(seconds: 3));
            perm = await Geolocator.checkPermission();
          }
          if (perm == LocationPermission.always ||
              perm == LocationPermission.whileInUse) {
            final pos = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high,
            ).timeout(const Duration(seconds: 15));
            lat = pos.latitude;
            lng = pos.longitude;
          }
        }
      } catch (e) {
        debugPrint('GPS failed during planting: $e');
      }

      // 3. Upload plant image to Appwrite storage
      String? imageFileId;
      String? imageUrl;
      final now = DateTime.now();
      try {
        imageFileId = await widget.dbService.uploadPlantImage(photo.path);
        imageUrl = widget.dbService.getPlantImageUrl(imageFileId);
      } catch (e) {
        debugPrint('Image upload failed: $e');
      }

      // 4. Save to DB with location + image + planting timestamp
      final auth = Provider.of<AuthController>(context, listen: false);
      final gardenId = 'GARDEN-${auth.userHandle.toUpperCase()}';
      try {
        if (_foundQr != null) {
          if (_foundQr!.ownerId == auth.userId) {
            // It's their own plant. Just update the existing record with photo/location.
            await widget.dbService.updateMyGardenQRPlantingInfo(
              docId: _foundQr!.id,
              locationLat: lat,
              locationLong: lng,
              imageFileId: imageFileId,
              imageUrl: imageUrl,
              plantedAt: now,
            );
          } else {
            // It's someone else's plant. Clone it to "My Garden".
            await widget.dbService.addScannedQRToMyGarden(
              originalQr: _foundQr!,
              newOwnerId: auth.userId ?? '',
              newOwnerName: auth.userName,
              newOwnerEmail: auth.userEmail ?? '',
              newGardenId: gardenId,
              locationLat: lat,
              locationLong: lng,
              imageFileId: imageFileId,
              imageUrl: imageUrl,
              plantedAt: now,
            );
          }
        } else {
          await widget.dbService.createMyGardenQR(
            uniqueCode: widget.uniqueCode,
            plantName: widget.plantName,
            localName: widget.localName,
            category: widget.category,
            bestSeason: widget.bestSeason,
            qrType: widget.qrType,
            plantAge: widget.plantAge,
            notes: 'Planted via QR scan from ${widget.ownerName}',
            ownerId: auth.userId ?? '',
            ownerName: auth.userName,
            ownerEmail: auth.userEmail ?? '',
            gardenId: gardenId,
            locationLat: lat,
            locationLong: lng,
            imageFileId: imageFileId,
            imageUrl: imageUrl,
            plantedAt: now,
          );
        }
      } catch (_) {}

      // 5. Also create an entry in the plants collection for full tracking
      try {
        await widget.dbService.createPlant(
          species: widget.plantName,
          guardianId: auth.userId ?? '',
          lat: lat,
          lng: lng,
          imageUrl: imageUrl ?? photo.path,
          nickname: widget.localName.isNotEmpty ? widget.localName : null,
          plantId: widget.uniqueCode,
        );
      } catch (_) {}

      // 6. Add plant to My Garden plants list (in-memory)
      final scanCtrl = Provider.of<ScanController>(context, listen: false);
      final timeLabel =
          '${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute.toString().padLeft(2, '0')}';

      final newPlant = PlantModel(
        id: widget.uniqueCode,
        name: widget.plantName,
        scientificName:
            widget.localName.isNotEmpty ? widget.localName : widget.category,
        image: imageUrl ?? photo.path,
        status: 'Healthy',
        statusColor: Colors.green,
        lastScan: timeLabel,
        location: lat != 0.0
            ? 'GPS: ${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}'
            : 'Location not available',
        latitude: lat,
        longitude: lng,
      );

      scanCtrl.addPlantToGarden(newPlant);

      if (mounted) {
        setState(() {
          _isPlanting = false;
          _planted = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isPlanting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(LucideIcons.scanLine,
                size: 20, color: Colors.green.shade800),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text('My Garden QR',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700, fontSize: 17)),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // MY GARDEN badge
            Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green.shade400),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.home,
                        size: 14, color: Colors.green.shade800),
                    const SizedBox(width: 6),
                    Text('MY GARDEN',
                        style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.green.shade800,
                            letterSpacing: 1)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            Text(widget.plantName,
                style: GoogleFonts.poppins(
                    fontSize: 20, fontWeight: FontWeight.bold)),
            if (widget.localName.isNotEmpty)
              Text(widget.localName,
                  style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: cs.onSurface.withOpacity(0.6))),
            const SizedBox(height: 12),

            // Type & Category
            Row(children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.isPlant
                      ? Colors.teal.withOpacity(0.1)
                      : Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(widget.qrType,
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: widget.isPlant
                            ? Colors.teal
                            : Colors.amber.shade700)),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(widget.category,
                    style: GoogleFonts.poppins(
                        fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ]),
            const SizedBox(height: 12),

            // Info rows
            _info(LucideIcons.sun, 'Season', widget.bestSeason),
            if (widget.isPlant && widget.plantAge != null)
              _info(LucideIcons.clock, 'Age', widget.plantAge!),
            _info(LucideIcons.user, 'Owner', widget.ownerName),

            const Divider(height: 24),

            // DB Status
            if (_isChecking)
              const Row(children: [
                SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2)),
                SizedBox(width: 12),
                Text('Checking database...'),
              ])
            else if (_planted)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade300),
                ),
                child: Column(
                  children: [
                    Row(children: [
                      Icon(LucideIcons.checkCircle,
                          size: 20, color: Colors.green.shade700),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text('Plant added to your garden!',
                            style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.green.shade800)),
                      ),
                    ]),
                    if (_capturedImagePath != null) ...[
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(_capturedImagePath!),
                          height: 100,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                  ],
                ),
              )
            else if (_existsInDb)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade300),
                ),
                child: Row(children: [
                  Icon(LucideIcons.checkCircle,
                      size: 20, color: Colors.green.shade700),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('Plant found in database! Ready to plant.',
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: Colors.green.shade800)),
                  ),
                ]),
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade300),
                ),
                child: Row(children: [
                  Icon(LucideIcons.alertCircle,
                      size: 20, color: Colors.orange.shade700),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('QR code not found in database.',
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: Colors.orange.shade800)),
                  ),
                ]),
              ),
          ],
        ),
      ),
      actions: [
        if (!_isChecking && _existsInDb && !_planted)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isPlanting ? null : _plantNow,
              icon: _isPlanting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(LucideIcons.sprout),
              label: Text(_isPlanting ? 'Planting...' : '🌱 Plant Now?',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            widget.onDone();
          },
          child: Text(_planted ? 'Done' : 'Close',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _info(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        Icon(icon, size: 15, color: Colors.grey),
        const SizedBox(width: 8),
        Text('$label: ',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        Expanded(
            child: Text(value,
                style: const TextStyle(fontSize: 13),
                overflow: TextOverflow.ellipsis)),
      ]),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// Community Plant QR Dialog — handles admin-generated SEEDSCAN| QR codes.
/// Auto-joins the user to the community when they plant the QR plant.
/// ═══════════════════════════════════════════════════════════════════════════
class _ScanCommunityQRDialog extends StatefulWidget {
  final String communityId;
  final String qrId;
  final String plantName;
  final String plantType;
  final String bestSeason;
  final bool isSeed;
  final String? plantAge;
  final VoidCallback onDone;

  const _ScanCommunityQRDialog({
    required this.communityId,
    required this.qrId,
    required this.plantName,
    required this.plantType,
    required this.bestSeason,
    required this.isSeed,
    this.plantAge,
    required this.onDone,
  });

  @override
  State<_ScanCommunityQRDialog> createState() => _ScanCommunityQRDialogState();
}

class _ScanCommunityQRDialogState extends State<_ScanCommunityQRDialog> {
  final DatabaseService _db = DatabaseService();

  bool _isLoading = true;
  String _communityName = '';
  bool _alreadyMember = false;
  bool _isPlanting = false;
  bool _planted = false;
  String? _joinMessage;

  @override
  void initState() {
    super.initState();
    _loadCommunityInfo();
  }

  Future<void> _loadCommunityInfo() async {
    final auth = Provider.of<AuthController>(context, listen: false);
    final userId = auth.userId ?? '';

    try {
      final community = await _db.getCommunity(widget.communityId);
      final name = community?.name ?? widget.communityId;

      bool isMember = false;
      if (userId.isNotEmpty) {
        isMember = await _db.isUserInCommunity(widget.communityId, userId);
      }

      if (mounted) {
        setState(() {
          _communityName = name;
          _alreadyMember = isMember;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Failed to load community info: $e');
      if (mounted) {
        setState(() {
          _communityName = widget.communityId;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _plantAndJoin() async {
    setState(() => _isPlanting = true);

    try {
      // 1. Take a photo of the plant
      final picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (photo == null) {
        if (mounted) setState(() => _isPlanting = false);
        return;
      }

      // 2. Get GPS location
      double lat = 0.0;
      double lng = 0.0;
      try {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          await Geolocator.openLocationSettings();
          await Future.delayed(const Duration(seconds: 3));
          serviceEnabled = await Geolocator.isLocationServiceEnabled();
        }
        if (serviceEnabled) {
          LocationPermission perm = await Geolocator.checkPermission();
          if (perm == LocationPermission.denied) {
            perm = await Geolocator.requestPermission();
          }
          if (perm == LocationPermission.always ||
              perm == LocationPermission.whileInUse) {
            final pos = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high,
            ).timeout(const Duration(seconds: 15));
            lat = pos.latitude;
            lng = pos.longitude;
          }
        }
      } catch (e) {
        debugPrint('GPS failed: $e');
      }

      // 3. Upload plant image
      String? imageUrl;
      String? uploadedFileId;
      try {
        uploadedFileId = await _db.uploadPlantImage(photo.path);
        imageUrl = _db.getPlantImageUrl(uploadedFileId);
      } catch (e) {
        debugPrint('Image upload failed: $e');
      }

      // 4. Create plant record in Appwrite (auto-generated ID to avoid collisions)
      final auth = Provider.of<AuthController>(context, listen: false);
      final userId = auth.userId ?? '';
      String createdPlantId = widget.qrId; // fallback
      try {
        final createdPlant = await _db.createPlant(
          species: widget.plantName,
          guardianId: userId,
          lat: lat,
          lng: lng,
          imageUrl: imageUrl ?? photo.path,
          nickname: widget.plantType,
          driveId: widget.communityId, // link plant to community
        );
        createdPlantId = createdPlant.id;

        // Keep community plant count in sync
        try {
          await _db.incrementCommunityPlantCount(widget.communityId);
        } catch (e) {
          debugPrint('Increment community plant count failed: $e');
        }
      } catch (e) {
        debugPrint('Plant creation failed: $e');
      }

      // 5. Create activity log — use the plant's Appwrite $id so admin history works
      try {
        await _db.createActivityLog(
          userId: userId,
          plantId: createdPlantId,
          actionType: 'register',
          coinsAwarded: 10,
          verificationStatus: 'verified',
          proofImageId: uploadedFileId ?? '',
        );
      } catch (e) {
        debugPrint('Activity log failed: $e');
      }

      // 6. Auto-join community if not already a member
      String joinMsg = '';
      if (userId.isNotEmpty) {
        try {
          final newlyJoined = await _db.safeJoinCommunity(
            communityId: widget.communityId,
            userId: userId,
            role: 'member',
          );
          if (newlyJoined) {
            joinMsg = 'You have been added to $_communityName!';
            _alreadyMember = true;
          } else {
            joinMsg = 'Plant registered in $_communityName.';
          }
        } catch (e) {
          debugPrint('Auto-join failed: $e');
          joinMsg = 'Planted successfully, but could not join community.';
        }
      }

      // 7. Add community to the Community tab and reload memberships
      final communityCtrl =
          Provider.of<CommunityController>(context, listen: false);
      try {
        final freshCommunity = await _db.getCommunity(widget.communityId);
        if (freshCommunity != null) {
          communityCtrl.addCommunityLocally(freshCommunity);
        }
      } catch (_) {}

      // Reload memberships from DB so community persists after restart
      if (userId.isNotEmpty) {
        try {
          await communityCtrl.loadUserCommunities(userId);
        } catch (e) {
          debugPrint('loadUserCommunities failed after join: $e');
        }
      }

      // Add plant to community in-memory list
      communityCtrl.addPlantToCommunity(CommunityPlant(
        id: widget.qrId,
        communityId: widget.communityId,
        plantName: widget.plantName,
        scientificName: widget.plantType,
        plantedBy: userId,
        plantedByUsername: auth.userName,
        location: lat != 0.0
            ? 'GPS: ${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}'
            : 'Location not available',
        latitude: lat,
        longitude: lng,
        imageUrl: imageUrl ?? photo.path,
        plantedDate: DateTime.now(),
        status: 'Healthy',
        category: widget.plantType,
      ));

      if (mounted) {
        setState(() {
          _isPlanting = false;
          _planted = true;
          _joinMessage = joinMsg;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isPlanting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child:
                Icon(LucideIcons.trees, size: 20, color: cs.onPrimaryContainer),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Community Plant QR',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 17,
              ),
            ),
          ),
        ],
      ),
      content: _isLoading
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator()),
            )
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Community name banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cs.primary.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(LucideIcons.globe2, size: 18, color: cs.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _communityName,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: cs.primary,
                            ),
                          ),
                        ),
                        if (_alreadyMember && !_planted)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Member',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.green.shade800,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Plant info
                  _infoRow(LucideIcons.sprout, 'Plant', widget.plantName),
                  _infoRow(LucideIcons.tag, 'Type', widget.plantType),
                  _infoRow(LucideIcons.sun, 'Best Season', widget.bestSeason),
                  _infoRow(LucideIcons.leaf, 'Form',
                      widget.isSeed ? 'Seed' : 'Plant'),
                  if (widget.plantAge != null)
                    _infoRow(LucideIcons.calendar, 'Age', widget.plantAge!),

                  const SizedBox(height: 12),

                  // Membership info
                  if (!_alreadyMember && !_planted)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(LucideIcons.info,
                              size: 16, color: Colors.blue.shade700),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Planting this will auto-join you to $_communityName',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: Colors.blue.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Success message
                  if (_planted && _joinMessage != null)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(LucideIcons.checkCircle,
                              size: 18, color: Colors.green.shade700),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _joinMessage!,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.green.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 8),
                ],
              ),
            ),
      actions: [
        if (!_planted && !_isLoading)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isPlanting ? null : _plantAndJoin,
              icon: _isPlanting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(LucideIcons.sprout),
              label: Text(
                _isPlanting
                    ? 'Planting...'
                    : _alreadyMember
                        ? '🌱 Plant Now'
                        : '🌱 Plant & Join Community',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            widget.onDone();
          },
          child: Text(
            _planted ? 'Done' : 'Close',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: cs.onSurface.withOpacity(0.5)),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: cs.onSurface.withOpacity(0.7),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(fontSize: 13, color: cs.onSurface),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
