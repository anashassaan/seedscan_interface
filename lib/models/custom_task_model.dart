class CustomTaskModel {
  final String id;
  final String title;
  final String description;
  final String category; // 'daily', 'weekly', 'monthly'
  final String priority; // 'low', 'medium', 'high'
  final int points;
  final String targetType; // 'all', 'community', 'disease', 'plant'
  final String? targetValue;
  final DateTime createdAt;

  CustomTaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.points,
    required this.targetType,
    this.targetValue,
    required this.createdAt,
  });

  factory CustomTaskModel.fromAppwrite(Map<String, dynamic> map) {
    return CustomTaskModel(
      id: map['\$id'] ?? '',
      title: map['title'] ?? 'Untitled Task',
      description: map['description'] ?? '',
      category: map['category'] ?? 'daily',
      priority: map['priority'] ?? 'medium',
      points: map['points'] ?? 10,
      targetType: map['target_type'] ?? 'all',
      targetValue: map['target_value'],
      createdAt: map['created_at'] != null 
          ? DateTime.tryParse(map['created_at']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'title': title,
      'description': description,
      'category': category,
      'priority': priority,
      'points': points,
      'target_type': targetType,
      'created_at': createdAt.toIso8601String(),
    };
    if (targetValue != null) {
      map['target_value'] = targetValue;
    }
    return map;
  }
}
