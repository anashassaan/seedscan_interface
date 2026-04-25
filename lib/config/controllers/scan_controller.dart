// lib/config/controllers/scan_controller.dart
import 'dart:async';
import 'dart:convert';
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
import '../../services/appwrite_service.dart';
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

  /// Load all plants for [userId].
  /// CACHE-FIRST: Shows cached plants instantly, then syncs Appwrite in background.
  /// Returns immediately — caller is never blocked waiting for Appwrite.
  Future<void> loadMyPlants(String userId) async {
    if (userId.isEmpty) return;

    if (_loadedForUserId != userId) {
      _myPlants.clear();
      _loadedForUserId = userId;
    }

    _isLoadingPlants = true;

    // STEP 1: INSTANT LOAD FROM CACHE (shown to user immediately)
    _loadMyPlantsFromCache();
    notifyListeners();

    // STEP 2: BACKGROUND SYNC WITH APPWRITE (truly non-blocking)
    // ignore: unawaited_futures
    _syncMyPlantsFromAppwrite(userId);
  }

  /// Load plants from GardenCacheService (instant, no network required)
  void _loadMyPlantsFromCache() {
    try {
      final cachedQRData = GardenCacheService.getAllCachedQRetails();
      if (cachedQRData != null && cachedQRData.isNotEmpty) {
        _buildPlantsFromCachedData(cachedQRData);
        debugPrint(
            '[ScanController] Loaded ${_myPlants.length} cached plants from Hive');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[ScanController] Failed to load plants from cache: $e');
    }
  }

  /// Background sync: Fetch fresh plants from Appwrite
  Future<void> _syncMyPlantsFromAppwrite(String userId) async {
    try {
      debugPrint('[ScanController] Starting background sync for user $userId');
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

      debugPrint(
          '[ScanController] Background sync complete — ${_myPlants.length} plants');
    } catch (e) {
      debugPrint(
          '[ScanController] Background sync failed (using cached data): $e');
    } finally {
      _isLoadingPlants = false;
      notifyListeners();
    }
  }

  /// Build plants list from cached data
  void _buildPlantsFromCachedData(List<Map<String, dynamic>> cachedData) {
    _myPlants.clear();
    final seenIds = <String>{};

    for (final data in cachedData) {
      final id = data['docId'] as String?;
      if (id == null || seenIds.contains(id)) continue;
      seenIds.add(id);

      final imageUrl = (data['imageUrl'] as String?) ?? '';
      _myPlants.add(PlantModel(
        id: id,
        name: (data['plantName'] as String?) ?? 'Plant',
        scientificName: (data['localName'] as String?) ??
            (data['category'] as String?) ??
            '',
        image: imageUrl,
        status: 'Unknown',
        statusColor: const Color(0xFF9CA3AF),
        lastScan: '',
        location: null,
        latitude: null,
        longitude: null,
      ));
    }
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
      // Show plants that have been planted (plantedAt set) OR have images/location data indicating use.
      // Skip ONLY if:
      // 1. No plantedAt timestamp AND
      // 2. No image OR no location AND
      // 3. It's a very new QR (created in last 5 minutes - probably just generated, not used yet)
      final hasNoPlantingData = qr.plantedAt == null &&
          (qr.imageUrl == null || qr.imageUrl!.isEmpty) &&
          (qr.locationLat == 0.0 && qr.locationLong == 0.0);
      final isVeryNewQR = DateTime.now().difference(qr.createdAt).inMinutes < 5;

      if (hasNoPlantingData && isVeryNewQR) {
        continue; // Skip only if QR was just created and not used yet
      }

      if (seenIds.contains(qr.id)) continue;
      seenIds.add(qr.id);

      // Prefer the URL on the Appwrite model; fall back to Hive cache
      final imageUrl = (qr.imageUrl != null && qr.imageUrl!.isNotEmpty)
          ? qr.imageUrl!
          : (GardenCacheService.getImageUrl(qr.id) ?? '');

      // Use plantedAt if available, otherwise fall back to createdAt
      final displayDate = qr.plantedAt ?? qr.createdAt;

      _myPlants.add(PlantModel(
        id: qr.id,
        name: qr.plantName.isNotEmpty ? qr.plantName : 'Plant',
        scientificName: qr.localName.isNotEmpty ? qr.localName : qr.category,
        image: imageUrl,
        status: _healthStatusLabel(qr.notes),
        statusColor: _healthStatusColor(qr.notes),
        lastScan: _formatDate(displayDate),
        location: qr.gardenId,
        latitude: qr.locationLat != 0.0 ? qr.locationLat : null,
        longitude: qr.locationLong != 0.0 ? qr.locationLong : null,
      ));
    }
  }

  static String _healthStatusLabel(String notes) {
    final lower = notes.toLowerCase();
    if (lower.contains('disease') || lower.contains('sick')) {
      return 'Needs Attention';
    }
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
  Future<void> analyzeImageForDisease({Uint8List? imageBytes, BuildContext? context}) async {
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

      // Stage 3: Auto-update nearby plants via Geolocation
      if (_lastDetectionLabel != null && 
          _lastDetectionLabel != 'Analysis error' && 
          _lastDetectionLabel != 'Not an Apple Leaf' &&
          _lastDetectionLabel != 'No image provided' &&
          _lastDetectionLabel != 'Could not decode image') {
        
        final loc = await getCurrentLocation();
        if (loc != null) {
          final updatedPlants = await DatabaseService().autoUpdatePlantHealthNearLocation(
            loc.latitude, 
            loc.longitude, 
            _lastDetectionLabel!,
          );

          if (updatedPlants.isNotEmpty && context != null && context.mounted) {
            final snackBarMessage = updatedPlants.map((p) => 
               "${p['name']} (${p['type']}) in ${p['community']} -> ${p['status']}"
            ).join('\n');

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(snackBarMessage),
                duration: const Duration(seconds: 4),
              ),
            );
          }
        }
      }

    } catch (e) {
      debugPrint('Disease analysis error: $e');
      _lastDetectionLabel = 'Analysis error';
      _lastDetectionConfidence = 0.0;
    }

    _isProcessing = false;
    notifyListeners();
  }

  // Upload image and log history for admin timeline.
  // Intentionally does NOT overwrite the plant profile image.
  Future<Map<String, dynamic>> updatePlantImage(
      String plantId, String imagePath) async {
    final dbService = DatabaseService();
    final now = DateTime.now();
    final plant = _myPlants
        .cast<PlantModel?>()
        .firstWhere((p) => p?.id == plantId, orElse: () => null);

    try {
      // 1. Upload image to Appwrite storage + best-effort history append
      final result = await dbService.updateMyGardenPlantImage(
        docId: plantId,
        filePath: imagePath,
      );
      final fileId = result['fileId']!;
      final imageUrl = result['url']!;

      // 2. Write activity log for admin history with health + location metadata.
      try {
        final currentUser = await AppwriteService().getCurrentUser();
        final userId = currentUser?.$id ?? '';
        if (userId.isNotEmpty) {
          final historyPlantId = await dbService.resolveCanonicalPlantId(
            userId: userId,
            localGardenId: plantId,
            speciesName: plant?.name,
            latitude: plant?.latitude,
            longitude: plant?.longitude,
          );

          final historyMeta = jsonEncode({
            'type': 'image_update_meta',
            'updated_at': now.toIso8601String(),
            'health': plant?.status,
            'location': plant?.location,
            'latitude': plant?.latitude,
            'longitude': plant?.longitude,
            'source_plant_id': plantId,
            'resolved_plant_id': historyPlantId,
          });

          await dbService.createActivityLog(
            userId: userId,
            plantId: historyPlantId,
            communityId: plant?.driveId,
            actionType: 'scan_disease', // Bypass Appwrite enum restrictions
            coinsAwarded: 0,
            verificationStatus: 'verified',
            proofImageId: fileId,
            rejectionReason: historyMeta,
          );
        }
      } catch (e) {
        debugPrint('ScanController image history log failed: $e');
        throw Exception('Appwrite Error: $e');
      }

      debugPrint('Plant $plantId image history saved: $imageUrl');
      notifyListeners();

      return {
        'success': true,
        'fileId': fileId,
        'imageUrl': imageUrl,
        'updatedAt': now.toIso8601String(),
      };
    } catch (e) {
      debugPrint('Error updating plant image: $e');
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

        // Update database — try BOTH collections because the plant can live in
        // the `plants` collection (community) OR `my_garden_qr_codes` (personal).
        try {
          await DatabaseService().updatePlant(plantId, {
            'location_lat': position.latitude,
            'location_long': position.longitude,
          });
          print('Synced updated location to plants collection for $plantId');
        } catch (dbErr) {
          print('Failed to sync location to plants collection for $plantId: $dbErr');
        }

        try {
          await DatabaseService().updateMyGardenPlantLocation(
            docId: plantId,
            lat: position.latitude,
            lng: position.longitude,
          );
          print('Synced updated location to my_garden_qr_codes for $plantId');
        } catch (dbErr) {
          print('Failed to sync location to my_garden_qr_codes for $plantId: $dbErr');
        }
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

        // Update database asynchronously
        try {
          await DatabaseService().updatePlant(plantId, {
            'location_lat': position.latitude,
            'location_long': position.longitude,
          });
          print('Synced updated location with name to DB for $plantId');
        } catch (dbErr) {
          print('Failed to sync location to DB for $plantId: $dbErr');
        }
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

  // Synchronize location locally for a specific plant without doing DB calls or permissions
  void syncPlantLocationLocal(
      String plantId, String locationName, double latitude, double longitude) {
    final plantIndex = _myPlants.indexWhere((p) => p.id == plantId);
    if (plantIndex != -1) {
      final p = _myPlants[plantIndex];
      _myPlants[plantIndex] = PlantModel(
        id: p.id,
        name: p.name,
        scientificName: p.scientificName,
        image: p.image,
        status: p.status,
        statusColor: p.statusColor,
        lastScan: p.lastScan,
        location: locationName,
        latitude: latitude,
        longitude: longitude,
      );
      notifyListeners();
    }
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
  final String? driveId;
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
    this.driveId,
    this.latitude,
    this.longitude,
  });
}
