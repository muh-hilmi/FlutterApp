// TODO: Enable this service when 'mapbox_api' dependency is added to pubspec.yaml
// import 'package:mapbox_api/mapbox_api.dart';
// import '../utils/app_logger.dart';

// class MapboxPlace {
//   final String id;
//   final String name;
//   final String address;
//   final double latitude;
//   final double longitude;
//   final String? placeName;

//   MapboxPlace({
//     required this.id,
//     required this.name,
//     required this.address,
//     required this.latitude,
//     required this.longitude,
//     this.placeName,
//   });

//   factory MapboxPlace.fromFeature(dynamic feature) {
//     // GeocoderFeature has properties: geometry, id, text, placeName, etc.
//     // Access them directly as properties
//     final geometry = feature.geometry;
//     final coords = geometry?.coordinates as List?;
//     final longitude = coords?[0] as double? ?? 0.0;
//     final latitude = coords?[1] as double? ?? 0.0;

//     // Build address from placeName or text
//     String address = feature.placeName ?? feature.text ?? 'Unknown';

//     return MapboxPlace(
//       id: feature.id ?? '',
//       name: feature.text ?? 'Unknown Place',
//       address: address,
//       latitude: latitude,
//       longitude: longitude,
//       placeName: feature.placeName,
//     );
//   }
// }

// class MapboxService {
//   late final MapboxApi _api;

//   MapboxService(String accessToken) {
//     _api = MapboxApi(accessToken: accessToken);
//     AppLogger().info('MapboxService initialized');
//   }

//   /// Forward geocoding - search for places by query
//   Future<List<MapboxPlace>> searchPlaces({
//     required String query,
//     double? proximityLat,
//     double? proximityLng,
//     int limit = 10,
//   }) async {
//     if (query.trim().isEmpty) return [];

//     try {
//       AppLogger().info('Mapbox search: "\$query"');

//       // Call API differently based on whether proximity is available
//       final response = (proximityLat != null && proximityLng != null)
//           ? await _api.forwardGeocoding.request(
//               searchText: query,
//               limit: limit,
//               fuzzyMatch: true,
//               country: ['ID'],
//               proximity: [proximityLat, proximityLng],
//               language: 'id',
//             )
//           : await _api.forwardGeocoding.request(
//               searchText: query,
//               limit: limit,
//               fuzzyMatch: true,
//               country: ['ID'],
//               language: 'id',
//             );

//       if (response.error != null) {
//         AppLogger().error('Mapbox API error: \${response.error}');
//         return [];
//       }

//       if (response.features == null || response.features!.isEmpty) {
//         AppLogger().info('No results found for "\$query"');
//         return [];
//       }

//       AppLogger().info('Mapbox found \${response.features!.length} results');

//       // Convert features to MapboxPlace
//       final places = response.features!
//           .map((feature) => MapboxPlace.fromFeature(feature))
//           .toList();

//       // Filter: only places with complete addresses (not just city names)
//       final completePlaces = places.where((place) {
//         // Has proper address format (contains street/area info)
//         final hasProperAddress = place.address.split(',').length >= 2;
//         // Coordinates are valid
//         final hasValidCoords = place.latitude != 0 && place.longitude != 0;
//         return hasProperAddress && hasValidCoords;
//       }).toList();

//       AppLogger().info('Filtered to \${completePlaces.length} places with complete addresses');

//       return completePlaces;
//     } catch (e, stackTrace) {
//       AppLogger().error('Error searching Mapbox places: \$e');
//       AppLogger().error('Stack trace: \$stackTrace');
//       return [];
//     }
//   }

//   /// Reverse geocoding - get address from coordinates
//   /// Note: Mapbox API reverse geocoding parameters are different
//   /// Using geocoding package instead for now
//   Future<String?> getAddressFromCoordinates({
//     required double latitude,
//     required double longitude,
//   }) async {
//     // For now, use null - the geocoding package handles this
//     return null;
//   }
// }
