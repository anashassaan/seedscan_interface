// lib/config/views/home/qr_scanner_screen.dart
import 'dart:convert';
import 'dart:io' as java;
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../../controllers/scan_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/community_controller.dart';
import '../../../services/database_service.dart';
import '../../../models/community_model.dart';
import '../../../models/my_garden_qr_model.dart';

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

  // Local camera controller – created fresh each time the screen opens
  late final MobileScannerController _cameraController =
      MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  bool _hasScanned = false; // guard so we only process one QR per session
  bool _isTorchOn = false;

  @override
  void dispose() {
    _laserCtrl.dispose();
    _cameraController.dispose();
    super.dispose();
  }

  void _toggleTorch() async {
    try {
      await _cameraController.toggleTorch();
      setState(() => _isTorchOn = !_isTorchOn);
    } catch (_) {}
  }

  void _switchCamera() async {
    try {
      await _cameraController.switchCamera();
    } catch (_) {}
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
            onPressed: _toggleTorch,
            icon: Icon(
              _isTorchOn ? Icons.flash_on : Icons.flash_off,
              color: Colors.white,
            ),
          ),
          IconButton(
            onPressed: _switchCamera,
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
              controller: _cameraController,
              fit: BoxFit.cover,
              onDetect: (capture) {
                if (_hasScanned) return; // only process once
                for (final barcode in capture.barcodes) {
                  final String? raw = barcode.rawValue;
                  if (raw != null && raw.isNotEmpty) {
                    _hasScanned = true;
                    _cameraController.stop(); // pause camera
                    scan.handleQr(raw);
                    _showQRResult(context, raw);
                    return; // exit after first valid barcode
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
    // Try to parse the QR data as JSON to see if it's a My Garden QR
    Map<String, dynamic>? parsed;
    try {
      parsed = jsonDecode(qrData) as Map<String, dynamic>;
    } catch (_) {
      parsed = null;
    }

    final isMyGardenQR = parsed != null &&
        parsed['source'] == 'my_garden' &&
        parsed['id'] != null;

    // Check for community/admin QR: SEEDSCAN|communityId|id|plantName|...
    final isCommunityQR = qrData.startsWith('SEEDSCAN|');

    if (isMyGardenQR) {
      _showMyGardenQRResult(context, parsed!);
    } else if (isCommunityQR) {
      _showCommunityQRResult(context, qrData);
    } else {
      _showGenericQRResult(context, qrData);
    }
  }

  /// Show a rich dialog for Community plant QR codes.
  /// Format: SEEDSCAN|communityId|id|plantName|plantType|bestSeason|SEED/PLANT|plantAge|timestamp
  void _showCommunityQRResult(BuildContext context, String qrData) {
    final parts = qrData.split('|');
    if (parts.length < 9) {
      _showGenericQRResult(context, qrData);
      return;
    }

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
        return _CommunityQRDialog(
          communityId: communityId,
          qrId: qrId,
          plantName: plantName,
          plantType: plantType,
          bestSeason: bestSeason,
          isSeed: isSeed,
          plantAge: plantAge,
        );
      },
    );
  }

  /// Show a rich dialog for My Garden QR codes with DB lookup & add-to-garden.
  void _showMyGardenQRResult(
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
        return _MyGardenQRDialog(
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
          qrPayload: qrPayload,
        );
      },
    );
  }

  /// Generic QR result dialog for non-garden QR codes.
  void _showGenericQRResult(BuildContext context, String qrData) {
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

/// Stateful dialog that checks the DB and offers "Add to My Garden".
class _MyGardenQRDialog extends StatefulWidget {
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
  final Map<String, dynamic> qrPayload;

  const _MyGardenQRDialog({
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
    required this.qrPayload,
  });

  @override
  State<_MyGardenQRDialog> createState() => _MyGardenQRDialogState();
}

class _MyGardenQRDialogState extends State<_MyGardenQRDialog> {
  bool _isChecking = true;
  bool _existsInDb = false;
  MyGardenQRModel? _foundQr;
  bool _alreadyInMyGarden = false;
  bool _isPlanting = false;
  bool _planted = false;
  String? _capturedImagePath;

  @override
  void initState() {
    super.initState();
    _checkDatabase();
  }

  Future<void> _checkDatabase() async {
    final auth = Provider.of<AuthController>(context, listen: false);
    final userId = auth.userId ?? '';

    // 1. Check if this QR exists at all in the DB
    final found =
        await widget.dbService.findMyGardenQRByUniqueCode(widget.uniqueCode);

    // 2. Check if current user already has this QR in their garden
    bool alreadyOwned = false;
    if (found != null && found.ownerId == userId) {
      alreadyOwned = true;
    } else if (userId.isNotEmpty) {
      alreadyOwned =
          await widget.dbService.qrExistsForUser(widget.uniqueCode, userId);
    }

    if (mounted) {
      setState(() {
        _isChecking = false;
        _existsInDb = found != null;
        _foundQr = found;
        _alreadyInMyGarden = alreadyOwned;
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
        // User cancelled camera
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
          // Wait a moment for user to enable
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
        // GPS failed — continue with 0,0
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
        // Image upload failed — still save locally
      }

      // 4. Save to DB with location + image + planting timestamp
      final auth = Provider.of<AuthController>(context, listen: false);
      final gardenId = 'GARDEN-${auth.userHandle.toUpperCase()}';
      try {
        if (_foundQr != null) {
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
      } catch (_) {
        // DB save failed — plant still added locally
      }

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
      } catch (_) {
        // plants collection save failed — non-critical
      }

      // 6. Add plant to My Garden plants list (in-memory)
      final scanCtrl = Provider.of<ScanController>(context, listen: false);
      final timeLabel =
          '${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute.toString().padLeft(2, '0')}';

      final newPlant = PlantModel(
        id: widget.uniqueCode,
        name: widget.plantName,
        scientificName:
            widget.localName.isNotEmpty ? widget.localName : widget.category,
        image: imageUrl ?? photo.path, // prefer Appwrite URL, fallback local
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
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
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
            child: Text(
              'My Garden QR Detected',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 17,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

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
                    Text(
                      'MY GARDEN',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.green.shade800,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Plant name
            Text(
              widget.plantName,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
            if (widget.localName.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                widget.localName,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: cs.onSurface.withOpacity(0.6),
                ),
              ),
            ],
            const SizedBox(height: 12),

            // Type badge
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.isPlant
                        ? Colors.teal.withOpacity(0.1)
                        : Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.isPlant
                            ? LucideIcons.flower2
                            : LucideIcons.sprout,
                        size: 14,
                        color: widget.isPlant
                            ? Colors.teal
                            : Colors.amber.shade700,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.qrType,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: widget.isPlant
                              ? Colors.teal
                              : Colors.amber.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.category,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: cs.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Details
            _infoTile(LucideIcons.sun, 'Best Season', widget.bestSeason),
            if (widget.isPlant && widget.plantAge != null)
              _infoTile(LucideIcons.clock, 'Plant Age', widget.plantAge!),
            _infoTile(LucideIcons.user, 'Owner', widget.ownerName),
            _infoTile(LucideIcons.hash, 'ID', widget.uniqueCode),

            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),

            // DB Status
            if (_isChecking)
              Row(
                children: [
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Checking database...',
                    style: GoogleFonts.poppins(
                        fontSize: 13, color: cs.onSurface.withOpacity(0.6)),
                  ),
                ],
              )
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
                    Row(
                      children: [
                        Icon(LucideIcons.checkCircle,
                            size: 20, color: Colors.green.shade700),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Plant added to your garden!',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.green.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_capturedImagePath != null) ...[
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          java.File(_capturedImagePath!),
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
                child: Row(
                  children: [
                    Icon(LucideIcons.checkCircle,
                        size: 20, color: Colors.green.shade700),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Plant found in database! Ready to plant.',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.green.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade300),
                ),
                child: Row(
                  children: [
                    Icon(LucideIcons.alertCircle,
                        size: 20, color: Colors.orange.shade700),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'QR code not found in database.',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.orange.shade800,
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
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(LucideIcons.sprout),
              label: Text(
                _isPlanting ? 'Planting...' : '🌱 Plant Now?',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        TextButton(
          onPressed: () {
            Navigator.pop(context); // Close dialog
            Navigator.pop(context); // Close scanner
          },
          child: Text(
            _planted ? 'Done' : 'Close',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
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
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: cs.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// Community Plant QR Dialog — scans admin-generated QR codes.
/// When the user plants the QR plant, they are auto-added to the community.
/// ═══════════════════════════════════════════════════════════════════════════
class _CommunityQRDialog extends StatefulWidget {
  final String communityId;
  final String qrId;
  final String plantName;
  final String plantType;
  final String bestSeason;
  final bool isSeed;
  final String? plantAge;

  const _CommunityQRDialog({
    required this.communityId,
    required this.qrId,
    required this.plantName,
    required this.plantType,
    required this.bestSeason,
    required this.isSeed,
    this.plantAge,
  });

  @override
  State<_CommunityQRDialog> createState() => _CommunityQRDialogState();
}

class _CommunityQRDialogState extends State<_CommunityQRDialog> {
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
      // Fetch community details
      final community = await _db.getCommunity(widget.communityId);
      final name = community?.name ?? widget.communityId;

      // Check if user already belongs to this community
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
      try {
        final fileId = await _db.uploadPlantImage(photo.path);
        imageUrl = _db.getPlantImageUrl(fileId);
      } catch (e) {
        debugPrint('Image upload failed: $e');
      }

      // 4. Create plant record in Appwrite
      final auth = Provider.of<AuthController>(context, listen: false);
      final userId = auth.userId ?? '';
      try {
        await _db.createPlant(
          species: widget.plantName,
          guardianId: userId,
          lat: lat,
          lng: lng,
          imageUrl: imageUrl ?? photo.path,
          nickname: widget.plantType,
          plantId: widget.qrId,
        );
      } catch (e) {
        debugPrint('Plant creation failed: $e');
      }

      // 5. Create activity log
      try {
        String? proofId;
        try {
          proofId = await _db.uploadPlantImage(photo.path);
        } catch (_) {}
        await _db.createActivityLog(
          userId: userId,
          plantId: widget.qrId,
          actionType: 'register',
          coinsAwarded: 10,
          verificationStatus: 'verified',
          proofImageId: proofId ?? '',
        );
      } catch (e) {
        debugPrint('Activity log failed: $e');
      }

      // 6. Auto-join community if not already a member
      String joinMsg = '';
      if (!_alreadyMember && userId.isNotEmpty) {
        try {
          await _db.addCommunityMember(
            communityId: widget.communityId,
            userId: userId,
            role: 'member',
          );
          await _db.incrementCommunityMemberCount(widget.communityId);
          joinMsg = 'You have been added to $_communityName!';
          _alreadyMember = true;
        } catch (e) {
          debugPrint('Auto-join failed: $e');
          joinMsg = 'Planted successfully, but could not join community.';
        }
      } else if (_alreadyMember) {
        joinMsg = 'Plant registered in $_communityName.';
      }

      // 7. Add community to the Community tab (not My Garden)
      final communityCtrl =
          Provider.of<CommunityController>(context, listen: false);
      try {
        final freshCommunity = await _db.getCommunity(widget.communityId);
        if (freshCommunity != null) {
          communityCtrl.addCommunityLocally(freshCommunity);
        }
      } catch (_) {}

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
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        TextButton(
          onPressed: () {
            Navigator.pop(context); // Close dialog
            Navigator.pop(context); // Close scanner
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
