// lib/controllers/scan_controller.dart
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScanController extends ChangeNotifier {
  ScanController();

  // Mode: true => QR, false => Disease
  bool _isQrMode = true;
  bool get isQrMode => _isQrMode;

  // simple scanner state
  bool _isTorchOn = false;
  bool get isTorchOn => _isTorchOn;

  bool _isProcessing = false;
  bool get isProcessing => _isProcessing;

  // last scanned result (qr or detection)
  String? _lastQr;
  String? get lastQr => _lastQr;

  DateTime? _lastScanTime;
  DateTime? get lastScanTime => _lastScanTime;

  // Mock detection result
  String? _lastDetectionLabel;
  double? _lastDetectionConfidence;
  String? get lastDetectionLabel => _lastDetectionLabel;
  double? get lastDetectionConfidence => _lastDetectionConfidence;

  final MobileScannerController cameraController = MobileScannerController(
    formats: [BarcodeFormat.qrCode, BarcodeFormat.all],
  );

  void toggleMode() {
    _isQrMode = !_isQrMode;
    notifyListeners();
  }

  Future<void> toggleTorch() async {
    _isTorchOn = !_isTorchOn;
    try {
      await cameraController.toggleTorch();
    } catch (_) {
      // ignore hardware errors; keep state coherent
    }
    notifyListeners();
  }

  // Called when QR code is detected by MobileScanner
  Future<void> handleQr(String code) async {
    if (_isProcessing) return;
    _isProcessing = true;
    notifyListeners();

    // simulate debounce and processing
    await Future<void>.delayed(const Duration(milliseconds: 700));
    _lastQr = code;
    _lastScanTime = DateTime.now();

    // simulate a small server lookup / plant association
    await Future<void>.delayed(const Duration(milliseconds: 450));
    _isProcessing = false;
    notifyListeners();
  }

  // Simulate disease analysis when using camera capture
  Future<void> analyzeImageForDisease({required Uint8List imageBytes}) async {
    if (_isProcessing) return;
    _isProcessing = true;
    notifyListeners();

    // Simulate upload + model inference time
    await Future<void>.delayed(const Duration(seconds: 2, milliseconds: 200));

    // Mock result selection (deterministic for demo)
    _lastDetectionLabel = 'Fungal Infection';
    _lastDetectionConfidence = 0.92;
    _lastScanTime = DateTime.now();

    _isProcessing = false;
    notifyListeners();
  }

  // Reset scanning results
  void reset() {
    _lastQr = null;
    _lastDetectionLabel = null;
    _lastDetectionConfidence = null;
    _lastScanTime = null;
    notifyListeners();
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }
}
