// lib/views/home/watering_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../../controllers/notification_controller.dart';
import '../../controllers/wallet_controller.dart';
import '../../controllers/scan_controller.dart';

class WateringScreen extends StatefulWidget {
  const WateringScreen({super.key});

  @override
  State<WateringScreen> createState() => _WateringScreenState();
}

class _WateringScreenState extends State<WateringScreen> {
  final ImagePicker _picker = ImagePicker();
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _fetchInitialLocation();
  }

  Future<void> _fetchInitialLocation() async {
    try {
      final pos = await _getCurrentLocation(context);
      if (mounted && pos != null) {
        setState(() {
          _currentPosition = pos;
        });
      }
    } catch (e) {
      debugPrint("Could not fetch location for distance: $e");
    }
  }

  String _getDistanceText(NotificationModel notification) {
    if (_currentPosition == null) {
      if (notification.location.isNotEmpty) return notification.location;
      return 'GPS Location Available';
    }

    if (notification.latitude == 0.0 && notification.longitude == 0.0) {
      return notification.location.isNotEmpty
          ? notification.location
          : 'Location Unavailable';
    }

    final distanceInMeters = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      notification.latitude,
      notification.longitude,
    );

    if (distanceInMeters < 1000) {
      return '${distanceInMeters.toStringAsFixed(0)} m away';
    } else {
      return '${(distanceInMeters / 1000).toStringAsFixed(1)} km away';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final notificationController = Provider.of<NotificationController>(context);
    final walletController =
        Provider.of<WalletController>(context, listen: false);

    // Filter notifications for watering type
    final wateringNotifications = notificationController.notifications
        .where((n) => n.type == NotificationType.watering)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Watering Schedule',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        actions: [
          if (wateringNotifications.isNotEmpty)
            TextButton.icon(
              onPressed: () {
                // Mark all watering notifications as read and award points
                final count =
                    wateringNotifications.where((n) => !n.isRead).length;
                for (var notification in wateringNotifications) {
                  notificationController.markAsRead(notification.id);
                }
                // Award points for completing tasks
                final pointsEarned = count * 50;
                if (pointsEarned > 0) {
                  walletController.earnPoints(
                    pointsEarned,
                    'Completed $count watering task${count > 1 ? 's' : ''}',
                  );
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'All tasks complete! +$pointsEarned points earned 🎉'),
                    duration: const Duration(seconds: 2),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              icon: const Icon(LucideIcons.checkCheck, size: 18),
              label: const Text('Complete All'),
            ),
        ],
      ),
      body: wateringNotifications.isEmpty
          ? _buildEmptyState(context, cs)
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: wateringNotifications.length,
              itemBuilder: (context, index) {
                final notification = wateringNotifications[index];
                return _buildWateringCard(
                  context,
                  notification,
                  notificationController,
                  cs,
                  isDark,
                );
              },
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ColorScheme cs) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: cs.primaryContainer.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              LucideIcons.droplet,
              size: 64,
              color: cs.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Plants Need Watering',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'All your plants are well hydrated!',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: cs.onSurface.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildWateringCard(
    BuildContext context,
    NotificationModel notification,
    NotificationController controller,
    ColorScheme cs,
    bool isDark,
  ) {
    final isOverdue = notification.timestamp.isBefore(
      DateTime.now().subtract(const Duration(hours: 24)),
    );

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isOverdue
              ? Colors.red.withOpacity(0.3)
              : cs.outline.withOpacity(0.2),
          width: isOverdue ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    LucideIcons.droplet,
                    color: Colors.blue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.plantName,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            LucideIcons.clock,
                            size: 14,
                            color: isOverdue
                                ? Colors.red
                                : cs.onSurface.withOpacity(0.6),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatTime(notification.timestamp),
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: isOverdue
                                  ? Colors.red
                                  : cs.onSurface.withOpacity(0.6),
                              fontWeight: isOverdue
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(LucideIcons.moreVertical),
                  onSelected: (value) {
                    if (value == 'mark') {
                      controller.markAsRead(notification.id);
                    } else if (value == 'delete') {
                      controller.removeNotification(notification.id);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'mark',
                      child: Row(
                        children: [
                          Icon(
                            notification.isRead
                                ? LucideIcons.mailOpen
                                : LucideIcons.mail,
                            size: 18,
                            color: cs.onSurface,
                          ),
                          const SizedBox(width: 12),
                          Text(notification.isRead
                              ? 'Mark as unread'
                              : 'Mark as read'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.trash2,
                            size: 18,
                            color: Colors.red,
                          ),
                          const SizedBox(width: 12),
                          const Text('Delete',
                              style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Message
            Text(
              notification.message,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: cs.onSurface.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 8),

            // Location Info & Navigation
            if (notification.location.isNotEmpty ||
                (notification.latitude != 0.0 && notification.longitude != 0.0))
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(LucideIcons.mapPin, size: 18, color: cs.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _getDistanceText(notification),
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                    if (notification.latitude != 0.0 &&
                        notification.longitude != 0.0)
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          backgroundColor: cs.primaryContainer,
                          minimumSize: Size.zero,
                        ),
                        onPressed: () => _openMap(
                            context,
                            notification.latitude,
                            notification.longitude,
                            notification.plantName),
                        icon: Icon(LucideIcons.navigation,
                            size: 14, color: cs.primary),
                        label: Text('Navigate',
                            style: TextStyle(
                                color: cs.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
              ),

            if (!notification.isRead) ...[
              if (notification.location.isEmpty && notification.latitude == 0.0)
                const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: () => _showTaskVerificationDialog(
                      context,
                      notification,
                      controller,
                    ),
                    icon: Icon(
                      notification.isRead
                          ? LucideIcons.checkCircle2
                          : LucideIcons.circle,
                      color: notification.isRead ? Colors.green : cs.outline,
                    ),
                    tooltip: 'Complete Task',
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),

            // Message
            Text(
              notification.message,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: cs.onSurface.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 12),

            // Location
            InkWell(
              onTap: () => _openMap(
                context,
                notification.latitude,
                notification.longitude,
                notification.plantName,
              ),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[850] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.mapPin,
                      size: 16,
                      color: cs.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        notification.location,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: cs.onSurface.withOpacity(0.8),
                        ),
                      ),
                    ),
                    Icon(
                      LucideIcons.externalLink,
                      size: 16,
                      color: cs.primary,
                    ),
                  ],
                ),
              ),
            ),

            // Watering tips
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.blue.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    LucideIcons.lightbulb,
                    size: 16,
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Water until soil is moist, avoid overwatering',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showTaskVerificationDialog(
    BuildContext context,
    NotificationModel notification,
    NotificationController controller,
  ) async {
    if (notification.isRead) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task already completed'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final cs = Theme.of(context).colorScheme;
    final scanController = Provider.of<ScanController>(context, listen: false);

    // Find the plant associated with this notification
    final plant = scanController
        .getMyPlants()
        .firstWhere((p) => p.name == notification.plantName, orElse: () {
      return scanController.getMyPlants().first; // Fallback
    });

    String? capturedImagePath;
    Position? currentPosition;
    bool isLocationVerified = false;
    bool isPhotoTaken = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(LucideIcons.clipboardCheck, color: cs.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Complete Task',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Task info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.plantName,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.message,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: cs.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Requirements Section
                Text(
                  'Requirements for +50 points:',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: cs.primary,
                  ),
                ),
                const SizedBox(height: 12),

                // Location Verification
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isLocationVerified
                        ? Colors.green.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isLocationVerified ? Colors.green : Colors.grey,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isLocationVerified
                            ? LucideIcons.checkCircle2
                            : LucideIcons.mapPin,
                        color: isLocationVerified ? Colors.green : Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '1. Location Match',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (currentPosition != null)
                              Text(
                                isLocationVerified
                                    ? 'Location verified ✓'
                                    : 'Location: ${currentPosition!.latitude.toStringAsFixed(4)}, ${currentPosition!.longitude.toStringAsFixed(4)}',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: cs.onSurface.withOpacity(0.6),
                                ),
                              )
                            else
                              Text(
                                'Click to verify location',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: cs.onSurface.withOpacity(0.6),
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (!isLocationVerified)
                        TextButton(
                          onPressed: () async {
                            try {
                              final position =
                                  await _getCurrentLocation(context);
                              if (position != null) {
                                final distance = _calculateDistance(
                                  position.latitude,
                                  position.longitude,
                                  plant.latitude ?? notification.latitude,
                                  plant.longitude ?? notification.longitude,
                                );

                                setDialogState(() {
                                  currentPosition = position;
                                  // Allow up to 100 meters tolerance
                                  isLocationVerified = distance <= 100;
                                });

                                if (!isLocationVerified) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'You are ${distance.toStringAsFixed(0)}m away from the plant. Please get closer (within 100m).',
                                      ),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                }
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error getting location: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          child: const Text('Verify'),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Photo Requirement
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isPhotoTaken
                        ? Colors.green.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isPhotoTaken ? Colors.green : Colors.grey,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isPhotoTaken
                                ? LucideIcons.checkCircle2
                                : LucideIcons.camera,
                            color: isPhotoTaken ? Colors.green : Colors.grey,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '2. Take Photo',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (capturedImagePath != null) ...[
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(capturedImagePath!),
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],
                      if (!isPhotoTaken) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  final image = await _picker.pickImage(
                                    source: ImageSource.camera,
                                  );
                                  if (image != null) {
                                    setDialogState(() {
                                      capturedImagePath = image.path;
                                      isPhotoTaken = true;
                                    });
                                  }
                                },
                                icon: const Icon(LucideIcons.camera, size: 16),
                                label: const Text('Camera'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  final image = await _picker.pickImage(
                                    source: ImageSource.gallery,
                                  );
                                  if (image != null) {
                                    setDialogState(() {
                                      capturedImagePath = image.path;
                                      isPhotoTaken = true;
                                    });
                                  }
                                },
                                icon: const Icon(LucideIcons.image, size: 16),
                                label: const Text('Gallery'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Caution Message
                if (!isLocationVerified || !isPhotoTaken)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.orange.withOpacity(0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          LucideIcons.alertTriangle,
                          color: Colors.orange,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Complete both requirements to earn +50 points',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.orange.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            // Skip button (no points)
            TextButton.icon(
              onPressed: () {
                controller.markAsRead(notification.id);
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text('${notification.plantName} task marked as done'),
                    backgroundColor: Colors.grey,
                  ),
                );
              },
              icon: const Icon(LucideIcons.skipForward, size: 16),
              label: const Text('Skip (No Points)'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey,
              ),
            ),
            // Complete button (with points)
            ElevatedButton.icon(
              onPressed: (isLocationVerified && isPhotoTaken)
                  ? () {
                      controller.markAsRead(notification.id);
                      final wallet = Provider.of<WalletController>(
                        context,
                        listen: false,
                      );
                      wallet.earnPoints(
                          50, 'Watered ${notification.plantName}');
                      Navigator.of(dialogContext).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '${notification.plantName} watered! +50 points 💧',
                          ),
                          duration: const Duration(seconds: 2),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  : null,
              icon: const Icon(LucideIcons.checkCircle2, size: 16),
              label: const Text('Complete (+50 pts)'),
            ),
          ],
        ),
      ),
    );
  }

  Future<Position?> _getCurrentLocation(BuildContext context) async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location services are disabled'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permission denied'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permission permanently denied'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }

    return await Geolocator.getCurrentPosition();
  }

  double _calculateDistance(
    double lat1,
    double lon1,
    double? lat2,
    double? lon2,
  ) {
    if (lat2 == null || lon2 == null) {
      return double.infinity; // Cannot verify without plant location
    }
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  Future<void> _openMap(
    BuildContext context,
    double latitude,
    double longitude,
    String plantName,
  ) async {
    final geoUrl =
        'geo:$latitude,$longitude?q=$latitude,$longitude($plantName)';
    final googleMapsUrl =
        'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
    final appleMapsUrl = 'https://maps.apple.com/?q=$latitude,$longitude';

    try {
      if (await canLaunchUrl(Uri.parse(geoUrl))) {
        await launchUrl(Uri.parse(geoUrl));
      } else if (await canLaunchUrl(Uri.parse(googleMapsUrl))) {
        await launchUrl(Uri.parse(googleMapsUrl),
            mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(Uri.parse(appleMapsUrl))) {
        await launchUrl(Uri.parse(appleMapsUrl),
            mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open map')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening map: $e')),
        );
      }
    }
  }
}
