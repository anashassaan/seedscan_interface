import 'dart:io';
import 'dart:convert';
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
import '../../controllers/auth_controller.dart';
import '../../../services/database_service.dart';

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

    // Filter notifications for watering type and within 72 hours (do not filter out read ones until completed)
    final wateringNotifications = notificationController.notifications
        .where((n) {
          if (n.type != NotificationType.watering) return false;
          if (n.isRead) return false; // Hide if already marked as read/done
          if (DateTime.now().difference(n.timestamp).inHours > 72) return false;
          return true;
        }).toList();

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
                  notificationController.removeNotification(notification.id);
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
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.trash2,
                            size: 18,
                            color: Colors.red,
                          ),
                          SizedBox(width: 12),
                          Text('Delete',
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

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FilledButton.icon(
                  onPressed: () => _showTaskVerificationDialog(
                    context,
                    notification,
                    controller,
                  ),
                  icon: const Icon(LucideIcons.droplets, size: 18),
                  label: const Text('Complete Task'),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Watering tips
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


    final cs = Theme.of(context).colorScheme;
    final scanController = Provider.of<ScanController>(context, listen: false);

    // ── Safe plant lookup — never throws ──────────────────────────────────────
    // If no plant matches the name (empty garden, name mismatch) we continue
    // with null and fall back to the notification's own coordinates.
    final plants = scanController.getMyPlants();
    final plant = plants.isEmpty
        ? null
        : plants.cast<dynamic>().firstWhere(
              (p) => p.name == notification.plantName,
              orElse: () => null,
            );

    // Resolve the plant's Appwrite document ID for the activity log.
    // If the plant is not found locally, we pass the notification's plantName
    // as a best-effort ID — the admin tier-2 scan will still find it via
    // the rejectionReason metadata.
    final plantId = (plant != null && (plant.id as String).isNotEmpty)
        ? plant.id as String
        : notification.plantName;

    // Coordinates for the 2-metre proximity check.
    final double targetLat = (plant?.latitude as double?) ?? notification.latitude;
    final double targetLng = (plant?.longitude as double?) ?? notification.longitude;

    String? capturedImagePath;
    Position? currentPosition;
    bool isLocationVerified = false;
    bool isPhotoTaken = false;
    bool isSubmitting = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
          actionsOverflowDirection: VerticalDirection.down,
          actionsOverflowButtonSpacing: 8,
          title: Row(
            children: [
              Icon(LucideIcons.clipboardCheck, color: cs.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Complete Watering Task',
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
                // ── Task info banner ────────────────────────────────────────
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

                // ── Earn-coins requirement heading ──────────────────────────
                Row(
                  children: [
                    const Icon(LucideIcons.coins,
                        size: 16, color: Colors.amber),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Complete both steps to earn +5 coins:',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: cs.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ── Step 1 — Location Verification (2-metre radius) ─────────
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isLocationVerified
                        ? Colors.green.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          isLocationVerified ? Colors.green : Colors.grey.shade300,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        isLocationVerified
                            ? LucideIcons.checkCircle2
                            : LucideIcons.mapPin,
                        color:
                            isLocationVerified ? Colors.green : Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '1. Location Match (within 2 m)',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isLocationVerified
                                  ? '✓ You are at the plant location'
                                  : currentPosition != null
                                      ? 'Too far — must be within 2 m of the plant'
                                      : 'Tap Verify to check your location',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: isLocationVerified
                                    ? Colors.green.shade700
                                    : cs.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!isLocationVerified)
                        TextButton(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                          ),
                          onPressed: () async {
                            try {
                              final position =
                                  await _getCurrentLocation(ctx);
                              if (position == null) return;

                              final distanceM = Geolocator.distanceBetween(
                                position.latitude,
                                position.longitude,
                                targetLat,
                                targetLng,
                              );

                              setDialogState(() {
                                currentPosition = position;
                                // 2-metre radius as requested.
                                // If the plant has no GPS (both 0,0) we
                                // allow verification automatically.
                                isLocationVerified = (targetLat == 0.0 &&
                                        targetLng == 0.0) ||
                                    distanceM <= 2.0;
                              });

                              if (!isLocationVerified && ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'You are ${distanceM.toStringAsFixed(1)} m away. '
                                      'Must be within 2 m to earn coins.',
                                    ),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(
                                    content:
                                        Text('Location error: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                          child: Text('Verify',
                              style: TextStyle(color: cs.primary)),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ── Step 2 — Photo Proof ────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isPhotoTaken
                        ? Colors.green.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isPhotoTaken
                          ? Colors.green
                          : Colors.grey.shade300,
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
                              '2. Photo Proof',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
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
                            height: 140,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  final img = await _picker.pickImage(
                                      source: ImageSource.camera);
                                  if (img != null) {
                                    setDialogState(() {
                                      capturedImagePath = img.path;
                                      isPhotoTaken = true;
                                    });
                                  }
                                },
                                icon: const Icon(LucideIcons.camera,
                                    size: 16),
                                label: const Text('Camera'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  final img = await _picker.pickImage(
                                      source: ImageSource.gallery);
                                  if (img != null) {
                                    setDialogState(() {
                                      capturedImagePath = img.path;
                                      isPhotoTaken = true;
                                    });
                                  }
                                },
                                icon: const Icon(LucideIcons.image,
                                    size: 16),
                                label: const Text('Gallery'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // ── Info banner ─────────────────────────────────────────────
                if (!isLocationVerified || !isPhotoTaken) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(10),
                      border:
                          Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.info,
                            color: Colors.blue, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isPhotoTaken && !isLocationVerified
                                ? 'Location not verified — you can still mark the task done without coins.'
                                : 'Both location (2 m) and photo required to earn +5 coins.',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.blue.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            // ── Cancel ──────────────────────────────────────────────────────
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child:
                  Text('Cancel', style: TextStyle(color: Colors.grey.shade600)),
            ),

            // ── Complete without coins (shown when photo taken but no location) ──
            if (isPhotoTaken && !isLocationVerified)
              TextButton.icon(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        setDialogState(() => isSubmitting = true);
                        await _submitWateringTask(
                          context: ctx,
                          dialogContext: dialogContext,
                          notification: notification,
                          controller: controller,
                          plantId: plantId,
                          capturedImagePath: capturedImagePath,
                          awardCoins: false,
                        );
                      },
                icon: const Icon(LucideIcons.checkCircle, size: 16),
                label: const Text('Complete Task (No Coins)'),
                style: TextButton.styleFrom(foregroundColor: Colors.grey),
              ),

            // ── Complete with +5 coins ───────────────────────────────────────
            ElevatedButton.icon(
              onPressed: (isLocationVerified && isPhotoTaken && !isSubmitting)
                  ? () async {
                      setDialogState(() => isSubmitting = true);
                      await _submitWateringTask(
                        context: ctx,
                        dialogContext: dialogContext,
                        notification: notification,
                        controller: controller,
                        plantId: plantId,
                        capturedImagePath: capturedImagePath,
                        awardCoins: true,
                      );
                    }
                  : null,
              icon: isSubmitting
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(LucideIcons.checkCircle2, size: 16),
              label: const Text('Complete (+5 coins)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Handles the shared submission logic for both coin and no-coin paths:
  ///  1. Uploads proof photo to Appwrite Storage
  ///  2. Writes activity_log with actionType='water' (valid enum) so the
  ///     admin panel Plant History shows the watering image on its timeline
  ///  3. Awards 5 coins if [awardCoins] is true
  ///  4. Marks notification as read
  Future<void> _submitWateringTask({
    required BuildContext context,
    required BuildContext dialogContext,
    required NotificationModel notification,
    required NotificationController controller,
    required String plantId,
    required String? capturedImagePath,
    required bool awardCoins,
  }) async {
    final db = DatabaseService();
    String proofImageUrl = '';

    // ── Upload proof photo (best-effort) ─────────────────────────────────────
    if (capturedImagePath != null) {
      try {
        final fileId = await db.uploadPlantImage(capturedImagePath);
        proofImageUrl = db.getPlantImageUrl(fileId);
      } catch (e) {
        debugPrint('WateringScreen: photo upload failed: $e');
        // Non-fatal — continue without image URL
      }
    }

    // ── Write activity_log for admin panel history ────────────────────────────
    // actionType = 'water' (valid Appwrite enum).
    // The admin plant history detects watering entries via the
    // rejectionReason meta field type='watering_proof_meta'.
    try {
      if (context.mounted) {
        final auth = Provider.of<AuthController>(context, listen: false);
        final userId = auth.userId ?? '';
        final nowIso = DateTime.now().toIso8601String();

        final historyPlantId = await db.resolveCanonicalPlantId(
          userId: userId,
          localGardenId: plantId,
          speciesName: notification.plantName,
        );

        final historyMeta = {
          'type': 'watering_proof_meta',
          'watered_at': nowIso,
          'plant_name': notification.plantName,
          'coins_awarded': awardCoins ? 5 : 0,
          'source_plant_id': plantId,
          'resolved_plant_id': historyPlantId,
        };

        await db.createActivityLog(
          userId: userId,
          plantId: historyPlantId,
          communityId: notification.linkedCommunityId,
          actionType: 'water',
          coinsAwarded: awardCoins ? 5 : 0,
          verificationStatus: 'verified',
          proofImageId: proofImageUrl,
          rejectionReason: jsonEncode(historyMeta),
        );
      }
    } catch (e) {
      debugPrint('WateringScreen: createActivityLog failed: $e');
      // Non-fatal — task is still completed for the user
    }

    // ── Award coins ──────────────────────────────────────────────────────────
    if (awardCoins && context.mounted) {
      final wallet = Provider.of<WalletController>(context, listen: false);
      wallet.earnPoints(5, 'Watered ${notification.plantName}');
    }

    // ── Remove notification perfectly ────────────────────────────────────────────
    controller.removeNotification(notification.id);

    // ── Close dialog and show result ─────────────────────────────────────────
    if (dialogContext.mounted) Navigator.of(dialogContext).pop();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            awardCoins
                ? '${notification.plantName} watered! +5 coins earned 💧🌱'
                : '${notification.plantName} marked as watered (no coins)',
          ),
          backgroundColor: awardCoins ? Colors.green : Colors.grey.shade700,
          duration: const Duration(seconds: 3),
        ),
      );
    }
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
