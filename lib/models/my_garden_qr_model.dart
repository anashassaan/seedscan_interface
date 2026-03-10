// lib/models/my_garden_qr_model.dart
/// Model for My Garden QR codes stored in Appwrite.
import 'dart:convert';

class MyGardenQRModel {
  final String id; // document ID (unique)
  final String uniqueCode; // e.g. MYGARDEN-1234567890-0001
  final String plantName;
  final String localName; // replaces scientific name
  final String category; // Tree, Shrub, Herb, Flower, Vegetable, Fruit, Other
  final String bestSeason; // Spring, Summer, Autumn, Winter, All Year
  final String qrType; // 'Seed' or 'Plant'
  final String? plantAge; // only when qrType == 'Plant'
  final String notes;
  final String ownerId;
  final String ownerName;
  final String ownerEmail;
  final String gardenId; // e.g. GARDEN-USERHANDLE
  final String source; // always 'my_garden'
  final DateTime createdAt;
  final double locationLat;
  final double locationLong;
  final String? imageFileId; // Appwrite storage file ID
  final String? imageUrl; // resolved preview URL
  final DateTime? plantedAt; // when the plant was planted
  final List<Map<String, dynamic>> imageHistory; // [{fileId, url, updatedAt}]

  MyGardenQRModel({
    required this.id,
    required this.uniqueCode,
    required this.plantName,
    required this.localName,
    required this.category,
    required this.bestSeason,
    required this.qrType,
    this.plantAge,
    this.notes = '',
    required this.ownerId,
    required this.ownerName,
    this.ownerEmail = '',
    required this.gardenId,
    this.source = 'my_garden',
    required this.createdAt,
    this.locationLat = 0.0,
    this.locationLong = 0.0,
    this.imageFileId,
    this.imageUrl,
    this.plantedAt,
    this.imageHistory = const [],
  });

  factory MyGardenQRModel.fromJson(Map<String, dynamic> json) {
    return MyGardenQRModel(
      id: json['\$id'] ?? json['id'] ?? '',
      uniqueCode: json['unique_code'] ?? '',
      plantName: json['plant_name'] ?? '',
      localName: json['local_name'] ?? '',
      category: json['category'] ?? '',
      bestSeason: json['best_season'] ?? '',
      qrType: json['qr_type'] ?? 'Seed',
      plantAge: json['plant_age'],
      notes: json['notes'] ?? '',
      ownerId: json['owner_id'] ?? '',
      ownerName: json['owner_name'] ?? '',
      ownerEmail: json['owner_email'] ?? '',
      gardenId: json['garden_id'] ?? '',
      source: json['source'] ?? 'my_garden',
      createdAt: DateTime.tryParse(
            json['created_at'] ?? json['\$createdAt'] ?? '',
          ) ??
          DateTime.now(),
      locationLat: (json['location_lat'] ?? 0.0).toDouble(),
      locationLong: (json['location_long'] ?? 0.0).toDouble(),
      imageFileId: json['image_file_id'],
      imageUrl: json['image_url'],
      plantedAt: json['planted_at'] != null
          ? DateTime.tryParse(json['planted_at'].toString())
          : null,
      imageHistory: json['image_history'] != null
          ? (json['image_history'] as List)
              .map((e) {
                if (e is String) {
                  // Stored as JSON-encoded strings in Appwrite string array
                  try {
                    final decoded = jsonDecode(e);
                    if (decoded is Map) {
                      return Map<String, dynamic>.from(decoded);
                    }
                  } catch (_) {}
                  return <String, dynamic>{};
                } else if (e is Map) {
                  return Map<String, dynamic>.from(e);
                }
                return <String, dynamic>{};
              })
              .where((m) => m.isNotEmpty)
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'unique_code': uniqueCode,
      'plant_name': plantName,
      'local_name': localName,
      'category': category,
      'best_season': bestSeason,
      'qr_type': qrType,
      'plant_age': plantAge,
      'notes': notes,
      'owner_id': ownerId,
      'owner_name': ownerName,
      'owner_email': ownerEmail,
      'garden_id': gardenId,
      'source': source,
      'created_at': createdAt.toIso8601String(),
      'location_lat': locationLat,
      'location_long': locationLong,
      'image_file_id': imageFileId,
      'image_url': imageUrl,
      'planted_at': plantedAt?.toIso8601String(),
      // 'image_history': imageHistory.map((e) => jsonEncode(e)).toList(),
    };
  }

  /// The data that gets encoded into the QR image.
  Map<String, dynamic> toQrPayload() {
    return {
      'id': uniqueCode,
      'plantName': plantName,
      'localName': localName,
      'category': category,
      'bestSeason': bestSeason,
      'qrType': qrType,
      'plantAge': plantAge,
      'notes': notes,
      'owner': ownerName,
      'ownerEmail': ownerEmail,
      'gardenId': gardenId,
      'source': source, // identifies this as My Garden QR
      'createdAt': createdAt.toIso8601String(),
    };
  }

  MyGardenQRModel copyWith({
    String? id,
    String? uniqueCode,
    String? plantName,
    String? localName,
    String? category,
    String? bestSeason,
    String? qrType,
    String? plantAge,
    String? notes,
    String? ownerId,
    String? ownerName,
    String? ownerEmail,
    String? gardenId,
    String? source,
    DateTime? createdAt,
    double? locationLat,
    double? locationLong,
    String? imageFileId,
    String? imageUrl,
    DateTime? plantedAt,
    List<Map<String, dynamic>>? imageHistory,
  }) {
    return MyGardenQRModel(
      id: id ?? this.id,
      uniqueCode: uniqueCode ?? this.uniqueCode,
      plantName: plantName ?? this.plantName,
      localName: localName ?? this.localName,
      category: category ?? this.category,
      bestSeason: bestSeason ?? this.bestSeason,
      qrType: qrType ?? this.qrType,
      plantAge: plantAge ?? this.plantAge,
      notes: notes ?? this.notes,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      ownerEmail: ownerEmail ?? this.ownerEmail,
      gardenId: gardenId ?? this.gardenId,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
      locationLat: locationLat ?? this.locationLat,
      locationLong: locationLong ?? this.locationLong,
      imageFileId: imageFileId ?? this.imageFileId,
      imageUrl: imageUrl ?? this.imageUrl,
      plantedAt: plantedAt ?? this.plantedAt,
      imageHistory: imageHistory ?? this.imageHistory,
    );
  }
}
