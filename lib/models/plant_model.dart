// lib/models/plant_model.dart

class PlantModel {
  final String id;
  final String userId;
  final String qrCode;
  final String name;
  final String species;
  final String? imageUrl;
  final DateTime plantedDate;
  final String? location;
  final String? communityId;
  final int healthScore;
  final List<HealthCheck> healthChecks;
  final DateTime createdAt;

  PlantModel({
    required this.id,
    required this.userId,
    required this.qrCode,
    required this.name,
    required this.species,
    this.imageUrl,
    required this.plantedDate,
    this.location,
    this.communityId,
    this.healthScore = 100,
    this.healthChecks = const [],
    required this.createdAt,
  });

  factory PlantModel.fromJson(Map<String, dynamic> json) {
    return PlantModel(
      id: json['\$id'] ?? json['id'] ?? '',
      userId: json['userId'] ?? '',
      qrCode: json['qrCode'] ?? '',
      name: json['name'] ?? '',
      species: json['species'] ?? '',
      imageUrl: json['imageUrl'],
      plantedDate: DateTime.parse(
          json['plantedDate'] ?? DateTime.now().toIso8601String()),
      location: json['location'],
      communityId: json['communityId'],
      healthScore: json['healthScore'] ?? 100,
      healthChecks: (json['healthChecks'] as List<dynamic>?)
              ?.map((e) => HealthCheck.fromJson(e))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['createdAt'] ??
          json['\$createdAt'] ??
          DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'qrCode': qrCode,
      'name': name,
      'species': species,
      'imageUrl': imageUrl,
      'plantedDate': plantedDate.toIso8601String(),
      'location': location,
      'communityId': communityId,
      'healthScore': healthScore,
      'healthChecks': healthChecks.map((e) => e.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class HealthCheck {
  final DateTime date;
  final String status;
  final String? disease;
  final double confidence;
  final String? imageUrl;

  HealthCheck({
    required this.date,
    required this.status,
    this.disease,
    required this.confidence,
    this.imageUrl,
  });

  factory HealthCheck.fromJson(Map<String, dynamic> json) {
    return HealthCheck(
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      status: json['status'] ?? 'unknown',
      disease: json['disease'],
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      imageUrl: json['imageUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'status': status,
      'disease': disease,
      'confidence': confidence,
      'imageUrl': imageUrl,
    };
  }
}
