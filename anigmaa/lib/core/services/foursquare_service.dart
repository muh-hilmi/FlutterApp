import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/app_logger.dart';

class FoursquarePlace {
  final String fsqId;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String? category;
  final int? distance;

  // Track raw location data for complete address check
  final bool _hasCompleteAddress;

  FoursquarePlace({
    required this.fsqId,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.category,
    this.distance,
    bool hasCompleteAddress = true,
  }) : _hasCompleteAddress = hasCompleteAddress;

  /// Check if this place has a complete address (street + locality)
  /// Complete address means: has street address AND locality/city
  bool get hasCompleteAddress => _hasCompleteAddress;

  factory FoursquarePlace.fromJson(Map<String, dynamic> json) {
    final location = json['location'];

    // Check if location has complete address data
    // Complete = has street address AND locality (at minimum)
    bool hasCompleteAddress = false;
    if (location != null) {
      final hasStreet = location['address'] != null &&
          location['address'].toString().trim().isNotEmpty;
      final hasLocality = location['locality'] != null &&
          location['locality'].toString().trim().isNotEmpty;
      final hasFormattedAddr = location['formatted_address'] != null &&
          location['formatted_address'].toString().trim().isNotEmpty &&
          location['formatted_address'].toString() != 'ID';

      hasCompleteAddress = hasFormattedAddr || (hasStreet && hasLocality);
    }

    // Parse address - PRIORITY: formatted_address > build from parts > "Indonesia"
    String address = '';

    // 1. Try formatted_address first (most complete)
    if (location != null && location['formatted_address'] != null) {
      final formatted = location['formatted_address'].toString();
      if (formatted.isNotEmpty && formatted != 'ID') {
        address = formatted;
      }
    }

    // 2. Build from parts if formatted_address is empty
    if (address.isEmpty && location != null) {
      List<String> addressParts = [];
      if (location['address'] != null &&
          location['address'].toString().isNotEmpty) {
        addressParts.add(location['address']);
      }
      if (location['locality'] != null &&
          location['locality'].toString().isNotEmpty) {
        addressParts.add(location['locality']);
      }
      if (location['region'] != null &&
          location['region'].toString().isNotEmpty) {
        addressParts.add(location['region']);
      }
      if (location['country'] != null &&
          location['country'].toString().isNotEmpty &&
          location['country'].toString() != 'ID') {
        addressParts.add(location['country']);
      }
      address = addressParts.join(', ');
    }

    // 3. Fallback to "Indonesia" if still empty
    if (address.isEmpty) {
      address = 'Indonesia';
    }

    // Parse category
    String? category;
    if (json['categories'] != null && (json['categories'] as List).isNotEmpty) {
      category = json['categories'][0]['name'];
    }

    // Parse coordinates - FIXED: Try top-level first (actual API format)
    double? latitude;
    double? longitude;

    // 1. Try top-level latitude/longitude (ACTUAL Foursquare API format)
    if (json['latitude'] != null && json['longitude'] != null) {
      latitude = json['latitude']?.toDouble();
      longitude = json['longitude']?.toDouble();
    }

    // 2. Try geocodes.main (for legacy/documentation format)
    if ((latitude == null || longitude == null) && json['geocodes']?['main'] != null) {
      final geocodes = json['geocodes']['main'];
      latitude = geocodes['latitude']?.toDouble();
      longitude = geocodes['longitude']?.toDouble();
    }

    // 3. Try direct geocodes (without main)
    if ((latitude == null || longitude == null) && json['geocodes'] != null) {
      final directGeo = json['geocodes'];
      latitude = directGeo['latitude']?.toDouble();
      longitude = directGeo['longitude']?.toDouble();
    }

    // 4. Try location object
    if ((latitude == null || longitude == null) && location != null) {
      latitude = location['latitude']?.toDouble();
      longitude = location['longitude']?.toDouble();
    }

    // 5. Try geo field (some APIs use this)
    if ((latitude == null || longitude == null) && json['geo'] != null) {
      final geo = json['geo'];
      latitude = geo['latitude']?.toDouble() ?? geo['lat']?.toDouble();
      longitude = geo['longitude']?.toDouble() ?? geo['lng']?.toDouble();
    }

    // 6. Try top-level lat/lng (alternative names)
    if (latitude == null || longitude == null) {
      latitude = json['lat']?.toDouble();
      longitude = json['lng']?.toDouble();
    }

    // If still no coordinates, throw error to skip this place
    if (latitude == null ||
        longitude == null ||
        (latitude == 0.0 && longitude == 0.0)) {
      final placeName = json['name'] ?? 'Unknown';
      AppLogger().warning(
        'Skipping place "$placeName" - no valid coordinates found',
      );
      throw Exception('Invalid coordinates for place: $placeName');
    }

    return FoursquarePlace(
      fsqId: json['fsq_place_id'] ?? json['fsq_id'] ?? '',
      name: json['name'] ?? 'Unknown Place',
      address: address,
      latitude: latitude,
      longitude: longitude,
      category: category,
      distance: json['distance'],
      hasCompleteAddress: hasCompleteAddress,
    );
  }
}

class FoursquareService {
  // IMPORTANT: Replace with your actual Foursquare API key
  // Get it from: https://foursquare.com/developers/apps
  static const String _apiKey =
      'HBPGD0IN2KVQSDGXRWDTQ42PPLUY0AF3TLXVDWMFCGF040KN';
  static const String _baseUrl = 'https://places-api.foursquare.com';

  /// Search for places near a location
  ///
  /// [query] - Search query (e.g., "restaurant", "coffee")
  /// [latitude] - Latitude of the search center
  /// [longitude] - Longitude of the search center
  /// [radius] - Search radius in meters (default: 5000)
  /// [limit] - Maximum number of results (default: 20)
  Future<List<FoursquarePlace>> searchPlaces({
    required String query,
    required double latitude,
    required double longitude,
    int radius = 5000,
    int limit = 20,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/places/search').replace(
        queryParameters: {
          'query': query,
          'll': '$latitude,$longitude',
          'radius': radius.toString(),
          'limit': limit.toString(),
        },
      );

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Accept': 'application/json',
          'X-Places-Api-Version': '2025-06-17',
        },
      );

      AppLogger().info('Foursquare search request: ${url.toString()}');
      AppLogger().info('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Handle different response formats
        List<dynamic>? results;
        if (data['results'] != null) {
          results = data['results'] as List<dynamic>?;
        } else if (data is List) {
          results = data;
        }

        if (results == null || results.isEmpty) {
          AppLogger().warning('No results found in search');
          return [];
        }

        AppLogger().info('Foursquare search found ${results.length} places');

        // Parse places with error handling
        final places = <FoursquarePlace>[];
        for (var placeJson in results) {
          try {
            places.add(FoursquarePlace.fromJson(placeJson));
          } catch (e) {
            AppLogger().error('Failed to parse search place: $e');
            // Continue processing other places
          }
        }

        // FILTER: Only show places with complete addresses
        final completeAddressPlaces = places
            .where((place) => place.hasCompleteAddress)
            .toList();

        AppLogger().info('Filtered to ${completeAddressPlaces.length} places with complete addresses');

        // Sort by distance - closest places first
        completeAddressPlaces.sort((a, b) {
          if (a.distance != null && b.distance != null) {
            return a.distance!.compareTo(b.distance!);
          }
          return 0;
        });

        // Optional: Prioritize exact name matches
        final exactMatches = completeAddressPlaces.where((p) => p.name.toLowerCase().contains(query.toLowerCase())).toList();
        final otherMatches = completeAddressPlaces.where((p) => !p.name.toLowerCase().contains(query.toLowerCase())).toList();

        return [...exactMatches, ...otherMatches];
      } else {
        AppLogger().error(
          'Foursquare API error: ${response.statusCode} - ${response.body}',
        );
        return [];
      }
    } catch (e, stackTrace) {
      AppLogger().error('Error searching places: $e');
      AppLogger().error('Stack trace: $stackTrace');
      return [];
    }
  }

  /// Get nearby places (without specific query)
  ///
  /// [latitude] - Latitude of the search center
  /// [longitude] - Longitude of the search center
  /// [radius] - Search radius in meters (default: 1000)
  /// [limit] - Maximum number of results (default: 50)
  Future<List<FoursquarePlace>> getNearbyPlaces({
    required double latitude,
    required double longitude,
    int radius = 1000,
    int limit = 50,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/geotagging/candidates').replace(
        queryParameters: {
          'll': '$latitude,$longitude',
          'radius': radius.toString(),
          'limit': limit.toString(),
        },
      );

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Accept': 'application/json',
          'X-Places-Api-Version': '2025-06-17',
        },
      );

      AppLogger().info('Foursquare nearby request: ${url.toString()}');
      AppLogger().info('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Log the response structure for debugging
        AppLogger().info('Response data keys: ${data.keys.toList()}');

        // Handle different response formats
        List<dynamic>? results;
        if (data['results'] != null) {
          results = data['results'] as List<dynamic>?;
        } else if (data['candidates'] != null) {
          results = data['candidates'] as List<dynamic>?;
        } else if (data is List) {
          results = data;
        }

        if (results == null || results.isEmpty) {
          AppLogger().warning(
            'No results found in response. Response body: ${response.body}',
          );
          return [];
        }

        AppLogger().info('Foursquare nearby found ${results.length} places');

        // Parse places with error handling
        final places = <FoursquarePlace>[];
        for (var placeJson in results) {
          try {
            places.add(FoursquarePlace.fromJson(placeJson));
          } catch (e) {
            AppLogger().error('Failed to parse nearby place: $e');
            // Continue processing other places
          }
        }

        // FILTER: Only show places with complete addresses
        final completeAddressPlaces = places
            .where((place) => place.hasCompleteAddress)
            .toList();

        AppLogger().info('Filtered to ${completeAddressPlaces.length} places with complete addresses');

        return completeAddressPlaces;
      } else {
        AppLogger().error(
          'Foursquare API error: ${response.statusCode} - ${response.body}',
        );
        return [];
      }
    } catch (e, stackTrace) {
      AppLogger().error('Error getting nearby places: $e');
      AppLogger().error('Stack trace: $stackTrace');
      return [];
    }
  }

  /// Get autocomplete suggestions for a query
  ///
  /// Uses the /places/search endpoint instead of /autocomplete because
  /// the autocomplete endpoint doesn't return full geocodes.
  ///
  /// [query] - Search query
  /// [latitude] - Latitude of the search center
  /// [longitude] - Longitude of the search center
  /// [limit] - Maximum number of results (default: 10)
  Future<List<FoursquarePlace>> getAutocompleteSuggestions({
    required String query,
    required double latitude,
    required double longitude,
    int limit = 30,
  }) async {
    if (query.trim().isEmpty) return [];

    try {
      // Use search endpoint instead of autocomplete for better geocode coverage
      final url = Uri.parse('$_baseUrl/places/search').replace(
        queryParameters: {
          'query': query,
          'll': '$latitude,$longitude',
          'limit': limit.toString(),
          'radius': '50000', // 50km radius for search
          'sort': 'DISTANCE', // Prioritize nearest places
        },
      );

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Accept': 'application/json',
          'X-Places-Api-Version': '2025-06-17',
        },
      );

      AppLogger().info('Foursquare search request: ${url.toString()}');
      AppLogger().info('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Handle different response formats
        List<dynamic>? results;
        if (data['results'] != null) {
          results = data['results'] as List<dynamic>?;
        } else if (data is List) {
          results = data;
        }

        if (results == null || results.isEmpty) {
          AppLogger().warning('No results found in search');
          return [];
        }

        AppLogger().info('Foursquare search found ${results.length} places');

        // Parse places with error handling
        final places = <FoursquarePlace>[];
        for (var placeJson in results) {
          try {
            places.add(FoursquarePlace.fromJson(placeJson));
          } catch (e) {
            AppLogger().error('Failed to parse search place: $e');
            // Continue processing other places
          }
        }

        AppLogger().info('Parsed ${places.length} valid places');

        // FILTER: Only show places with complete addresses
        // Complete = has street address AND locality/city
        final completeAddressPlaces = places
            .where((place) => place.hasCompleteAddress)
            .toList();

        final filteredCount = places.length - completeAddressPlaces.length;
        if (filteredCount > 0) {
          AppLogger().info('Filtered out $filteredCount places with incomplete addresses');
        }
        AppLogger().info('Returning ${completeAddressPlaces.length} places with complete addresses');

        return completeAddressPlaces;
      } else {
        AppLogger().error(
          'Foursquare API error: ${response.statusCode} - ${response.body}',
        );
        return [];
      }
    } catch (e, stackTrace) {
      AppLogger().error('Error getting autocomplete suggestions: $e');
      AppLogger().error('Stack trace: $stackTrace');
      return [];
    }
  }

  /// Get place details by Foursquare ID
  ///
  /// [fsqId] - Foursquare place ID
  Future<FoursquarePlace?> getPlaceDetails(String fsqId) async {
    try {
      final url = Uri.parse('$_baseUrl/places/$fsqId');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Accept': 'application/json',
          'X-Places-Api-Version': '2025-06-17',
        },
      );

      AppLogger().info('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        AppLogger().info('Foursquare place details retrieved');
        return FoursquarePlace.fromJson(data);
      } else {
        AppLogger().error(
          'Foursquare API error: ${response.statusCode} - ${response.body}',
        );
        return null;
      }
    } catch (e) {
      AppLogger().error('Error getting place details: $e');
      return null;
    }
  }
}
