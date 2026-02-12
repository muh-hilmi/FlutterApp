import '../../domain/entities/community.dart';
import '../../domain/entities/community_category.dart';

abstract class CommunityLocalDataSource {
  Future<List<Community>> getCommunities();
  Future<List<Community>> getCommunitiesByLocation(String location);
  Future<List<Community>> getCommunitiesByCategory(CommunityCategory category);
  Future<List<Community>> getJoinedCommunities(String userId);
  Future<Community?> getCommunityById(String id);
  Future<void> cacheCommunities(List<Community> communities);
  Future<void> cacheCommunity(Community community);
  Future<void> deleteCommunity(String id);
}

class CommunityLocalDataSourceImpl implements CommunityLocalDataSource {
  // Mock data for now - in real implementation this would use a local database
  final List<Community> _cachedCommunities = [];
  final Map<String, List<String>> _userJoinedCommunities = {
    'current_user_id': ['1', '2'], // Mock: user already joined these communities
  };

  @override
  Future<List<Community>> getCommunities() async {
    if (_cachedCommunities.isEmpty) {
      return _getMockCommunities();
    }
    return _cachedCommunities;
  }

  @override
  Future<List<Community>> getCommunitiesByLocation(String location) async {
    final communities = await getCommunities();
    return communities.where((c) => c.location == location).toList();
  }

  @override
  Future<List<Community>> getCommunitiesByCategory(CommunityCategory category) async {
    final communities = await getCommunities();
    return communities.where((c) => c.category == category).toList();
  }

  @override
  Future<List<Community>> getJoinedCommunities(String userId) async {
    final joinedIds = _userJoinedCommunities[userId] ?? [];
    final allCommunities = await getCommunities();
    return allCommunities.where((c) => joinedIds.contains(c.id)).toList();
  }

  @override
  Future<Community?> getCommunityById(String id) async {
    final communities = await getCommunities();
    try {
      return communities.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> cacheCommunities(List<Community> communities) async {
    _cachedCommunities.clear();
    _cachedCommunities.addAll(communities);
  }

  @override
  Future<void> cacheCommunity(Community community) async {
    final index = _cachedCommunities.indexWhere((c) => c.id == community.id);
    if (index != -1) {
      _cachedCommunities[index] = community;
    } else {
      _cachedCommunities.add(community);
    }
  }

  @override
  Future<void> deleteCommunity(String id) async {
    _cachedCommunities.removeWhere((c) => c.id == id);
  }

  List<Community> _getMockCommunities() {
    return [
      Community(
        id: '1',
        name: 'Boyolali Developers',
        description: 'Komunitas developer lokal yang suka sharing & ngumpul bareng',
        category: CommunityCategory.learning,
        location: 'Boyolali',
        memberCount: 89,
        createdAt: DateTime.now().subtract(const Duration(days: 180)),
        isVerified: true,
        icon: '💻',
      ),
      Community(
        id: '2',
        name: 'Jakarta Football Club',
        description: 'Main bola bareng tiap weekend. Open untuk semua level!',
        category: CommunityCategory.sports,
        location: 'Jakarta',
        memberCount: 234,
        createdAt: DateTime.now().subtract(const Duration(days: 365)),
        isVerified: true,
        icon: '⚽',
      ),
      Community(
        id: '3',
        name: 'Bandung Photography',
        description: 'Komunitas fotografer Bandung. From beginner to pro!',
        category: CommunityCategory.creative,
        location: 'Bandung',
        memberCount: 156,
        createdAt: DateTime.now().subtract(const Duration(days: 120)),
        icon: '📸',
      ),
      Community(
        id: '4',
        name: 'Surabaya Foodies',
        description: 'Pecinta kuliner Surabaya. Explore makanan baru bareng!',
        category: CommunityCategory.food,
        location: 'Surabaya',
        memberCount: 312,
        createdAt: DateTime.now().subtract(const Duration(days: 200)),
        isVerified: true,
        icon: '🍜',
      ),
      Community(
        id: '5',
        name: 'Jakarta Startup Founders',
        description: 'Komunitas entrepreneur & startup founders di Jakarta',
        category: CommunityCategory.networking,
        location: 'Jakarta',
        memberCount: 189,
        createdAt: DateTime.now().subtract(const Duration(days: 90)),
        isVerified: true,
        icon: '💼',
      ),
      Community(
        id: '6',
        name: 'Yogyakarta Hikers',
        description: 'Suka hiking? Join kami explore gunung-gunung di Jogja!',
        category: CommunityCategory.sports,
        location: 'Yogyakarta',
        memberCount: 145,
        createdAt: DateTime.now().subtract(const Duration(days: 150)),
        icon: '🏔️',
      ),
      Community(
        id: '7',
        name: 'Jakarta Coffee Lovers',
        description: 'Komunitas pecinta kopi Jakarta. Eksplorasi kedai-kedai kopi terbaik!',
        category: CommunityCategory.food,
        location: 'Jakarta',
        memberCount: 201,
        createdAt: DateTime.now().subtract(const Duration(days: 220)),
        icon: '☕',
      ),
      Community(
        id: '8',
        name: 'Bandung Book Club',
        description: 'Klub baca buku Bandung. Diskusi buku tiap minggu!',
        category: CommunityCategory.creative,
        location: 'Bandung',
        memberCount: 78,
        createdAt: DateTime.now().subtract(const Duration(days: 95)),
        icon: '📚',
      ),
    ];
  }
}
