// lib/views/scan/scan_screen.dart
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  bool _isQrMode = true;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(_isQrMode ? 'QR Scanner' : 'Disease Detection'),
        actions: [
          Switch(
            value: _isQrMode,
            onChanged: (v) => setState(() => _isQrMode = v),
            activeColor: cs.primary,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera preview
          MobileScanner(
            onDetect: (capture) {},
          ),
          // Overlay: center square cutout and laser animation
          Center(
            child: SizedBox(
              width: 280,
              height: 280,
              child: Stack(
                children: [
                  // darkened overlay with cutout handled by container and inner square
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(color: Colors.black.withOpacity(0.35)),
                    ),
                  ),
                  Center(
                    child: Container(
                      width: 280,
                      height: 280,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.transparent,
                        border: Border.all(
                          color: cs.onBackground.withOpacity(0.14),
                          width: 1.5,
                        ),
                      ),
                      child: const _LaserAnimation(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Capture / analyze for disease mode
          if (!_isQrMode)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 36.0),
                child: ElevatedButton.icon(
                  onPressed: () async {
                    // simulate analyzing flow
                    showModalBottomSheet(
                      context: context,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      builder: (context) {
                        Future.delayed(
                          const Duration(seconds: 1, milliseconds: 300),
                          () {
                            // After "analysis" show result by rebuilding bottom sheet
                            if (mounted) {
                              Navigator.of(context).pop();
                              showModalBottomSheet(
                                context: context,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                builder: (_) => Padding(
                                  padding: const EdgeInsets.all(18.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Analysis Result',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleLarge,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Fungal Infection Detected — 92% confidence',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyMedium,
                                      ),
                                      const SizedBox(height: 14),
                                      ElevatedButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(),
                                        child: const Text('Close'),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }
                          },
                        );
                        return Padding(
                          padding: const EdgeInsets.all(18.0),
                          child: Row(
                            children: const [
                              CircularProgressIndicator(),
                              SizedBox(width: 16),
                              Text('Analyzing…'),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('Capture & Analyze'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LaserAnimation extends StatefulWidget {
  const _LaserAnimation();

  @override
  State<_LaserAnimation> createState() => _LaserAnimationState();
}

class _LaserAnimationState extends State<_LaserAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return Align(
          alignment: Alignment(0, (_ctrl.value * 2) - 1),
          child: Container(
            width: double.infinity,
            height: 2,
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
    );
  }
}
