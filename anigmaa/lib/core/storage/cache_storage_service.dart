import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:anigmaa/core/utils/app_logger.dart';

/// SharedPreferences-based persistent storage service
/// Provides offline-first data persistence that survives app restarts
///
/// Features:
/// - Persists data to local disk using SharedPreferences
/// - Survives app restart and device reboots
/// - Simple JSON serialization
/// - Fast read/write operations
class CacheStorageService {
  final AppLogger _logger = AppLogger();

  // Storage keys
  static const String _locationLatKey = 'last_latitude';
  static const String _locationLngKey = 'last_longitude';
  static const String _postsKey = 'cached_posts';
  static const String _eventsKey = 'cached_events';
  static const String _communitiesKey = 'cached_communities';
  static const String _postsTimestampKey = 'posts_timestamp';
  static const String _eventsTimestampKey = 'events_timestamp';
  static const String _communitiesTimestampKey = 'communities_timestamp';

  SharedPreferences? _prefs;
  bool _initialized = false;

  /// Initialize SharedPreferences
  /// Must be called before any storage operation
  Future<void> init() async {
    if (_initialized) {
      _logger.debug('[CacheStorage] Already initialized');
      return;
    }

    try {
      _logger.info('[CacheStorage] Initializing SharedPreferences...');
      _prefs = await SharedPreferences.getInstance();
      _initialized = true;
      _logger.info('[CacheStorage] Initialized successfully');

      // Log current cache size
      final postsCount = _prefs?.getInt(_postsTimestampKey) ?? 0;
      final eventsCount = _prefs?.getInt(_eventsTimestampKey) ?? 0;
      final communitiesCount = _prefs?.getInt(_communitiesTimestampKey) ?? 0;
      _logger.debug('[CacheStorage] Cache sizes: posts=$postsCount, events=$eventsCount, communities=$communitiesCount');
    } catch (e, stackTrace) {
      _logger.error('[CacheStorage] Failed to initialize: $e', stackTrace);
      rethrow;
    }
  }

  /// Clear all cached data
  Future<void> clearAll() async {
    if (!_initialized) {
      _logger.warning('[CacheStorage] Cannot clear - not initialized');
      return;
    }

    try {
      await _prefs!.remove(_postsKey);
      await _prefs!.remove(_eventsKey);
      await _prefs!.remove(_communitiesKey);
      await _prefs!.remove(_postsTimestampKey);
      await _prefs!.remove(_eventsTimestampKey);
      await _prefs!.remove(_communitiesTimestampKey);
      _logger.info('[CacheStorage] All cache cleared');
    } catch (e) {
      _logger.error('[CacheStorage] Error clearing cache: $e');
    }
  }

  // ========== POSTS ==========

  Future<void> savePosts(List<dynamic> posts) async {
    _ensureInitialized();
    try {
      final jsonString = jsonEncode(posts.map((p) => p.toString()).toList());
      await _prefs!.setString(_postsKey, jsonString);
      await _prefs!.setString(_postsTimestampKey, DateTime.now().toIso8601String());
      await _prefs!.setInt('posts_count', posts.length);
      _logger.debug('[CacheStorage] Saved ${posts.length} posts');
    } catch (e) {
      _logger.error('[CacheStorage] Error saving posts: $e');
    }
  }

  Future<List<String>> getPosts() async {
    _ensureInitialized();
    try {
      final jsonString = _prefs!.getString(_postsKey);
      if (jsonString == null) return [];

      final List<dynamic> jsonList = jsonDecode(jsonString);
      _logger.debug('[CacheStorage] Retrieved ${jsonList.length} cached posts');
      return jsonList.cast<String>();
    } catch (e) {
      _logger.error('[CacheStorage] Error getting posts: $e');
      return [];
    }
  }

  // ========== EVENTS ==========

  Future<void> saveEvents(List<dynamic> events) async {
    _ensureInitialized();
    try {
      final jsonString = jsonEncode(events.map((e) => e.toString()).toList());
      await _prefs!.setString(_eventsKey, jsonString);
      await _prefs!.setString(_eventsTimestampKey, DateTime.now().toIso8601String());
      await _prefs!.setInt('events_count', events.length);
      _logger.debug('[CacheStorage] Saved ${events.length} events');
    } catch (e) {
      _logger.error('[CacheStorage] Error saving events: $e');
    }
  }

  Future<List<String>> getEvents() async {
    _ensureInitialized();
    try {
      final jsonString = _prefs!.getString(_eventsKey);
      if (jsonString == null) return [];

      final List<dynamic> jsonList = jsonDecode(jsonString);
      _logger.debug('[CacheStorage] Retrieved ${jsonList.length} cached events');
      return jsonList.cast<String>();
    } catch (e) {
      _logger.error('[CacheStorage] Error getting events: $e');
      return [];
    }
  }

  // ========== COMMUNITIES ==========

  Future<void> saveCommunities(List<dynamic> communities) async {
    _ensureInitialized();
    try {
      final jsonString = jsonEncode(communities.map((c) => c.toString()).toList());
      await _prefs!.setString(_communitiesKey, jsonString);
      await _prefs!.setString(_communitiesTimestampKey, DateTime.now().toIso8601String());
      await _prefs!.setInt('communities_count', communities.length);
      _logger.debug('[CacheStorage] Saved ${communities.length} communities');
    } catch (e) {
      _logger.error('[CacheStorage] Error saving communities: $e');
    }
  }

  Future<List<String>> getCommunities() async {
    _ensureInitialized();
    try {
      final jsonString = _prefs!.getString(_communitiesKey);
      if (jsonString == null) return [];

      final List<dynamic> jsonList = jsonDecode(jsonString);
      _logger.debug('[CacheStorage] Retrieved ${jsonList.length} cached communities');
      return jsonList.cast<String>();
    } catch (e) {
      _logger.error('[CacheStorage] Error getting communities: $e');
      return [];
    }
  }

  // ========== LOCATION ==========

  /// Save last known user location
  Future<void> saveLocation(double latitude, double longitude) async {
    _ensureInitialized();
    try {
      await _prefs!.setDouble(_locationLatKey, latitude);
      await _prefs!.setDouble(_locationLngKey, longitude);
      await _prefs!.setString('location_timestamp', DateTime.now().toIso8601String());
      _logger.debug('[CacheStorage] Saved location: $latitude, $longitude');
    } catch (e) {
      _logger.error('[CacheStorage] Error saving location: $e');
    }
  }

  /// Get last known user location
  /// Returns null if no cached location exists
  Future<Map<String, double>?> getLastLocation() async {
    _ensureInitialized();
    try {
      final lat = _prefs!.getDouble(_locationLatKey);
      final lng = _prefs!.getDouble(_locationLngKey);

      if (lat != null && lng != null) {
        _logger.debug('[CacheStorage] Retrieved cached location: $lat, $lng');
        return {'latitude': lat, 'longitude': lng};
      }

      _logger.debug('[CacheStorage] No cached location found');
      return null;
    } catch (e) {
      _logger.error('[CacheStorage] Error getting location: $e');
      return null;
    }
  }

  // ========== METADATA ==========

  DateTime? getCacheTimestamp(String key) {
    _ensureInitialized();
    final timestampKey = '${key}_timestamp';
    final timestamp = _prefs!.getString(timestampKey);
    return timestamp != null ? DateTime.tryParse(timestamp) : null;
  }

  bool isCacheExpired(String key, {Duration maxAge = const Duration(hours: 1)}) {
    final timestamp = getCacheTimestamp(key);
    if (timestamp == null) return true;

    final age = DateTime.now().difference(timestamp);
    return age > maxAge;
  }

  /// Check if any cache exists
  bool hasAnyData() {
    _ensureInitialized();
    return _prefs!.containsKey(_postsKey) ||
        _prefs!.containsKey(_eventsKey) ||
        _prefs!.containsKey(_communitiesKey);
  }

  // ========== PRIVATE ==========

  void _ensureInitialized() {
    if (!_initialized) {
      throw StateError('CacheStorageService must be initialized before use. Call init() first.');
    }
  }
}
