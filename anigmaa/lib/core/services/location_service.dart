import 'package:geolocator/geolocator.dart';
import '../utils/app_logger.dart';
import '../constants/app_config.dart';

/// Service for handling location permissions and retrieving user location
/// Provides a clean interface for location-related operations
class LocationService {
  static final AppLogger _logger = AppLogger();

  /// Check if location services are enabled
  static bool get isLocationServiceEnabled => AppConfig.locationServicesEnabled;

  /// Check if location permission is granted
  static Future<LocationPermission> checkPermission() async {
    if (!isLocationServiceEnabled) {
      _logger.warning('Location services are disabled');
      return LocationPermission.denied;
    }

    return await Geolocator.checkPermission();
  }

  /// Request location permission
  static Future<LocationPermission> requestPermission() async {
    if (!isLocationServiceEnabled) {
      _logger.warning('Location services are disabled');
      return LocationPermission.denied;
    }

    _logger.info('Requesting location permission');
    return await Geolocator.requestPermission();
  }

  /// Get current position with permission handling
  static Future<Position?> getCurrentPosition({
    LocationAccuracy desiredAccuracy = LocationAccuracy.high,
    bool forceAndroidLocationManager = false,
    Duration? timeout = const Duration(seconds: 10),
  }) async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _logger.warning('Location services are disabled');
        return null;
      }

      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _logger.warning('Location permission denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _logger.warning('Location permission permanently denied');
        return null;
      }

      // Get position
      _logger.info('Getting current location');
      final position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: desiredAccuracy,
          distanceFilter: 0,
          timeLimit: timeout,
        ),
      );

      _logger.info('Location retrieved: ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e) {
      _logger.error('Failed to get location', e);
      return null;
    }
  }

  /// Open app settings so user can enable location
  static Future<void> openAppSettings() async {
    _logger.info('Opening app settings for location permission');
    await Geolocator.openAppSettings();
  }

  /// Open location settings
  static Future<void> openLocationSettings() async {
    _logger.info('Opening location settings');
    await Geolocator.openLocationSettings();
  }

  /// Calculate distance between two points in meters
  static double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  /// Stream position updates
  static Stream<Position> getPositionStream({
    LocationSettings? locationSettings,
  }) {
    if (!isLocationServiceEnabled) {
      return Stream.error('Location services are disabled');
    }

    return Geolocator.getPositionStream(
      locationSettings: locationSettings ?? const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 100, // Update every 100 meters
      ),
    );
  }
}