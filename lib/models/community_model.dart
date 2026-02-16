// lib/models/community_model.dart
import 'package:flutter/material.dart';

class Community {
  final String id;
  final String name;
  final String description;
  final int memberCount;
  final int plantCount;
  final String? imageUrl;
  final String category;
  final DateTime createdAt;
  final bool isArchived;

  Community({
    required this.id,
    required this.name,
    required this.description,
    required this.memberCount,
    required this.plantCount,
    this.imageUrl,
    required this.category,
    required this.createdAt,
    this.isArchived = false,
  });

  // Create a copy with optional parameter changes
  Community copyWith({
    String? id,
    String? name,
    String? description,
    int? memberCount,
    int? plantCount,
    String? imageUrl,
    String? category,
    DateTime? createdAt,
    bool? isArchived,
  }) {
    return Community(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      memberCount: memberCount ?? this.memberCount,
      plantCount: plantCount ?? this.plantCount,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      isArchived: isArchived ?? this.isArchived,
    );
  }
}

class CommunityPlant {
  final String id;
  final String communityId;
  final String plantName;
  final String scientificName;
  final String plantedBy;
  final String plantedByUsername;
  final String? plantedByAvatar;
  final String location;
  final double? latitude;
  final double? longitude;
  final String? imageUrl;
  final DateTime plantedDate;
  final String status; // "Healthy", "Growing", "Needs Care", "Flowering"
  final String category; // "Tree", "Shrub", "Herb", "Flower", etc.
  final String? description;
  final int likeCount;
  final int commentCount;
  final bool isLiked;
  final List<String> tags;

  CommunityPlant({
    required this.id,
    required this.communityId,
    required this.plantName,
    required this.scientificName,
    required this.plantedBy,
    required this.plantedByUsername,
    this.plantedByAvatar,
    required this.location,
    this.latitude,
    this.longitude,
    this.imageUrl,
    required this.plantedDate,
    required this.status,
    required this.category,
    this.description,
    required this.likeCount,
    required this.commentCount,
    this.isLiked = false,
    this.tags = const [],
  });

  CommunityPlant copyWith({
    String? id,
    String? communityId,
    String? plantName,
    String? scientificName,
    String? plantedBy,
    String? plantedByUsername,
    String? plantedByAvatar,
    String? location,
    double? latitude,
    double? longitude,
    String? imageUrl,
    DateTime? plantedDate,
    String? status,
    String? category,
    String? description,
    int? likeCount,
    int? commentCount,
    bool? isLiked,
    List<String>? tags,
  }) {
    return CommunityPlant(
      id: id ?? this.id,
      communityId: communityId ?? this.communityId,
      plantName: plantName ?? this.plantName,
      scientificName: scientificName ?? this.scientificName,
      plantedBy: plantedBy ?? this.plantedBy,
      plantedByUsername: plantedByUsername ?? this.plantedByUsername,
      plantedByAvatar: plantedByAvatar ?? this.plantedByAvatar,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      imageUrl: imageUrl ?? this.imageUrl,
      plantedDate: plantedDate ?? this.plantedDate,
      status: status ?? this.status,
      category: category ?? this.category,
      description: description ?? this.description,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      isLiked: isLiked ?? this.isLiked,
      tags: tags ?? this.tags,
    );
  }

  Color get statusColor {
    switch (status.toLowerCase()) {
      case 'healthy':
        return Colors.green;
      case 'growing':
        return Colors.blue;
      case 'needs care':
        return Colors.orange;
      case 'flowering':
        return Colors.purple;
      case 'dormant':
        return Colors.grey;
      default:
        return Colors.teal;
    }
  }
}
