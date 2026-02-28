import 'package:hive_flutter/hive_flutter.dart';
import '../utils/app_logger.dart';

/// Hive-based location cache service
/// Fast, efficient local storage for user location
class LocationCacheService {
  final AppLogger _logger = AppLogger();
  static const String _locationBoxName = 'location_cache';
  static const String _latKey = 'latitude';
  static const String _lngKey = 'longitude';
  static const String _timestampKey = 'timestamp';

  late Box _locationBox;
  bool _initialized = false;

  /// Initialize Hive box for location caching
  Future<void> init() async {
    if (_initialized) {
      _logger.debug('[LocationCache] Already initialized');
      return;
    }

    try {
      _logger.info('[LocationCache] Initializing Hive box...');
      _locationBox = await Hive.openBox(_locationBoxName);
      _initialized = true;
      _logger.info('[LocationCache] Initialized successfully');

      // Log cached location
      final cachedLoc = getLastLocationSync();
      if (cachedLoc != null) {
        _logger.debug('[LocationCache] Cached location: ${cachedLoc['latitude']}, ${cachedLoc['longitude']}');
      }
    } catch (e, stackTrace) {
      _logger.error('[LocationCache] Failed to initialize: $e', stackTrace);
      // Don't rethrow — location cache failure is non-fatal.
      // The service will stay _initialized=false and degrade gracefully.
    }
  }

  /// Save current user location
  Future<void> saveLocation(double latitude, double longitude) async {
    _ensureInitialized();
    try {
      await _locationBox.put(_latKey, latitude);
      await _locationBox.put(_lngKey, longitude);
      await _locationBox.put(_timestampKey, DateTime.now().toIso8601String());
      _logger.debug('[LocationCache] Saved location: $latitude, $longitude');
    } catch (e) {
      _logger.error('[LocationCache] Error saving location: $e');
    }
  }

  /// Get last known location (async)
  Future<Map<String, double>?> getLastLocation() async {
    _ensureInitialized();
    try {
      final lat = _locationBox.get(_latKey);
      final lng = _locationBox.get(_lngKey);

      if (lat != null && lng != null) {
        _logger.debug('[LocationCache] Retrieved cached location: $lat, $lng');
        return {'latitude': lat as double, 'longitude': lng as double};
      }

      _logger.debug('[LocationCache] No cached location found');
      return null;
    } catch (e) {
      _logger.error('[LocationCache] Error getting location: $e');
      return null;
    }
  }

  /// Get last known location (sync version - faster)
  Map<String, double>? getLastLocationSync() {
    if (!_initialized) return null;

    try {
      final lat = _locationBox.get(_latKey);
      final lng = _locationBox.get(_lngKey);

      if (lat != null && lng != null) {
        return {'latitude': lat as double, 'longitude': lng as double};
      }
      return null;
    } catch (e) {
      _logger.error('[LocationCache] Error getting location (sync): $e');
      return null;
    }
  }

  /// Check if cached location exists
  bool hasCachedLocation() {
    if (!_initialized) return false;
    return _locationBox.containsKey(_latKey) && _locationBox.containsKey(_lngKey);
  }

  /// Get cache age
  Duration? getCacheAge() {
    if (!_initialized) return null;

    try {
      final timestamp = _locationBox.get(_timestampKey);
      if (timestamp == null) return null;

      final cachedTime = DateTime.parse(timestamp as String);
      return DateTime.now().difference(cachedTime);
    } catch (e) {
      _logger.error('[LocationCache] Error getting cache age: $e');
      return null;
    }
  }

  /// Clear cached location
  Future<void> clearLocation() async {
    _ensureInitialized();
    try {
      await _locationBox.delete(_latKey);
      await _locationBox.delete(_lngKey);
      await _locationBox.delete(_timestampKey);
      _logger.info('[LocationCache] Location cache cleared');
    } catch (e) {
      _logger.error('[LocationCache] Error clearing location: $e');
    }
  }

  void _ensureInitialized() {
    if (!_initialized) {
      throw StateError('LocationCacheService must be initialized before use. Call init() first.');
    }
  }
}
