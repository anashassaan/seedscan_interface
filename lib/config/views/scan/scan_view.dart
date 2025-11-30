// lib/views/scan/scan_view.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../controllers/scan_controller.dart';
import 'package:image_picker/image_picker.dart';

class ScanView extends StatelessWidget {
  const ScanView({super.key});

  @override
  Widget build(BuildContext context) {
    final scan = Provider.of<ScanController>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan'),
        actions: [
          IconButton(
            onPressed: scan.toggleTorch,
            icon: Icon(scan.isTorchOn ? Icons.flash_on : Icons.flash_off),
          ),
          IconButton(
            onPressed: scan.toggleMode,
            icon: Icon(scan.isQrMode ? Icons.document_scanner : Icons.qr_code),
          ),
        ],
      ),
      body: scan.isQrMode
          ? _qrScanner(context, scan)
          : _diseaseMode(context, scan),
      floatingActionButton: !scan.isQrMode
          ? FloatingActionButton.extended(
              onPressed: () => _pickImage(context),
              label: const Text("Upload Leaf Image"),
              icon: const Icon(Icons.photo),
            )
          : null,
    );
  }

  Widget _qrScanner(BuildContext context, ScanController scan) {
    return Column(
      children: [
        Expanded(
          child: MobileScanner(
            controller: scan.cameraController,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                final String? raw = barcode.rawValue;
                if (raw != null) {
                  scan.handleQr(raw);
                  break; // Handle only the first valid QR
                }
              }
            },
          ),
        ),
        _resultBox(scan),
      ],
    );
  }

  Widget _diseaseMode(BuildContext context, ScanController scan) {
    return Column(
      children: [
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(16),
            ),
            child: scan.isProcessing
                ? const Center(child: CircularProgressIndicator())
                : const Center(child: Text("Capture or upload an image")),
          ),
        ),
        _resultBox(scan),
      ],
    );
  }

  Widget _resultBox(ScanController scan) {
    return Card(
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: scan.isProcessing
            ? const Text("Processing...")
            : scan.isQrMode
                ? Text("Last QR: ${scan.lastQr ?? 'None'}")
                : Text(
                    scan.lastDetectionLabel == null
                        ? "No analysis yet"
                        : "Detected: ${scan.lastDetectionLabel!}\nConfidence: ${(scan.lastDetectionConfidence! * 100).toStringAsFixed(1)}%",
                  ),
      ),
    );
  }

  Future<void> _pickImage(BuildContext context) async {
    final picker = ImagePicker();
    final scan = Provider.of<ScanController>(context, listen: false);

    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    Uint8List bytes = await image.readAsBytes();
    scan.analyzeImageForDisease(imageBytes: bytes);
  }
}
