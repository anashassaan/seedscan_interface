import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:geolocator/geolocator.dart';
import '../../controllers/scan_controller.dart';
import '../../controllers/chat_controller.dart';
import '../../controllers/community_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../../models/community_model.dart';
import '../../../services/database_service.dart';
import 'dart:async';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../../services/leaf_diagnosis_service.dart';
import 'custom_camera_screen.dart';

class UnifiedScanScreen extends StatefulWidget {
  const UnifiedScanScreen({super.key});

  @override
  State<UnifiedScanScreen> createState() => _UnifiedScanScreenState();
}

class _UnifiedScanScreenState extends State<UnifiedScanScreen>
    with TickerProviderStateMixin {
  // Enhanced service with optimized parameters for reliable detection
  final diagnosisService = LeafDiagnosisService(
    detectionThreshold: 0.25, // Balanced threshold (25%)
    fallbackDetectionThreshold: 0.15, // Lower fallback for challenging images
    enablePreprocessing: true, // Gamma correction + color enhancement
    interpreterThreads: 4, // Multi-threading for faster inference
    minBoxAreaFraction: 0.002, // Allow smaller leaf detections
    maxBoxAreaFraction: 0.95, // Allow larger detections
  );

  // State variables - PRESERVED for backend integration
  String? classificationResult;
  String? diseaseName;
  int? severityLevel;
  double? confidenceLevel;
  bool isLoading = false;
  bool modelsLoaded = false;
  String? modelLoadError;

  // Real-time CV feedback for optimal capture
  String cvFeedback = "Position leaf in center of frame";
  late AnimationController _scanAnimationController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _loadModels();
    _scanAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scanAnimationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadModels() async {
    if (modelsLoaded) return;

    setState(() {
      modelLoadError = null;
    });

    try {
      await diagnosisService.loadModels().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Model loading timed out');
        },
      );

      if (mounted) {
        setState(() {
          modelsLoaded = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          modelLoadError = 'Failed to load models: $e';
        });
      }
    }
  }

  // CUSTOM CAMERA WITH CV FEEDBACK
  Future<void> _showImageSourceSheet() async {
    await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Select Image Source',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose how to capture your plant leaf',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            // Camera Option with CV Feedback
            _buildSourceOption(
              icon: Icons.camera_alt,
              label: 'Take Photo',
              subtitle: 'Use camera for instant capture',
              onTap: () async {
                Navigator.pop(context);
                // Open custom camera with real-time feedback
                final imagePath = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CustomCameraScreen(
                      onCapture: (path) => Navigator.pop(context, path),
                    ),
                  ),
                );
                if (imagePath != null && imagePath is String) {
                  _processImage(File(imagePath));
                }
              },
            ),
            const SizedBox(height: 16),
            // Gallery Option
            _buildSourceOption(
              icon: Icons.photo_library,
              label: 'Choose from Gallery',
              subtitle: 'Pick from your saved images',
              onTap: () {
                Navigator.pop(context);
                _captureDiseaseImage(ImageSource.gallery);
              },
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.05),
          ],
        ),
      ),
    );
  }

  // Process captured/selected image
  Future<void> _processImage(File imageFile) async {
    setState(() {
      isLoading = true;
      classificationResult = null;
      diseaseName = null;
      severityLevel = null;
      confidenceLevel = null;
    });

    try {
      final result = await diagnosisService.predict(imageFile);

      if (mounted) {
        setState(() {
          classificationResult = result['result'];

          // If the pipeline determined this is NOT an apple leaf,
          // make sure we do NOT display disease/severity info.
          final bool noApple = (result['result'] == 'No Apple Leaf Detected') ||
              (result['disease'] == 'N/A');

          if (noApple) {
            diseaseName = 'N/A';
            confidenceLevel = 0.0;
            severityLevel = null; // null prevents severity UI from showing
          } else {
            diseaseName = result['disease'];
            confidenceLevel = result['confidence'];
            severityLevel = result['severity'];
          }

          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          classificationResult = 'Error: $e';
        });
      }
    }
  }

  Widget _buildSourceOption({
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  // PRESERVED LOGIC - Uses existing predict() function
  Future<void> _captureDiseaseImage(ImageSource source) async {
    if (!modelsLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Models are still loading...')),
      );
      return;
    }

    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);

    if (image == null) return;

    setState(() {
      isLoading = true;
      classificationResult = null;
      diseaseName = null;
      severityLevel = null;
      confidenceLevel = null;
    });

    try {
      // PRESERVED - calling existing model prediction
      final result = await diagnosisService.predict(File(image.path));

      if (mounted) {
        setState(() {
          classificationResult = result['result'];

          final bool noApple = (result['result'] == 'No Apple Leaf Detected') ||
              (result['disease'] == 'N/A');

          if (noApple) {
            diseaseName = 'N/A';
            confidenceLevel = 0.0;
            severityLevel = null;
          } else {
            diseaseName = result['disease'];
            confidenceLevel = result['confidence'];
            severityLevel = result['severity'];
          }

          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          classificationResult = 'Error: $e';
        });
      }
    }
  }

  // Helper function to get severity name
  String _getSeverityName(int level) {
    switch (level) {
      case 1:
        return 'Minimal';
      case 2:
        return 'Mild';
      case 3:
        return 'Moderate';
      case 4:
        return 'Severe';
      case 5:
        return 'Critical';
      default:
        return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    final scan = Provider.of<ScanController>(context);
    final cs = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: Navigator.canPop(context)
            ? Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              )
            : null,
        title: Text(
          scan.isQrMode ? 'QR Scanner' : 'Disease Detector',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Stack(
        children: [
          // CAMERA VIEW or GRADIENT BACKGROUND
          if (scan.isQrMode)
            _buildQRCameraView(scan)
          else
            _buildDiseaseBackground(cs),

          // Main Content Overlay
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),

                // MODERN MODE TOGGLE
                _buildModernModeToggle(scan, cs),

                const Spacer(),

                // CONTENT BASED ON MODE
                if (scan.isQrMode)
                  _buildQRScannerUI(screenWidth, screenHeight, cs)
                else
                  _buildDiseaseDetectionUI(screenWidth, screenHeight, cs),

                SizedBox(height: screenHeight * 0.05), // Thumb zone spacing
              ],
            ),
          ),

          // LOADING OVERLAY
          if (isLoading) _buildLoadingOverlay(cs),

          // RESULTS OVERLAY
          if (classificationResult != null && !isLoading)
            _buildResultsOverlay(cs, screenWidth, screenHeight),
        ],
      ),
    );
  }

  // MODERN QR SCANNER WITH TRANSLUCENT OVERLAY
  Widget _buildQRCameraView(ScanController scan) {
    return MobileScanner(
      controller: scan.cameraController,
      onDetect: (capture) async {
        final List<Barcode> barcodes = capture.barcodes;
        for (final barcode in barcodes) {
          if (barcode.rawValue != null) {
            final result = await scan.handleQr(barcode.rawValue!);
            if (result['success'] == true && mounted) {
              _handleQrCodeScanned(barcode.rawValue!, result);
            }
          }
        }
      },
    );
  }

  // Handle QR code — detect SEEDSCAN| community plant QR codes
  void _handleQrCodeScanned(String qrCode, Map<String, dynamic> scanResult) {
    // ── Community plant QR: SEEDSCAN|communityId|id|plantName|plantType|bestSeason|SEED/PLANT|plantAge|timestamp
    if (qrCode.startsWith('SEEDSCAN|')) {
      final parts = qrCode.split('|');
      if (parts.length >= 9) {
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
          builder: (_) => _UnifiedCommunityQRDialog(
            communityId: communityId,
            qrId: qrId,
            plantName: plantName,
            plantType: plantType,
            bestSeason: bestSeason,
            isSeed: isSeed,
            plantAge: plantAge,
          ),
        );
        return;
      }
    }

    // ── Regular / unknown QR code
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('QR Code: $qrCode'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildDiseaseBackground(ColorScheme cs) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primary, cs.primaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }

  // MODERN PILL-SHAPED MODE TOGGLE
  Widget _buildModernModeToggle(ScanController scan, ColorScheme cs) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildModeButton('QR Code', scan.isQrMode, scan.toggleMode, cs),
          _buildModeButton('Disease', !scan.isQrMode, scan.toggleMode, cs),
        ],
      ),
    );
  }

  Widget _buildModeButton(
      String label, bool isActive, VoidCallback onTap, ColorScheme cs) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? cs.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : cs.onSurface,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }

  // QR SCANNER UI WITH CUTOUT OVERLAY - CENTERED
  Widget _buildQRScannerUI(
      double screenWidth, double screenHeight, ColorScheme cs) {
    final scanSize = screenWidth * 0.7;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Scanning frame with corners - CENTERED
        Container(
          width: scanSize,
          height: scanSize,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Stack(
            children: [
              // Corner indicators
              ..._buildCornerIndicators(cs.primary),

              // Scanning line animation
              AnimatedBuilder(
                animation: _scanAnimationController,
                builder: (context, child) {
                  return Positioned(
                    top: scanSize * _scanAnimationController.value,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 2,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            cs.primary,
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 40),

        // Instruction card - CENTERED
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.qr_code_scanner, size: 40, color: cs.primary),
              const SizedBox(width: 16),
              const Text(
                'Point camera at QR code',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildCornerIndicators(Color color) {
    const cornerSize = 24.0;
    const thickness = 4.0;

    return [
      // Top-left
      Positioned(
        top: 0,
        left: 0,
        child: Container(
          width: cornerSize,
          height: cornerSize,
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: color, width: thickness),
              left: BorderSide(color: color, width: thickness),
            ),
          ),
        ),
      ),
      // Top-right
      Positioned(
        top: 0,
        right: 0,
        child: Container(
          width: cornerSize,
          height: cornerSize,
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: color, width: thickness),
              right: BorderSide(color: color, width: thickness),
            ),
          ),
        ),
      ),
      // Bottom-left
      Positioned(
        bottom: 0,
        left: 0,
        child: Container(
          width: cornerSize,
          height: cornerSize,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: color, width: thickness),
              left: BorderSide(color: color, width: thickness),
            ),
          ),
        ),
      ),
      // Bottom-right
      Positioned(
        bottom: 0,
        right: 0,
        child: Container(
          width: cornerSize,
          height: cornerSize,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: color, width: thickness),
              right: BorderSide(color: color, width: thickness),
            ),
          ),
        ),
      ),
    ];
  }

  // DISEASE DETECTION UI - DUAL INPUT IN THUMB ZONE
  Widget _buildDiseaseDetectionUI(
      double screenWidth, double screenHeight, ColorScheme cs) {
    if (modelLoadError != null) {
      return _buildErrorState(screenHeight);
    }

    if (!modelsLoaded) {
      return _buildLoadingState(cs);
    }

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1.0 + (_pulseController.value * 0.1),
                  child: Icon(
                    Icons.eco,
                    size: 60,
                    color: cs.primary,
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            const Text(
              'Plant Disease Detection',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Advanced AI analysis to identify plant diseases and assess severity',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),
            const SizedBox(height: 28),

            // DUAL INPUT BUTTON - Opens action sheet
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _showImageSourceSheet,
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.add_a_photo, size: 24),
                    SizedBox(width: 12),
                    Text(
                      'Start Diagnosis',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(double screenHeight) {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 50),
          const SizedBox(height: 16),
          Text(
            modelLoadError!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _loadModels,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(ColorScheme cs) {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: cs.primary),
          const SizedBox(height: 20),
          const Text(
            'Initializing AI models...',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            'This may take a moment',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay(ColorScheme cs) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: cs.primary),
              const SizedBox(height: 20),
              const Text(
                'Analyzing Plant Disease',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Our AI is examining the leaf for diseases',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultsOverlay(
      ColorScheme cs, double screenWidth, double screenHeight) {
    return Positioned.fill(
      child: Container(
        color: Colors.black54,
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(24),
            constraints: BoxConstraints(maxHeight: screenHeight * 0.7),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    diseaseName != 'N/A'
                        ? Icons.warning_amber_rounded
                        : Icons.check_circle,
                    size: 60,
                    color: diseaseName != 'N/A' ? Colors.orange : Colors.green,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    classificationResult!,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (diseaseName != null && diseaseName != 'N/A') ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Detected Disease',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            diseaseName!,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Text('Confidence: '),
                              Text(
                                '${((confidenceLevel ?? 0) * 100).toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: cs.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (severityLevel != null) ...[
                      const SizedBox(height: 20),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Severity Level',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          LinearProgressIndicator(
                            value: severityLevel! / 5,
                            backgroundColor: Colors.grey[200],
                            color: severityLevel! <= 2
                                ? Colors.green
                                : severityLevel! <= 3
                                    ? Colors.orange
                                    : Colors.red,
                            minHeight: 10,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _getSeverityName(severityLevel!),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: severityLevel! <= 2
                                  ? Colors.green
                                  : severityLevel! <= 3
                                      ? Colors.orange
                                      : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                  const SizedBox(height: 28),

                  // AI Consultation Button (only for diseases)
                  if (diseaseName != null && diseaseName != 'N/A')
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              // Prepare diagnosis report
                              final diagnosisReport =
                                  '🌿 Disease Diagnosis Report\n\n'
                                  '📋 Disease: $diseaseName\n'
                                  '⚠️ Severity: ${_getSeverityName(severityLevel ?? 0)}\n'
                                  '📊 Confidence: ${((confidenceLevel ?? 0) * 100).toStringAsFixed(1)}%\n\n'
                                  'Please provide treatment recommendations.';

                              // Send diagnosis to chat
                              final chatController =
                                  Provider.of<ChatController>(context,
                                      listen: false);
                              await chatController.sendText(diagnosisReport);

                              // Clear results to hide overlay
                              if (mounted) {
                                setState(() {
                                  classificationResult = null;
                                  diseaseName = null;
                                  severityLevel = null;
                                  confidenceLevel = null;
                                });

                                // Show success message
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        '✅ Diagnosis sent! Go to Chat tab to see AI response.'),
                                    duration: Duration(seconds: 4),
                                    backgroundColor: Color(0xFF00C853),
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00C853),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon:
                                const Icon(Icons.chat_bubble_outline, size: 20),
                            label: const Text(
                              'Consult SeedScan AI',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          classificationResult = null;
                          diseaseName = null;
                          severityLevel = null;
                          confidenceLevel = null;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cs.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Scan Another Leaf',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// Community Plant QR Dialog (Unified Scanner)
/// Auto-joins the user to the community when they plant the QR plant.
/// ═══════════════════════════════════════════════════════════════════════════
class _UnifiedCommunityQRDialog extends StatefulWidget {
  final String communityId;
  final String qrId;
  final String plantName;
  final String plantType;
  final String bestSeason;
  final bool isSeed;
  final String? plantAge;

  const _UnifiedCommunityQRDialog({
    required this.communityId,
    required this.qrId,
    required this.plantName,
    required this.plantType,
    required this.bestSeason,
    required this.isSeed,
    this.plantAge,
  });

  @override
  State<_UnifiedCommunityQRDialog> createState() =>
      _UnifiedCommunityQRDialogState();
}

class _UnifiedCommunityQRDialogState extends State<_UnifiedCommunityQRDialog> {
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
      final community = await _db.getCommunity(widget.communityId);
      final name = community?.name ?? widget.communityId;

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

      // 7. Add community to the Community tab
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
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
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
