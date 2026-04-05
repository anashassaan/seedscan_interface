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
import '../../services/database_service.dart';
import '../../services/garden_cache_service.dart';
import '../../models/my_garden_qr_model.dart';

class ScanController extends ChangeNotifier {
  ScanController() {
    // Initialize plants list
    _initializePlants();
  }

  // Mutable plants list
  final List<PlantModel> _myPlants = [];
  String? _loadedForUserId;

  // Loading state for DB fetch
  bool _isLoadingPlants = false;
  bool get isLoadingPlants => _isLoadingPlants;

  void _initializePlants() {
    // Plants list starts empty — populated from DB or QR scan
  }

  /// Load all plants for [userId] from Appwrite (my_garden_qr_codes collection).
  Future<void> loadMyPlants(String userId) async {
    if (userId.isEmpty) return;

    if (_loadedForUserId != userId) {
      _myPlants.clear();
      _loadedForUserId = userId;
    }

    _isLoadingPlants = true;
    notifyListeners();

    try {
      final db = DatabaseService();
      final qrList = await db.listMyGardenQRCodes(userId);

      // Sync image data to Hive so tabs & cards always have a URL available
      await GardenCacheService.syncAll(
        qrList
            .map((qr) => {
                  'docId': qr.id,
                  'plantName': qr.plantName,
                  'localName': qr.localName,
                  'category': qr.category,
                  'imageFileId': qr.imageFileId,
                  'imageUrl': qr.imageUrl,
                })
            .toList(),
      );

      _buildPlantsFromQR(qrList);
    } catch (e) {
      debugPrint('ScanController.loadMyPlants failed: $e');
    }

    _isLoadingPlants = false;
    notifyListeners();
  }

  /// Update the in-memory plants list from a pre-fetched QR list.
  /// Called from MyGardenScreen after a successful image upload so that
  /// All-Plants / Healthy / Needs-Care tabs immediately reflect the new photo.
  void updateFromQRCodes(List<MyGardenQRModel> qrList) {
    _buildPlantsFromQR(qrList);
    notifyListeners();
  }

  void _buildPlantsFromQR(List<MyGardenQRModel> qrList) {
    _myPlants.clear();
    final seenIds = <String>{};

    for (final qr in qrList) {
      // Only show QR codes that have been scanned and planted.
      // A QR with plantedAt == null is one that was generated but not yet scanned.
      if (qr.plantedAt == null) continue;

      if (seenIds.contains(qr.id)) continue;
      seenIds.add(qr.id);

      // Prefer the URL on the Appwrite model; fall back to Hive cache
      final imageUrl = (qr.imageUrl != null && qr.imageUrl!.isNotEmpty)
          ? qr.imageUrl!
          : (GardenCacheService.getImageUrl(qr.id) ?? '');

      _myPlants.add(PlantModel(
        id: qr.id,
        name: qr.plantName.isNotEmpty ? qr.plantName : 'Plant',
        scientificName: qr.localName.isNotEmpty ? qr.localName : qr.category,
        image: imageUrl,
        status: _healthStatusLabel(qr.notes),
        statusColor: _healthStatusColor(qr.notes),
        lastScan: _formatDate(qr.plantedAt),
        location: qr.gardenId,
        latitude: qr.locationLat != 0.0 ? qr.locationLat : null,
        longitude: qr.locationLong != 0.0 ? qr.locationLong : null,
      ));
    }
  }

  static String _healthStatusLabel(String notes) {
    final lower = notes.toLowerCase();
    if (lower.contains('disease') || lower.contains('sick'))
      return 'Needs Attention';
    if (lower.contains('water')) return 'Needs Water';
    return 'Healthy';
  }

  static Color _healthStatusColor(String notes) {
    final lower = notes.toLowerCase();
    if (lower.contains('disease') || lower.contains('sick')) return Colors.red;
    if (lower.contains('water')) return Colors.orange;
    return Colors.green;
  }

  static String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown';
    return '${date.day}/${date.month}/${date.year}';
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

  // Handle QR barcode scanned — lightweight, non-blocking.
  Future<Map<String, dynamic>> handleQr(String code) async {
    _lastQr = code;
    _lastScanTime = DateTime.now();
    notifyListeners();

    // Capture location in the background (don't block detection)
    getCurrentLocation().then((position) {
      if (position != null) {
        _lastLatitude = position.latitude;
        _lastLongitude = position.longitude;
        notifyListeners();
      }
    }).catchError((_) {});

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

  // Update plant with new image — uploads to Appwrite and updates DB + in-memory list
  Future<Map<String, dynamic>> updatePlantImage(
      String plantId, String imagePath) async {
    final dbService = DatabaseService();
    final now = DateTime.now();
    final timeLabel =
        '${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute.toString().padLeft(2, '0')}';

    try {
      // 1. Upload to Appwrite bucket + best-effort DB update
      final result = await dbService.updateMyGardenPlantImage(
        docId: plantId,
        filePath: imagePath,
      );
      final fileId = result['fileId']!;
      final imageUrl = result['url']!;

      // 2. Persist URL in Hive so it survives navigation and app restart
      await GardenCacheService.updateImage(plantId, fileId, imageUrl);

      // 3. Update in-memory plant list
      final plantIndex = _myPlants.indexWhere((plant) => plant.id == plantId);
      if (plantIndex != -1) {
        final plant = _myPlants[plantIndex];
        _myPlants[plantIndex] = PlantModel(
          id: plant.id,
          name: plant.name,
          scientificName: plant.scientificName,
          image: imageUrl,
          status: plant.status,
          statusColor: plant.statusColor,
          lastScan: timeLabel,
          location: plant.location,
          latitude: plant.latitude,
          longitude: plant.longitude,
        );
      }

      debugPrint('Plant $plantId image updated: $imageUrl at $timeLabel');
      notifyListeners();

      return {
        'success': true,
        'fileId': fileId,
        'imageUrl': imageUrl,
        'updatedAt': now.toIso8601String(),
      };
    } catch (e) {
      debugPrint('Error updating plant image: $e');

      // Fallback: store local path in-memory only (will not survive restart,
      // but at least shows something for this session)
      final plantIndex = _myPlants.indexWhere((plant) => plant.id == plantId);
      if (plantIndex != -1) {
        final plant = _myPlants[plantIndex];
        _myPlants[plantIndex] = PlantModel(
          id: plant.id,
          name: plant.name,
          scientificName: plant.scientificName,
          image: imagePath,
          status: plant.status,
          statusColor: plant.statusColor,
          lastScan: timeLabel,
          location: plant.location,
          latitude: plant.latitude,
          longitude: plant.longitude,
        );
      }
      notifyListeners();

      return {
        'success': false,
        'error': e.toString(),
      };
    }
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

  /// Add a plant to the garden list (from QR scan + photo + GPS).
  void addPlantToGarden(PlantModel plant) {
    final existingIndex = _myPlants.indexWhere((p) => p.id == plant.id);
    if (existingIndex != -1) {
      _myPlants[existingIndex] = plant;
    } else {
      _myPlants.insert(0, plant);
    }
    notifyListeners();
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
