import 'dart:convert';
import '../../domain/entities/community.dart';
import '../../domain/entities/community_category.dart';
import '../../core/storage/cache_storage_service.dart';
import 'community_local_datasource.dart';

/// Community local datasource using persistent SharedPreferences storage
/// Survives app restart and device reboots
class CommunityLocalDataSourceImpl implements CommunityLocalDataSource {
  final CacheStorageService _cacheStorage;

  CommunityLocalDataSourceImpl(this._cacheStorage);

  @override
  Future<List<Community>> getCommunities() async {
    try {
      final cachedJsonList = await _cacheStorage.getCommunities();

      if (cachedJsonList.isEmpty) {
        // Return mock data as fallback
        return _getMockCommunities();
      }

      // Parse JSON strings back to Community objects
      final communities = cachedJsonList.map((jsonString) {
        final json = Map<String, dynamic>.from(
          jsonDecode(jsonString),
        );
        return Community.fromJson(json);
      }).toList();

      return communities;
    } catch (e) {
      // Return mock data on error
      return _getMockCommunities();
    }
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
    final joinedIds = ['1', '2']; // Mock: user already joined these
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
    try {
      // Convert Community objects to JSON strings for storage
      final jsonStringList = communities.map((community) {
        return jsonEncode(community.toJson());
      }).toList();

      await _cacheStorage.saveCommunities(jsonStringList);
    } catch (e) {
      // Silent fail - cache is optional
    }
  }

  @override
  Future<void> cacheCommunity(Community community) async {
    try {
      final currentCommunities = await getCommunities();
      final index = currentCommunities.indexWhere((c) => c.id == community.id);

      if (index != -1) {
        currentCommunities[index] = community;
      } else {
        currentCommunities.add(community);
      }

      await cacheCommunities(currentCommunities);
    } catch (e) {
      // Silent fail
    }
  }

  @override
  Future<void> deleteCommunity(String id) async {
    try {
      final currentCommunities = await getCommunities();
      currentCommunities.removeWhere((c) => c.id == id);
      await cacheCommunities(currentCommunities);
    } catch (e) {
      // Silent fail
    }
  }

  // Mock data fallback
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
    ];
  }
}
