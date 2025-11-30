// lib/config/views/scan/unified_scan_screen.dart
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../controllers/scan_controller.dart';
import 'package:google_fonts/google_fonts.dart';

class UnifiedScanScreen extends StatefulWidget {
  const UnifiedScanScreen({super.key});

  @override
  State<UnifiedScanScreen> createState() => _UnifiedScanScreenState();
}

class _UnifiedScanScreenState extends State<UnifiedScanScreen>
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
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: Text(
          scan.isQrMode ? 'Scan QR Code' : 'Disease Detector',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          // AI Active badge - Only show in Disease mode
          if (!scan.isQrMode)
            Container(
              margin: const EdgeInsets.only(right: 16, top: 12, bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: Text(
                'AI Active',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          // Camera preview
          Positioned.fill(
            child: MobileScanner(
              controller: scan.cameraController,
              fit: BoxFit.cover,
              onDetect: (capture) {
                if (!scan.isQrMode) return;
                for (final barcode in capture.barcodes) {
                  final String? raw = barcode.rawValue;
                  if (raw != null && raw.isNotEmpty) {
                    scan.handleQr(raw);
                    _showQrResult(context, raw, scan);
                  }
                }
              },
            ),
          ),

          // Dark overlay with cutout
          Positioned.fill(
            child: CustomPaint(
              painter: _OverlayCutoutPainter(
                scanMode: scan.isQrMode,
              ),
            ),
          ),

          // Scan frame with laser
          Center(
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: scan.isQrMode ? Colors.green : Colors.amber,
                  width: 3,
                  strokeAlign: BorderSide.strokeAlignOutside,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    // Laser animation for QR mode
                    if (scan.isQrMode)
                      AnimatedBuilder(
                        animation: _laserCtrl,
                        builder: (context, child) {
                          return Align(
                            alignment: Alignment(0, (_laserCtrl.value * 2) - 1),
                            child: Container(
                              width: double.infinity,
                              height: 2,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.green.withOpacity(0.0),
                                    Colors.green.withOpacity(0.9),
                                    Colors.green.withOpacity(0.0),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                    // Dashed border for disease mode
                    if (!scan.isQrMode)
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _DashedCirclePainter(
                            color: Colors.amber,
                          ),
                        ),
                      ),

                    // Mode toggle buttons at bottom of frame
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _ModeButton(
                              label: 'QR Scan',
                              isActive: scan.isQrMode,
                              onTap: () {
                                if (!scan.isQrMode) scan.toggleMode();
                              },
                            ),
                            const SizedBox(width: 4),
                            _ModeButton(
                              label: 'Disease',
                              isActive: !scan.isQrMode,
                              onTap: () {
                                if (scan.isQrMode) scan.toggleMode();
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Instruction text
                    if (!scan.isQrMode)
                      Center(
                        child: Text(
                          'Align Plant Leaf',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Capture button for disease mode
          if (!scan.isQrMode)
            Positioned(
              bottom: 60,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: scan.isProcessing
                      ? null
                      : () => _captureAndAnalyze(context, scan),
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: scan.isProcessing
                        ? const Padding(
                            padding: EdgeInsets.all(15.0),
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.black),
                            ),
                          )
                        : null,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showQrResult(BuildContext context, String qrData, ScanController scan) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.qr_code_scanner, size: 48, color: Colors.green),
            const SizedBox(height: 16),
            Text(
              'QR Code Scanned',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              qrData,
              style: GoogleFonts.poppins(fontSize: 14),
              textAlign: TextAlign.center,
            ),
            if (scan.lastLatitude != null && scan.lastLongitude != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_on, size: 20, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text(
                      'Location: ${scan.lastLatitude!.toStringAsFixed(6)}, ${scan.lastLongitude!.toStringAsFixed(6)}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.blue.shade900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  void _captureAndAnalyze(BuildContext context, ScanController scan) async {
    await scan.analyzeImageForDisease(imageBytes: null);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              scan.lastDetectionLabel?.toLowerCase().contains('healthy') ??
                      false
                  ? Icons.check_circle
                  : Icons.warning,
              size: 48,
              color:
                  scan.lastDetectionLabel?.toLowerCase().contains('healthy') ??
                          false
                      ? Colors.green
                      : Colors.orange,
            ),
            const SizedBox(height: 16),
            Text(
              'Analysis Result',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              scan.lastDetectionLabel ?? 'No issue detected',
              style: GoogleFonts.poppins(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            if (scan.lastDetectionConfidence != null) ...[
              const SizedBox(height: 8),
              Text(
                'Confidence: ${(scan.lastDetectionConfidence! * 100).toStringAsFixed(0)}%',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _ModeButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            color: isActive ? Colors.black : Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _OverlayCutoutPainter extends CustomPainter {
  final bool scanMode;

  _OverlayCutoutPainter({required this.scanMode});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withOpacity(0.6);

    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final center = Offset(size.width / 2, size.height / 2);
    final scanSize = 300.0;
    final cutoutRect = Rect.fromCenter(
      center: center,
      width: scanSize,
      height: scanSize,
    );
    final cutoutPath = Path()
      ..addRRect(
          RRect.fromRectAndRadius(cutoutRect, const Radius.circular(20)));

    final overlayPath = Path.combine(
      PathOperation.difference,
      backgroundPath,
      cutoutPath,
    );

    canvas.drawPath(overlayPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DashedCirclePainter extends CustomPainter {
  final Color color;

  _DashedCirclePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.35;

    const dashWidth = 10.0;
    const dashSpace = 5.0;
    double startAngle = 0;

    while (startAngle < 360) {
      final endAngle = startAngle + dashWidth;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        _degreesToRadians(startAngle),
        _degreesToRadians(dashWidth),
        false,
        paint,
      );
      startAngle = endAngle + dashSpace;
    }
  }

  double _degreesToRadians(double degrees) =>
      degrees * (3.141592653589793 / 180);

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
