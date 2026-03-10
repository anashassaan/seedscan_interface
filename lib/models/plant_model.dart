// lib/models/plant_model.dart
/// Matches Appwrite collection: `plants`

class PlantModel {
  final String id;
  final String species;
  final String guardianId;
  final String? driveId;
  final String? nickname;
  final double locationLat;
  final double locationLong;
  final String healthStatus; // healthy, diseased, critical, dead
  final String imageUrl;
  final DateTime? lastWatered;
  final List<String> pHashHistory;

  PlantModel({
    required this.id,
    required this.species,
    required this.guardianId,
    this.driveId,
    this.nickname,
    required this.locationLat,
    required this.locationLong,
    this.healthStatus = 'healthy',
    required this.imageUrl,
    this.lastWatered,
    this.pHashHistory = const [],
  });

  factory PlantModel.fromJson(Map<String, dynamic> json) {
    return PlantModel(
      id: json['\$id'] ?? json['id'] ?? '',
      species: json['species'] ?? '',
      guardianId: json['guardian_id'] ?? '',
      driveId: json['drive_id'],
      nickname: json['nickname'],
      locationLat: (json['location_lat'] ?? 0.0).toDouble(),
      locationLong: (json['location_long'] ?? 0.0).toDouble(),
      healthStatus: json['health_status'] ?? 'healthy',
      imageUrl: json['image_url'] ?? '',
      lastWatered: json['last_watered'] != null
          ? DateTime.tryParse(json['last_watered'].toString())
          : null,
      pHashHistory:
          ((json['phash_history'] ?? json['pHash_history']) as List? ?? [])
              .whereType<String>()
              .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'species': species,
      'guardian_id': guardianId,
      'drive_id': driveId,
      'nickname': nickname,
      'location_lat': locationLat,
      'location_long': locationLong,
      'health_status': healthStatus,
      'image_url': imageUrl,
      'last_watered': lastWatered?.toIso8601String(),
      'phash_history': pHashHistory,
    };
  }

  PlantModel copyWith({
    String? id,
    String? species,
    String? guardianId,
    String? driveId,
    String? nickname,
    double? locationLat,
    double? locationLong,
    String? healthStatus,
    String? imageUrl,
    DateTime? lastWatered,
    List<String>? pHashHistory,
  }) {
    return PlantModel(
      id: id ?? this.id,
      species: species ?? this.species,
      guardianId: guardianId ?? this.guardianId,
      driveId: driveId ?? this.driveId,
      nickname: nickname ?? this.nickname,
      locationLat: locationLat ?? this.locationLat,
      locationLong: locationLong ?? this.locationLong,
      healthStatus: healthStatus ?? this.healthStatus,
      imageUrl: imageUrl ?? this.imageUrl,
      lastWatered: lastWatered ?? this.lastWatered,
      pHashHistory: pHashHistory ?? this.pHashHistory,
    );
  }
}
