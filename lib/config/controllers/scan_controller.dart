// lib/config/controllers/scan_controller.dart
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScanController extends ChangeNotifier {
  ScanController() {
    // nothing to init for now
  }

  // Camera controller from mobile_scanner (works on mobile & desktop)
  final MobileScannerController cameraController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  // Modes
  bool _isQrMode = true;
  bool get isQrMode => _isQrMode;

  bool _isProcessing = false;
  bool get isProcessing => _isProcessing;

  bool _isTorchOn = false;
  bool get isTorchOn => _isTorchOn;

  // Results
  String? _lastQr;
  String? get lastQr => _lastQr;

  String? _lastDetectionLabel;
  double? _lastDetectionConfidence;
  String? get lastDetectionLabel => _lastDetectionLabel;
  double? get lastDetectionConfidence => _lastDetectionConfidence;

  DateTime? _lastScanTime;
  DateTime? get lastScanTime => _lastScanTime;

  // Toggle between QR and Disease mode
  void toggleMode() {
    _isQrMode = !_isQrMode;
    notifyListeners();
  }

  // Toggle torch
  Future<void> toggleTorch() async {
    _isTorchOn = !_isTorchOn;
    try {
      await cameraController.toggleTorch();
    } catch (_) {
      // ignore - some platforms may not support it
    }
    notifyListeners();
  }

  // Switch camera facing (back/front)
  Future<void> switchCamera() async {
    try {
      await cameraController.switchCamera();
    } catch (_) {}
    notifyListeners();
  }

  // Handle QR barcode scanned
  Future<void> handleQr(String code) async {
    if (_isProcessing) return;
    _isProcessing = true;
    notifyListeners();

    // debounce / simulate small lookup
    await Future<void>.delayed(const Duration(milliseconds: 600));
    _lastQr = code;
    _lastScanTime = DateTime.now();

    // simulate a little additional processing
    await Future<void>.delayed(const Duration(milliseconds: 400));
    _isProcessing = false;
    notifyListeners();
  }

  // Analyze an image for disease (simulated). imageBytes optional.
  Future<void> analyzeImageForDisease({Uint8List? imageBytes}) async {
    if (_isProcessing) return;
    _isProcessing = true;
    _lastDetectionLabel = null;
    _lastDetectionConfidence = null;
    notifyListeners();

    // Simulate network/model latency
    await Future<void>.delayed(const Duration(seconds: 2));

    // Mock deterministic result
    _lastDetectionLabel = 'Fungal Infection';
    _lastDetectionConfidence = 0.92;
    _lastScanTime = DateTime.now();

    _isProcessing = false;
    notifyListeners();
  }

  // Simple list of plants (mock). Used by dashboard.
  List<PlantModel> getMyPlants() {
    return [
      PlantModel(
        id: '402',
        name: 'Moringa',
        image:
            'https://images.unsplash.com/photo-1501004318641-b39e6451bec6?auto=format&fit=crop&w=800&q=60',
        status: 'Healthy',
        statusColor: Colors.green,
        lastScan: '2 days ago',
      ),
      PlantModel(
        id: '278',
        name: 'Neem',
        image:
            'https://images.unsplash.com/photo-1501004318641-b39e6451bec6?auto=format&fit=crop&w=800&q=60',
        status: 'Needs Water',
        statusColor: Colors.orange,
        lastScan: '4 days ago',
      ),
      PlantModel(
        id: '119',
        name: 'Mango',
        image:
            'https://images.unsplash.com/photo-1497034825429-c343d7c6a68f?auto=format&fit=crop&w=800&q=60',
        status: 'Healthy',
        statusColor: Colors.green,
        lastScan: '1 day ago',
      ),
    ];
  }

  // Reset results
  void resetResults() {
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

class PlantModel {
  final String id;
  final String name;
  final String image;
  final String status;
  final Color statusColor;
  final String lastScan;

  PlantModel({
    required this.id,
    required this.name,
    required this.image,
    required this.status,
    required this.statusColor,
    required this.lastScan,
  });
}
