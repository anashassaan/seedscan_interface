// lib/config/views/scan/scan_screen.dart
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../controllers/scan_controller.dart';

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
  @override
  void dispose() {
    _laserCtrl.dispose();
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
            onPressed: () => scan.toggleTorch(),
            icon: Icon(scan.isTorchOn ? Icons.flash_on : Icons.flash_off,
                color: cs.onBackground),
          ),
          IconButton(
            onPressed: () => scan.switchCamera(),
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
              // MobileScanner may throw on web — guard with kIsWeb in your app-level code.
              return MobileScanner(
                controller: scan.cameraController,
                fit: BoxFit.cover,
                onDetect: (capture) {
                  if (!scan.isQrMode) return; // only process in QR mode
                  for (final barcode in capture.barcodes) {
                    final String? raw = barcode.rawValue;
                    if (raw != null && raw.isNotEmpty) {
                      scan.handleQr(raw);
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

  void _onCapture(BuildContext context, ScanController scan) async {
    // Simulate capture flow: show bottom sheet "Analyzing..." then show result
    showModalBottomSheet(
      context: context,
      isScrollControlled: false,
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

    // simulate model analysis
    await scan.analyzeImageForDisease(imageBytes: null);

    // close the progress sheet
    if (mounted) Navigator.of(context).pop();

    // show result sheet
    if (mounted) {
      showModalBottomSheet(
        context: context,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        builder: (context) {
          return Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('Analysis Result',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              Text('${scan.lastDetectionLabel ?? 'No issue detected'}',
                  style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 8),
              if (scan.lastDetectionConfidence != null)
                Text(
                    'Confidence: ${(scan.lastDetectionConfidence! * 100).toStringAsFixed(0)}%'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ]),
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
    final text = scan.isQrMode
        ? (scan.lastQr != null ? 'Last QR: ${scan.lastQr}' : 'QR mode — ready')
        : (scan.lastDetectionLabel != null
            ? '${scan.lastDetectionLabel} ${(scan.lastDetectionConfidence != null ? '(${(scan.lastDetectionConfidence! * 100).toStringAsFixed(0)}%)' : '')}'
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
