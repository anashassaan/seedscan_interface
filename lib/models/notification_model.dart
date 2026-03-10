// lib/models/notification_model.dart
/// Matches Appwrite collection: `notifications`

class NotificationModel {
  final String id;
  final String recipientId;
  final String? senderId;
  final String type; // like, comment, invite, watering, system
  final String title;
  final String body;
  final String? linkedPostId;
  final String? linkedCommunityId;
  final String? linkedPlantId;
  final String? plantName;
  final String? plantLocation;
  final String scheduleFrequency; // none, daily, weekly, monthly, custom
  final int? customIntervalDays;
  final DateTime? nextScheduledAt;
  final bool isRecurring;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.recipientId,
    this.senderId,
    required this.type,
    required this.title,
    required this.body,
    this.linkedPostId,
    this.linkedCommunityId,
    this.linkedPlantId,
    this.plantName,
    this.plantLocation,
    this.scheduleFrequency = 'none',
    this.customIntervalDays,
    this.nextScheduledAt,
    this.isRecurring = false,
    this.isRead = false,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['\$id'] ?? json['id'] ?? '',
      recipientId: json['recipient_id'] ?? '',
      senderId: json['sender_id'],
      type: json['type'] ?? 'system',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      linkedPostId: json['linked_post_id'],
      linkedCommunityId: json['linked_community_id'],
      linkedPlantId: json['linked_plant_id'],
      plantName: json['plant_name'],
      plantLocation: json['plant_location'],
      scheduleFrequency: json['schedule_frequency'] ?? 'none',
      customIntervalDays: json['custom_interval_days'],
      nextScheduledAt: json['next_scheduled_at'] != null
          ? DateTime.tryParse(json['next_scheduled_at'].toString())
          : null,
      isRecurring: json['is_recurring'] ?? false,
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.tryParse(
            json['created_at'] ?? json['\$createdAt'] ?? '',
          ) ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'recipient_id': recipientId,
      'sender_id': senderId,
      'type': type,
      'title': title,
      'body': body,
      'linked_post_id': linkedPostId,
      'linked_community_id': linkedCommunityId,
      'linked_plant_id': linkedPlantId,
      'plant_name': plantName,
      'plant_location': plantLocation,
      'schedule_frequency': scheduleFrequency,
      'custom_interval_days': customIntervalDays,
      'next_scheduled_at': nextScheduledAt?.toIso8601String(),
      'is_recurring': isRecurring,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }

  NotificationModel copyWith({
    String? id,
    String? recipientId,
    String? senderId,
    String? type,
    String? title,
    String? body,
    String? linkedPostId,
    String? linkedCommunityId,
    String? linkedPlantId,
    String? plantName,
    String? plantLocation,
    String? scheduleFrequency,
    int? customIntervalDays,
    DateTime? nextScheduledAt,
    bool? isRecurring,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      recipientId: recipientId ?? this.recipientId,
      senderId: senderId ?? this.senderId,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      linkedPostId: linkedPostId ?? this.linkedPostId,
      linkedCommunityId: linkedCommunityId ?? this.linkedCommunityId,
      linkedPlantId: linkedPlantId ?? this.linkedPlantId,
      plantName: plantName ?? this.plantName,
      plantLocation: plantLocation ?? this.plantLocation,
      scheduleFrequency: scheduleFrequency ?? this.scheduleFrequency,
      customIntervalDays: customIntervalDays ?? this.customIntervalDays,
      nextScheduledAt: nextScheduledAt ?? this.nextScheduledAt,
      isRecurring: isRecurring ?? this.isRecurring,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
