// lib/config/views/home/qr_scanner_screen.dart
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/scan_controller.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _laserCtrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat(reverse: true);

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
        leading: BackButton(color: Colors.white),
        title: Text(
          'Scan QR Code',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => scan.toggleTorch(),
            icon: Icon(
              scan.isTorchOn ? Icons.flash_on : Icons.flash_off,
              color: Colors.white,
            ),
          ),
          IconButton(
            onPressed: () => scan.switchCamera(),
            icon: const Icon(
              Icons.cameraswitch_rounded,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // Camera preview (fills the screen)
          Positioned.fill(
            child: MobileScanner(
              controller: scan.cameraController,
              fit: BoxFit.cover,
              onDetect: (capture) {
                for (final barcode in capture.barcodes) {
                  final String? raw = barcode.rawValue;
                  if (raw != null && raw.isNotEmpty) {
                    scan.handleQr(raw);
                    // Show success dialog
                    _showQRResult(context, raw);
                  }
                }
              },
            ),
          ),

          // Dark overlay with transparent cutout
          Positioned.fill(
            child: _OverlayCutout(cornerRadius: 20),
          ),

          // Laser animation inside the cutout
          Center(
            child: SizedBox(
              width: 300,
              height: 300,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    // Laser animation
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
                    // Border for the cutout
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.5),
                            width: 2,
                          ),
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
            child: Center(
              child: _StatusPill(scan: scan),
            ),
          ),

          // Bottom instruction text
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Align QR code within the frame',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showQRResult(BuildContext context, String qrData) {
    // Close the scanner and show result
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(
              Icons.qr_code_scanner,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Text(
              'QR Code Scanned',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Scanned Data:',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                qrData,
                style: GoogleFonts.poppins(fontSize: 13),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close scanner
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}

/// Status pill showing last QR or scanning status
class _StatusPill extends StatelessWidget {
  final ScanController scan;
  const _StatusPill({required this.scan});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text =
        scan.lastQr != null ? 'Last QR: ${scan.lastQr}' : 'QR Scanner Ready';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

/// Dark overlay with transparent cutout for the scanning area
class _OverlayCutout extends StatelessWidget {
  final double cornerRadius;
  const _OverlayCutout({this.cornerRadius = 0});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CutoutPainter(cornerRadius: cornerRadius),
    );
  }
}

class _CutoutPainter extends CustomPainter {
  final double cornerRadius;
  _CutoutPainter({this.cornerRadius = 0});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withOpacity(0.65);
    final cutoutSize = 300.0;
    final left = (size.width - cutoutSize) / 2;
    final top = (size.height - cutoutSize) / 2;

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, cutoutSize, cutoutSize),
        Radius.circular(cornerRadius),
      ))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CutoutPainter oldDelegate) => false;
}
