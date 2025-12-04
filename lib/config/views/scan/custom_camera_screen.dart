import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

/// Custom Camera Screen with Real-Time CV Feedback
class CustomCameraScreen extends StatefulWidget {
  final Function(String) onCapture;

  const CustomCameraScreen({super.key, required this.onCapture});

  @override
  State<CustomCameraScreen> createState() => _CustomCameraScreenState();
}

class _CustomCameraScreenState extends State<CustomCameraScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  String feedback = "Position leaf in center";
  Color feedbackColor = Colors.orange;
  bool isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras!.isNotEmpty) {
        _controller = CameraController(
          _cameras![0],
          ResolutionPreset.high,
          enableAudio: false,
        );

        await _controller!.initialize();

        if (mounted) {
          setState(() {
            isInitialized = true;
          });
          _startCVFeedback();
        }
      }
    } catch (e) {
      debugPrint('Camera initialization error: $e');
    }
  }

  // Simulated CV Feedback (Real implementation would analyze camera frames)
  void _startCVFeedback() {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          feedback = "Hold steady for clear image";
          feedbackColor = Colors.green;
        });
      }
    });

    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          feedback = "Perfect! Tap to capture";
          feedbackColor = const Color(0xFF00C853);
        });
      }
    });
  }

  Future<void> _captureImage() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      final image = await _controller!.takePicture();
      widget.onCapture(image.path);
    } catch (e) {
      debugPrint('Capture error: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (!isInitialized || _controller == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Preview
          Positioned.fill(
            child: CameraPreview(_controller!),
          ),

          // Dark overlay with center cutout effect
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Container(
                  width: screenWidth * 0.8,
                  height: screenWidth * 0.8,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: feedbackColor,
                      width: 3,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
          ),

          // Top bar with feedback
          SafeArea(
            child: Column(
              children: [
                // Back button and title
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                      const Text(
                        'Capture Leaf',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // CV Feedback Banner
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: feedbackColor.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        feedback.contains("Perfect")
                            ? Icons.check_circle
                            : Icons.center_focus_strong,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        feedback,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Capture button
                Container(
                  margin: const EdgeInsets.only(bottom: 40),
                  child: Column(
                    children: [
                      // Instruction text
                      Text(
                        'Position leaf in frame',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Capture button
                      GestureDetector(
                        onTap: _captureImage,
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            border: Border.all(
                              color: feedback.contains("Perfect")
                                  ? const Color(0xFF00C853)
                                  : Colors.white,
                              width: 4,
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.camera_alt,
                              color: feedback.contains("Perfect")
                                  ? const Color(0xFF00C853)
                                  : Colors.grey[800],
                              size: 32,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
