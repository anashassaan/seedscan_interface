// lib/models/community_model.dart
/// Matches Appwrite collection: `communities`
import 'package:flutter/material.dart';

class Community {
  final String id;
  final String name;
  final String? description;
  final String creatorId;
  final String? coverImageId;
  final String? imageUrl;
  final String qrCodeUrl;
  final String inviteCode;
  final int memberCount;
  final int plantCount;
  final String category;
  final bool isActive;
  final DateTime createdAt;

  Community({
    required this.id,
    required this.name,
    this.description,
    this.creatorId = '',
    this.coverImageId,
    this.imageUrl,
    this.qrCodeUrl = '',
    this.inviteCode = '',
    this.memberCount = 1,
    this.plantCount = 0,
    this.category = 'General',
    this.isActive = true,
    required this.createdAt,
  });

  factory Community.fromJson(Map<String, dynamic> json) {
    return Community(
      id: json['\$id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      creatorId: json['creator_id'] ?? '',
      coverImageId: json['cover_image_id'],
      imageUrl: json['image_url'],
      qrCodeUrl: json['qr_code_url'] ?? '',
      inviteCode: json['invite_code'] ?? '',
      memberCount: json['member_count'] ?? 1,
      plantCount: json['plant_count'] ?? 0,
      category: json['category'] ?? 'General',
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(
        json['created_at'] ??
            json['\$createdAt'] ??
            DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'creator_id': creatorId,
      'cover_image_id': coverImageId,
      'image_url': imageUrl,
      'qr_code_url': qrCodeUrl,
      'invite_code': inviteCode,
      'member_count': memberCount,
      'plant_count': plantCount,
      'category': category,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Community copyWith({
    String? id,
    String? name,
    String? description,
    String? creatorId,
    String? coverImageId,
    String? imageUrl,
    String? qrCodeUrl,
    String? inviteCode,
    int? memberCount,
    int? plantCount,
    String? category,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return Community(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      creatorId: creatorId ?? this.creatorId,
      coverImageId: coverImageId ?? this.coverImageId,
      imageUrl: imageUrl ?? this.imageUrl,
      qrCodeUrl: qrCodeUrl ?? this.qrCodeUrl,
      inviteCode: inviteCode ?? this.inviteCode,
      memberCount: memberCount ?? this.memberCount,
      plantCount: plantCount ?? this.plantCount,
      category: category ?? this.category,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Matches Appwrite collection: `community_posts`
class CommunityPost {
  final String id;
  final String communityId;
  final String authorId;
  final String authorName;
  final String content;
  final String? imageId;
  final String postType; // general, plant_update, tip, achievement
  final String? linkedPlantId;
  final int likesCount;
  final int commentsCount;
  final DateTime createdAt;

  CommunityPost({
    required this.id,
    required this.communityId,
    required this.authorId,
    required this.authorName,
    required this.content,
    this.imageId,
    required this.postType,
    this.linkedPlantId,
    this.likesCount = 0,
    this.commentsCount = 0,
    required this.createdAt,
  });

  factory CommunityPost.fromJson(Map<String, dynamic> json) {
    return CommunityPost(
      id: json['\$id'] ?? json['id'] ?? '',
      communityId: json['community_id'] ?? '',
      authorId: json['author_id'] ?? '',
      authorName: json['author_name'] ?? '',
      content: json['content'] ?? '',
      imageId: json['image_id'],
      postType: json['post_type'] ?? 'general',
      linkedPlantId: json['linked_plant_id'],
      likesCount: json['likes_count'] ?? 0,
      commentsCount: json['comments_count'] ?? 0,
      createdAt: DateTime.parse(
        json['created_at'] ??
            json['\$createdAt'] ??
            DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'community_id': communityId,
      'author_id': authorId,
      'author_name': authorName,
      'content': content,
      'image_id': imageId,
      'post_type': postType,
      'linked_plant_id': linkedPlantId,
      'likes_count': likesCount,
      'comments_count': commentsCount,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

/// Matches Appwrite collection: `community_comments`
class CommunityComment {
  final String id;
  final String postId;
  final String authorId;
  final String authorName;
  final String content;
  final DateTime createdAt;

  CommunityComment({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorName,
    required this.content,
    required this.createdAt,
  });

  factory CommunityComment.fromJson(Map<String, dynamic> json) {
    return CommunityComment(
      id: json['\$id'] ?? json['id'] ?? '',
      postId: json['post_id'] ?? '',
      authorId: json['author_id'] ?? '',
      authorName: json['author_name'] ?? '',
      content: json['content'] ?? '',
      createdAt: DateTime.parse(
        json['created_at'] ??
            json['\$createdAt'] ??
            DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'post_id': postId,
      'author_id': authorId,
      'author_name': authorName,
      'content': content,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

/// Matches Appwrite collection: `community_likes`
class CommunityLike {
  final String id;
  final String postId;
  final String userId;
  final DateTime createdAt;

  CommunityLike({
    required this.id,
    required this.postId,
    required this.userId,
    required this.createdAt,
  });

  factory CommunityLike.fromJson(Map<String, dynamic> json) {
    return CommunityLike(
      id: json['\$id'] ?? json['id'] ?? '',
      postId: json['post_id'] ?? '',
      userId: json['user_id'] ?? '',
      createdAt: DateTime.parse(
        json['created_at'] ??
            json['\$createdAt'] ??
            DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'post_id': postId,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

/// Matches Appwrite collection: `community_members`
class CommunityMember {
  final String id;
  final String communityId;
  final String userId;
  final String role; // admin, moderator, member
  final DateTime joinedAt;

  CommunityMember({
    required this.id,
    required this.communityId,
    required this.userId,
    this.role = 'member',
    required this.joinedAt,
  });

  factory CommunityMember.fromJson(Map<String, dynamic> json) {
    return CommunityMember(
      id: json['\$id'] ?? json['id'] ?? '',
      communityId: json['community_id'] ?? '',
      userId: json['user_id'] ?? '',
      role: json['role'] ?? 'member',
      joinedAt: DateTime.parse(
        json['joined_at'] ??
            json['\$createdAt'] ??
            DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'community_id': communityId,
      'user_id': userId,
      'role': role,
      'joined_at': joinedAt.toIso8601String(),
    };
  }
}

/// Helper for backward compatibility with community plant display.
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
  final String status;
  final String category;
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
