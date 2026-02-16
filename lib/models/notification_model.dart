// lib/models/notification_model.dart

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final DateTime scheduledAt;
  final DateTime? sentAt;
  final String? targetAudience; // 'all', 'community:id', 'user:id'
  final int recipientCount;
  final NotificationStatus status;
  final Map<String, dynamic>? data; // Additional notification data

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.scheduledAt,
    this.sentAt,
    this.targetAudience,
    this.recipientCount = 0,
    this.status = NotificationStatus.pending,
    this.data,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['\$id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => NotificationType.custom,
      ),
      scheduledAt: DateTime.parse(
          json['scheduledAt'] ?? DateTime.now().toIso8601String()),
      sentAt: json['sentAt'] != null ? DateTime.parse(json['sentAt']) : null,
      targetAudience: json['targetAudience'],
      recipientCount: json['recipientCount'] ?? 0,
      status: NotificationStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => NotificationStatus.pending,
      ),
      data: json['data'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type.toString().split('.').last,
      'scheduledAt': scheduledAt.toIso8601String(),
      'sentAt': sentAt?.toIso8601String(),
      'targetAudience': targetAudience,
      'recipientCount': recipientCount,
      'status': status.toString().split('.').last,
      'data': data,
    };
  }
}

enum NotificationType {
  custom,
  autoWatering,
  autoFertilizing,
  autoHealthCheck,
  autoCommunity,
  autoReward,
}

enum NotificationStatus {
  pending,
  sent,
  failed,
  cancelled,
}
