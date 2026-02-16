// lib/config/controllers/scan_controller.dart
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image/image.dart' as img;
import '../../services/apple_detection_service.dart';
import '../../services/disease_classifier_service.dart';

class ScanController extends ChangeNotifier {
  ScanController() {
    // Initialize plants list
    _initializePlants();
  }

  // Mutable plants list
  final List<PlantModel> _myPlants = [];

  void _initializePlants() {
    // TODO: DUMMY DATA - These are placeholder images for demo purposes only
    // In production, replace all 'image' URLs with user-uploaded plant photos
    _myPlants.addAll([
      PlantModel(
        id: '402',
        name: 'Golden Pothos',
        scientificName: 'Epipremnum aureum',
        image:
            'https://images.unsplash.com/photo-1501004318641-b39e6451bec6?auto=format&fit=crop&w=800&q=60', // PLACEHOLDER - Replace with user upload
        status: 'Healthy',
        statusColor: Colors.green,
        lastScan: '2 days ago',
        location: 'Garden, Near Window',
        latitude: 31.5204,
        longitude: 74.3587,
      ),
      PlantModel(
        id: '278',
        name: 'Fiddle Leaf Fig',
        scientificName: 'Ficus lyrata',
        image:
            'https://images.unsplash.com/photo-1501004318641-b39e6451bec6?auto=format&fit=crop&w=800&q=60',
        status: 'Needs Water',
        statusColor: Colors.orange,
        lastScan: '5 hours ago',
        location: 'Living Room, Corner',
        latitude: 31.5200,
        longitude: 74.3580,
      ),
      PlantModel(
        id: '119',
        name: 'Snake Plant',
        scientificName: 'Dracaena trifasciata',
        image:
            'https://images.unsplash.com/photo-1497034825429-c343d7c6a68f?auto=format&fit=crop&w=800&q=60',
        status: 'Healthy',
        statusColor: Colors.green,
        lastScan: '1 week ago',
        location: 'Bedroom, Nightstand',
        latitude: 31.5210,
        longitude: 74.3595,
      ),
    ]);
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

  // Location data
  double? _lastLatitude;
  double? _lastLongitude;
  double? get lastLatitude => _lastLatitude;
  double? get lastLongitude => _lastLongitude;

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

  // Request location permission
  Future<bool> requestLocationPermission() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }

  // Get current location
  Future<Position?> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      debugPrint('Error getting location: $e');
      return null;
    }
  }

  // Handle QR barcode scanned
  Future<Map<String, dynamic>> handleQr(String code) async {
    if (_isProcessing)
      return {'success': false, 'message': 'Already processing'};
    _isProcessing = true;
    notifyListeners();

    // Capture location when QR is scanned
    final position = await getCurrentLocation();
    if (position != null) {
      _lastLatitude = position.latitude;
      _lastLongitude = position.longitude;
    }

    // debounce / simulate small lookup
    await Future<void>.delayed(const Duration(milliseconds: 600));
    _lastQr = code;
    _lastScanTime = DateTime.now();

    // simulate a little additional processing
    await Future<void>.delayed(const Duration(milliseconds: 400));
    _isProcessing = false;
    notifyListeners();

    // Return the QR code and location data
    return {
      'success': true,
      'qrCode': code,
      'latitude': _lastLatitude,
      'longitude': _lastLongitude,
    };
  }

  // Analyze an image for disease using real TFLite models.
  Future<void> analyzeImageForDisease({Uint8List? imageBytes}) async {
    if (_isProcessing) return;
    _isProcessing = true;
    _lastDetectionLabel = null;
    _lastDetectionConfidence = null;
    notifyListeners();

    try {
      if (imageBytes == null) {
        _lastDetectionLabel = 'No image provided';
        _lastDetectionConfidence = 0.0;
        _isProcessing = false;
        notifyListeners();
        return;
      }

      // Decode image bytes
      final image = img.decodeImage(imageBytes);
      if (image == null) {
        _lastDetectionLabel = 'Could not decode image';
        _lastDetectionConfidence = 0.0;
        _isProcessing = false;
        notifyListeners();
        return;
      }

      // Stage 1: Apple leaf detection
      await AppleDetectionService.loadModel();
      final isApple = await AppleDetectionService.isAppleLeaf(image);

      if (!isApple) {
        _lastDetectionLabel = 'Not an Apple Leaf';
        _lastDetectionConfidence = 0.0;
        _lastScanTime = DateTime.now();
        _isProcessing = false;
        notifyListeners();
        return;
      }

      // Stage 2: Disease classification
      await DiseaseClassifierService.loadModel();
      final result = await DiseaseClassifierService.classify(image);

      _lastDetectionLabel = result['disease'] as String?;
      _lastDetectionConfidence = (result['confidence'] as num?)?.toDouble();
      _lastScanTime = DateTime.now();
    } catch (e) {
      debugPrint('Disease analysis error: $e');
      _lastDetectionLabel = 'Analysis error';
      _lastDetectionConfidence = 0.0;
    }

    _isProcessing = false;
    notifyListeners();
  }

  // Update plant with new image
  Future<void> updatePlantImage(String plantId, String imagePath) async {
    // In a real app, this would upload the image and update the database
    // For now, we'll just notify listeners
    print('Updating plant $plantId with new image: $imagePath');
    notifyListeners();
  }

  // Update plant location with new GPS coordinates
  Future<Map<String, dynamic>> updatePlantLocation(String plantId) async {
    try {
      // Request location permissions
      final permission = await Permission.location.request();
      if (permission.isDenied || permission.isPermanentlyDenied) {
        return {
          'success': false,
          'error':
              'Location permission denied. Please enable location access in settings.',
        };
      }

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return {
          'success': false,
          'error': 'Location services are disabled. Please enable GPS.',
        };
      }

      // Get current position with timeout
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      ).timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          throw Exception('Location request timed out. Please try again.');
        },
      );

      // Update location tracking
      _lastLatitude = position.latitude;
      _lastLongitude = position.longitude;

      // Find and update the plant in the list
      final plantIndex = _myPlants.indexWhere((plant) => plant.id == plantId);
      if (plantIndex != -1) {
        final plant = _myPlants[plantIndex];

        // Create a more meaningful location name with timestamp
        final now = DateTime.now();
        final locationName =
            'Updated Location (${now.hour}:${now.minute.toString().padLeft(2, '0')})';

        _myPlants[plantIndex] = PlantModel(
          id: plant.id,
          name: plant.name,
          scientificName: plant.scientificName,
          image: plant.image,
          status: plant.status,
          statusColor: plant.statusColor,
          lastScan: 'Just now',
          location: locationName,
          latitude: position.latitude,
          longitude: position.longitude,
        );
        print(
            'Updated plant $plantId location: ${position.latitude}, ${position.longitude}');
        notifyListeners();
      }

      return {
        'success': true,
        'latitude': position.latitude,
        'longitude': position.longitude,
      };
    } catch (e) {
      print('Error updating location: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Update plant location with custom name
  Future<Map<String, dynamic>> updatePlantLocationWithName(
    String plantId,
    String locationName,
  ) async {
    try {
      // Request location permissions
      final permission = await Permission.location.request();
      if (permission.isDenied || permission.isPermanentlyDenied) {
        return {
          'success': false,
          'error':
              'Location permission denied. Please enable location access in settings.',
        };
      }

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return {
          'success': false,
          'error': 'Location services are disabled. Please enable GPS.',
        };
      }

      // Get current position with timeout
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      ).timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          throw Exception('Location request timed out. Please try again.');
        },
      );

      // Update location tracking
      _lastLatitude = position.latitude;
      _lastLongitude = position.longitude;

      // Find and update the plant in the list
      final plantIndex = _myPlants.indexWhere((plant) => plant.id == plantId);
      if (plantIndex != -1) {
        final plant = _myPlants[plantIndex];

        _myPlants[plantIndex] = PlantModel(
          id: plant.id,
          name: plant.name,
          scientificName: plant.scientificName,
          image: plant.image,
          status: plant.status,
          statusColor: plant.statusColor,
          lastScan: 'Just now',
          location: locationName,
          latitude: position.latitude,
          longitude: position.longitude,
        );
        print(
            'Updated plant $plantId location: $locationName (${position.latitude}, ${position.longitude})');
        notifyListeners();
      }

      return {
        'success': true,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'locationName': locationName,
      };
    } catch (e) {
      print('Error updating location: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Get location with custom name (helper method without updating plants)
  Future<Map<String, dynamic>> getLocationWithName(String locationName) async {
    try {
      // Request location permissions
      final permission = await Permission.location.request();
      if (permission.isDenied || permission.isPermanentlyDenied) {
        return {
          'success': false,
          'error':
              'Location permission denied. Please enable location access in settings.',
        };
      }

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return {
          'success': false,
          'error': 'Location services are disabled. Please enable GPS.',
        };
      }

      // Get current position with timeout
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      ).timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          throw Exception('Location request timed out. Please try again.');
        },
      );

      // Update location tracking
      _lastLatitude = position.latitude;
      _lastLongitude = position.longitude;

      return {
        'success': true,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'locationName': locationName,
      };
    } catch (e) {
      print('Error getting location: $e');
      return {
        'success': false,
        'error': e.toString().contains('timed out')
            ? 'Location request timed out. Please ensure GPS is enabled and try again.'
            : 'Could not get location. Please check GPS settings.',
      };
    }
  }

  // Simple list of plants (mock). Used by dashboard.
  List<PlantModel> getMyPlants() {
    return _myPlants;
  }

  // Reset results
  void resetResults() {
    _lastQr = null;
    _lastDetectionLabel = null;
    _lastDetectionConfidence = null;
    _lastScanTime = null;
    _lastLatitude = null;
    _lastLongitude = null;
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
  final String scientificName;
  final String image;
  final String status;
  final Color statusColor;
  final String lastScan;
  final String? location;
  final double? latitude;
  final double? longitude;

  PlantModel({
    required this.id,
    required this.name,
    required this.scientificName,
    required this.image,
    required this.status,
    required this.statusColor,
    required this.lastScan,
    this.location,
    this.latitude,
    this.longitude,
  });
}
