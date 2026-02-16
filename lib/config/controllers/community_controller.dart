// lib/config/controllers/community_controller.dart
import 'package:flutter/material.dart';
import '../../models/community_model.dart';

class CommunityController extends ChangeNotifier {
  CommunityController() {
    _initializeCommunities();
    _initializeSamplePlants();
  }

  // List of communities
  final List<Community> _communities = [];
  final Map<String, List<CommunityPlant>> _communityPlants = {};

  void _initializeCommunities() {
    // TODO: DUMMY DATA - In production, replace all imageUrl values with user-uploaded images
    // These Unsplash URLs are placeholder images for development/demo purposes only
    _communities.addAll([
      Community(
        id: 'daily_dose_ai',
        name: 'Daily Dose of AI ⚡',
        description: 'A community for AI enthusiasts learning about plants',
        memberCount: 1247,
        plantCount: 0,
        imageUrl:
            'https://images.unsplash.com/photo-1466692476868-aef1dfb1e735?auto=format&fit=crop&w=800', // PLACEHOLDER - Replace with user upload
        category: 'Education',
        createdAt: DateTime(2025, 1, 15),
      ),
      Community(
        id: 'announcements',
        name: 'Announcements',
        description: 'Official announcements and updates for plant care',
        memberCount: 3456,
        plantCount: 0,
        imageUrl:
            'https://images.unsplash.com/photo-1542601906990-b4d3fb778b09?auto=format&fit=crop&w=800',
        category: 'Official',
        createdAt: DateTime(2025, 1, 10),
      ),
      Community(
        id: 'beginner_to_advance',
        name: 'Beginner to Advance',
        description: 'Growing together from novice to expert gardeners',
        memberCount: 892,
        plantCount: 0,
        imageUrl:
            'https://images.unsplash.com/photo-1416879595882-3373a0480b5b?auto=format&fit=crop&w=800',
        category: 'Learning',
        createdAt: DateTime(2025, 1, 20),
      ),
      Community(
        id: 'online_work_nust',
        name: 'Online Work NUST',
        description: 'NUST students collaborative plantation project',
        memberCount: 567,
        plantCount: 0,
        imageUrl:
            'https://images.unsplash.com/photo-1463936575829-25148e1db1b8?auto=format&fit=crop&w=800',
        category: 'University',
        createdAt: DateTime(2024, 12, 5),
      ),
      Community(
        id: 'nustians_engineering',
        name: 'Nustians - Engineering',
        description: 'Engineering students making campus greener',
        memberCount: 423,
        plantCount: 0,
        imageUrl:
            'https://images.unsplash.com/photo-1473448912268-2022ce9509d8?auto=format&fit=crop&w=800',
        category: 'University',
        createdAt: DateTime(2025, 1, 25),
      ),
      Community(
        id: 'urban_gardeners',
        name: 'Urban Gardeners',
        description: 'Bringing nature back to city spaces',
        memberCount: 1834,
        plantCount: 0,
        imageUrl:
            'https://images.unsplash.com/photo-1591958911259-bee2173bdccc?auto=format&fit=crop&w=800',
        category: 'Urban',
        createdAt: DateTime(2024, 11, 15),
      ),
    ]);
  }

  void _initializeSamplePlants() {
    // TODO: DUMMY DATA - All plant images below are placeholders for demo purposes
    // In production, these should be replaced with actual user-uploaded plant photos
    // Daily Dose of AI community plants
    _communityPlants['daily_dose_ai'] = [
      CommunityPlant(
        id: 'plant_dd_001',
        communityId: 'daily_dose_ai',
        plantName: 'Neem Tree',
        scientificName: 'Azadirachta indica',
        plantedBy: 'user_001',
        plantedByUsername: 'Ahmed Khan',
        plantedByAvatar: 'https://randomuser.me/api/portraits/men/32.jpg',
        location: 'Islamabad, Pakistan',
        latitude: 33.6844,
        longitude: 73.0479,
        imageUrl:
            'https://images.unsplash.com/photo-1501004318641-b39e6451bec6?auto=format&fit=crop&w=800',
        plantedDate: DateTime(2025, 1, 20),
        status: 'Healthy',
        category: 'Tree',
        description: 'Young neem tree planted for medicinal purposes',
        likeCount: 24,
        commentCount: 5,
        tags: ['medicinal', 'native', 'beneficial'],
      ),
      CommunityPlant(
        id: 'plant_dd_002',
        communityId: 'daily_dose_ai',
        plantName: 'Rose Bush',
        scientificName: 'Rosa damascena',
        plantedBy: 'user_002',
        plantedByUsername: 'Fatima Ali',
        plantedByAvatar: 'https://randomuser.me/api/portraits/women/44.jpg',
        location: 'Lahore, Pakistan',
        latitude: 31.5204,
        longitude: 74.3587,
        imageUrl:
            'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?auto=format&fit=crop&w=800',
        plantedDate: DateTime(2025, 1, 22),
        status: 'Flowering',
        category: 'Shrub',
        description: 'Beautiful pink roses blooming this season',
        likeCount: 48,
        commentCount: 12,
        tags: ['flowering', 'fragrant', 'ornamental'],
      ),
      CommunityPlant(
        id: 'plant_dd_003',
        communityId: 'daily_dose_ai',
        plantName: 'Basil',
        scientificName: 'Ocimum basilicum',
        plantedBy: 'user_003',
        plantedByUsername: 'Sara Malik',
        plantedByAvatar: 'https://randomuser.me/api/portraits/women/68.jpg',
        location: 'Karachi, Pakistan',
        latitude: 24.8607,
        longitude: 67.0011,
        imageUrl:
            'https://images.unsplash.com/photo-1618375569909-3c8616cf7733?auto=format&fit=crop&w=800',
        plantedDate: DateTime(2025, 1, 18),
        status: 'Growing',
        category: 'Herb',
        description: 'Fresh basil for cooking and tea',
        likeCount: 15,
        commentCount: 3,
        tags: ['herb', 'culinary', 'aromatic'],
      ),
    ];

    // Online Work NUST plants
    _communityPlants['online_work_nust'] = [
      CommunityPlant(
        id: 'plant_nust_001',
        communityId: 'online_work_nust',
        plantName: 'Mango Tree',
        scientificName: 'Mangifera indica',
        plantedBy: 'user_004',
        plantedByUsername: 'Ali Hassan',
        plantedByAvatar: 'https://randomuser.me/api/portraits/men/45.jpg',
        location: 'NUST Campus, Islamabad',
        latitude: 33.6425,
        longitude: 72.9897,
        imageUrl:
            'https://images.unsplash.com/photo-1605027990121-cbae9d3b5b1f?auto=format&fit=crop&w=800',
        plantedDate: DateTime(2025, 1, 10),
        status: 'Healthy',
        category: 'Tree',
        description: 'Mango tree planted near the library',
        likeCount: 67,
        commentCount: 18,
        tags: ['fruit', 'campus', 'native'],
      ),
      CommunityPlant(
        id: 'plant_nust_002',
        communityId: 'online_work_nust',
        plantName: 'Sunflower',
        scientificName: 'Helianthus annuus',
        plantedBy: 'user_005',
        plantedByUsername: 'Zainab Ahmed',
        plantedByAvatar: 'https://randomuser.me/api/portraits/women/22.jpg',
        location: 'NUST H-12 Campus',
        latitude: 33.6425,
        longitude: 72.9897,
        imageUrl:
            'https://images.unsplash.com/photo-1597848212624-e66cb8b3a994?auto=format&fit=crop&w=800',
        plantedDate: DateTime(2025, 1, 15),
        status: 'Flowering',
        category: 'Flower',
        description: 'Bright sunflowers adding color to campus',
        likeCount: 92,
        commentCount: 24,
        tags: ['flowering', 'bright', 'annual'],
      ),
    ];

    // Urban Gardeners plants
    _communityPlants['urban_gardeners'] = [
      CommunityPlant(
        id: 'plant_ug_001',
        communityId: 'urban_gardeners',
        plantName: 'Ficus Tree',
        scientificName: 'Ficus religiosa',
        plantedBy: 'user_006',
        plantedByUsername: 'Imran Sheikh',
        plantedByAvatar: 'https://randomuser.me/api/portraits/men/67.jpg',
        location: 'F-7 Islamabad',
        latitude: 33.7102,
        longitude: 73.0498,
        imageUrl:
            'https://images.unsplash.com/photo-1509937528035-ad76254b0356?auto=format&fit=crop&w=800',
        plantedDate: DateTime(2024, 12, 5),
        status: 'Healthy',
        category: 'Tree',
        description: 'Sacred fig tree for urban cooling',
        likeCount: 156,
        commentCount: 34,
        tags: ['shade', 'urban', 'sacred'],
      ),
    ];

    // Update plant counts
    for (var community in _communities) {
      final plants = _communityPlants[community.id] ?? [];
      final updatedCommunity = community.copyWith(plantCount: plants.length);
      final index = _communities.indexOf(community);
      _communities[index] = updatedCommunity;
    }
  }

  // Get all communities
  List<Community> getCommunities() {
    // Update plant counts dynamically before returning
    return _communities.map((community) {
      final plantCount = _communityPlants[community.id]?.length ?? 0;
      return community.copyWith(plantCount: plantCount);
    }).toList();
  }

  // Get community by ID
  Community? getCommunityById(String id) {
    try {
      final community = _communities.firstWhere((c) => c.id == id);
      // Update plant count dynamically
      final plantCount = _communityPlants[id]?.length ?? 0;
      return community.copyWith(plantCount: plantCount);
    } catch (e) {
      return null;
    }
  }

  // Get plants for a specific community
  List<CommunityPlant> getCommunityPlants(String communityId) {
    return List.unmodifiable(_communityPlants[communityId] ?? []);
  }

  // Add plant to a community
  void addPlantToCommunity(CommunityPlant plant) {
    if (!_communityPlants.containsKey(plant.communityId)) {
      _communityPlants[plant.communityId] = [];
    }
    _communityPlants[plant.communityId]!.add(plant);

    // Update plant count
    final communityIndex =
        _communities.indexWhere((c) => c.id == plant.communityId);
    if (communityIndex != -1) {
      final updatedCommunity = _communities[communityIndex].copyWith(
        plantCount: _communityPlants[plant.communityId]!.length,
      );
      _communities[communityIndex] = updatedCommunity;
    }
    notifyListeners();
  }

  // Remove plant from community
  void removePlantFromCommunity(String communityId, String plantId) {
    if (_communityPlants.containsKey(communityId)) {
      _communityPlants[communityId]!.removeWhere((p) => p.id == plantId);

      // Update plant count
      final communityIndex =
          _communities.indexWhere((c) => c.id == communityId);
      if (communityIndex != -1) {
        final updatedCommunity = _communities[communityIndex].copyWith(
          plantCount: _communityPlants[communityId]!.length,
        );
        _communities[communityIndex] = updatedCommunity;
      }
      notifyListeners();
    }
  }

  // Toggle like on community plant
  void toggleLikePlant(String communityId, String plantId) {
    if (_communityPlants.containsKey(communityId)) {
      final plants = _communityPlants[communityId]!;
      final plantIndex = plants.indexWhere((p) => p.id == plantId);

      if (plantIndex != -1) {
        final plant = plants[plantIndex];
        final updatedPlant = plant.copyWith(
          isLiked: !plant.isLiked,
          likeCount: plant.isLiked ? plant.likeCount - 1 : plant.likeCount + 1,
        );
        _communityPlants[communityId]![plantIndex] = updatedPlant;
        notifyListeners();
      }
    }
  }

  // Search communities
  List<Community> searchCommunities(String query) {
    if (query.isEmpty) return getCommunities();

    final lowerQuery = query.toLowerCase();
    return _communities.where((community) {
      return community.name.toLowerCase().contains(lowerQuery) ||
          community.description.toLowerCase().contains(lowerQuery) ||
          community.category.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  // Get communities by category
  List<Community> getCommunitiesByCategory(String category) {
    return _communities.where((c) => c.category == category).toList();
  }

  // Check if QR code belongs to a community (for backward compatibility)
  Community? getCommunityByQrCode(String qrCode) {
    // For now, return null as QR prefix system is removed
    // You can implement custom logic here if needed
    return null;
  }

  // Update plant image
  void updatePlantImage(String communityId, String plantId, String imagePath) {
    if (_communityPlants.containsKey(communityId)) {
      final plants = _communityPlants[communityId]!;
      final plantIndex = plants.indexWhere((p) => p.id == plantId);

      if (plantIndex != -1) {
        final plant = plants[plantIndex];
        final updatedPlant = plant.copyWith(imageUrl: imagePath);
        _communityPlants[communityId]![plantIndex] = updatedPlant;
        notifyListeners();
      }
    }
  }

  // Update plant location
  void updatePlantLocation(String communityId, String plantId, String location,
      double? latitude, double? longitude) {
    if (_communityPlants.containsKey(communityId)) {
      final plants = _communityPlants[communityId]!;
      final plantIndex = plants.indexWhere((p) => p.id == plantId);

      if (plantIndex != -1) {
        final plant = plants[plantIndex];
        final updatedPlant = plant.copyWith(
          location: location,
          latitude: latitude,
          longitude: longitude,
        );
        _communityPlants[communityId]![plantIndex] = updatedPlant;
        notifyListeners();
      }
    }
  }

  // Get total count of all plants across all communities
  int getTotalCommunityPlantsCount() {
    int total = 0;
    for (var plants in _communityPlants.values) {
      total += plants.length;
    }
    return total;
  }
}
