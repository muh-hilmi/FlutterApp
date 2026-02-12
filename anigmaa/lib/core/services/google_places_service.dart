import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/app_logger.dart';

class GooglePlace {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;

  GooglePlace({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  factory GooglePlace.fromAutocompleteJson(Map<String, dynamic> json) {
    final placeId = json['place_id'] as String?;
    final description = json['description'] as String? ?? 'Unknown';

    // For autocomplete, we don't have coordinates yet
    // Need to do a details call to get coordinates
    return GooglePlace(
      id: placeId ?? '',
      name: description.split(',')[0], // First part is usually the name
      address: description,
      latitude: 0.0,
      longitude: 0.0,
    );
  }

  factory GooglePlace.fromDetailsJson(Map<String, dynamic> json) {
    final placeId = json['place_id'] as String?;
    final name = json['name'] as String? ?? 'Unknown';
    final address = json['formatted_address'] as String? ?? 'Unknown';

    final location = json['geometry']?['location'];
    final lat = location?['lat'] as double?;
    final lng = location?['lng'] as double?;

    return GooglePlace(
      id: placeId ?? '',
      name: name,
      address: address,
      latitude: lat ?? 0.0,
      longitude: lng ?? 0.0,
    );
  }

  /// Update coordinates from details response
  GooglePlace copyWithCoordinates(double lat, double lng) {
    return GooglePlace(
      id: id,
      name: name,
      address: address,
      latitude: lat,
      longitude: lng,
    );
  }
}

class GooglePlacesService {
  final String _apiKey;
  final String _baseUrl = 'https://maps.googleapis.com/maps/api';

  GooglePlacesService(this._apiKey) {
    AppLogger().info('GooglePlacesService initialized');
  }

  /// Global autocomplete search - NO radius limit
  ///
  /// Used for MANUAL search (user typing):
  /// - NO location/radius constraints
  /// - Can find famous places anywhere (Monas, Bali, etc.)
  /// - Filters by country only (components=country:id)
  /// - Later filtered by ratings (4.0+ rating, 100+ reviews)
  ///
  /// Use this when:
  /// - User is manually typing/searching
  /// - Looking for famous/landmark places
  /// - Location is unknown or not relevant
  ///
  /// For NEARBY search (places around user), use `autocompleteNearby()` instead.
  Future<List<GooglePlace>> autocomplete({
    required String query,
    String? sessionToken,
    String language = 'id',
    String region = 'id',
  }) async {
    if (query.trim().isEmpty) return [];

    try {
      final url = Uri.parse('$_baseUrl/place/autocomplete/json').replace(
        queryParameters: {
          'input': query,
          'key': _apiKey,
          'language': language,
          'components': 'country:$region',
          if (sessionToken != null) 'sessiontoken': sessionToken,
        },
      );

      AppLogger().info('Google autocomplete: $query');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final predictions = data['predictions'] as List? ?? [];

        AppLogger().info('Found ${predictions.length} predictions');

        return predictions
            .map((p) => GooglePlace.fromAutocompleteJson(p))
            .toList();
      } else {
        AppLogger().error('Google API error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      AppLogger().error('Error in autocomplete: $e');
      return [];
    }
  }

  /// Get place details (including coordinates) from place_id
  Future<GooglePlace?> getPlaceDetails(
    String placeId, {
    String? sessionToken,
    String language = 'id',
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/place/details/json').replace(
        queryParameters: {
          'place_id': placeId,
          'key': _apiKey,
          'language': language,
          if (sessionToken != null) 'sessiontoken': sessionToken,
        },
      );

      AppLogger().info('Getting place details for: $placeId');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final result = data['result'];

        if (result != null) {
          return GooglePlace.fromDetailsJson(result);
        }
      } else {
        AppLogger().error('Google API error: ${response.statusCode}');
      }

      return null;
    } catch (e) {
      AppLogger().error('Error getting place details: $e');
      return null;
    }
  }

  /// Location-based autocomplete with 50km radius constraint
  ///
  /// Used for NEARBY search (auto-load places around user):
  /// - strictbounds: true → ONLY returns places within 50km radius
  /// - Filters by popular place types (establishment, tourist_attraction, etc.)
  /// - Later filtered by ratings (3.5+ rating, 50+ reviews)
  ///
  /// Use this when:
  /// - User has location enabled
  /// - Loading nearby places automatically
  /// - Showing "what's around me"
  ///
  /// For GLOBAL search (user typing famous places), use `autocomplete()` instead.
  Future<List<GooglePlace>> autocompleteNearby({
    required String query,
    required double latitude,
    required double longitude,
    String? sessionToken,
    String language = 'id',
    String region = 'id',
    int radius = 50000, // 50km in meters
  }) async {
    if (query.trim().isEmpty) return [];

    try {
      final url = Uri.parse('$_baseUrl/place/autocomplete/json').replace(
        queryParameters: {
          'input': query,
          'key': _apiKey,
          'language': language,
          'components': 'country:$region',
          'location': '$latitude,$longitude',
          'radius': radius.toString(),
          'strictbounds': 'true',
          if (sessionToken != null) 'sessiontoken': sessionToken,
        },
      );

      AppLogger().info(
        'Google nearby autocomplete: $query near $latitude,$longitude',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final predictions = data['predictions'] as List? ?? [];

        AppLogger().info(
          'Found ${predictions.length} predictions (radius: ${radius}m)',
        );

        // Filter for popular/famous places only
        final popularPredictions = predictions.where((prediction) {
          final types = prediction['types'] as List? ?? [];
          final typesSet = types.cast<String>();

          // Check if place has famous/popular types
          final popularTypes = {
            'establishment',
            'point_of_interest',
            'tourist_attraction',
            'lodging',
            'restaurant',
            'shopping_mall',
            'museum',
            'park',
            'amusement_park',
            'aquarium',
            'art_gallery',
            'casino',
            'night_club',
            'stadium',
            'zoo',
          };

          // Place must have at least one popular type
          return typesSet.any((type) => popularTypes.contains(type));
        }).toList();

        AppLogger().info(
          'Filtered to ${popularPredictions.length} popular places',
        );

        return popularPredictions
            .map((p) => GooglePlace.fromAutocompleteJson(p))
            .toList();
      } else {
        AppLogger().error('Google API error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      AppLogger().error('Error in nearby autocomplete: $e');
      return [];
    }
  }

  /// Full search with autocomplete + details (returns places with coordinates)
  /// Uses parallel requests for faster performance
  ///
  /// **IMPORTANT**: Two search modes:
  /// 1. **Manual search (no location)** → GLOBAL, searches everywhere, filters by popularity (rating 4.0+, 100+ reviews)
  /// 2. **Nearby search (with location)** → 50km radius with strictbounds, filters by popular types + ratings
  ///
  /// Examples:
  /// - `searchPlaces(query: "Monas")` → Global search, can find Monas anywhere in Indonesia
  /// - `searchPlaces(query: "restoran", latitude: -7.55, longitude: 110.83)` → Nearby search, 50km radius only
  Future<List<GooglePlace>> searchPlaces({
    required String query,
    String language = 'id',
    String region = 'id',
    int limit = 10,
    double? latitude,
    double? longitude,
  }) async {
    // Get autocomplete predictions based on search mode
    final predictions = latitude != null && longitude != null
        ? await autocompleteNearby(
            query: query,
            latitude: latitude,
            longitude: longitude,
            language: language,
            region: region,
          )
        : await autocomplete(query: query, language: language, region: region);

    if (predictions.isEmpty) return [];

    // Limit results
    final limitedPredictions = predictions.take(limit).toList();

    // Get details for each prediction IN PARALLEL using Future.wait
    // This is much faster than sequential await in a loop
    final detailFutures = limitedPredictions
        .map((prediction) => getPlaceDetails(prediction.id, language: language))
        .toList();

    // Wait for all detail requests to complete simultaneously
    final detailsList = await Future.wait(detailFutures);

    // Filter out null results and places without valid coordinates
    final places = detailsList
        .where((details) => details != null && details.latitude != 0.0)
        .cast<GooglePlace>()
        .toList();

    // Apply popularity filtering for BOTH search modes
    // - Global search: Filter by rating 4.0+ and 100+ reviews
    // - Nearby search: More lenient - rating 3.5+ and 50+ reviews (already filtered by popular types)
    if (places.isNotEmpty) {
      final isNearby = latitude != null && longitude != null;
      final popularPlaces = await _filterByPopularity(
        places,
        isNearby: isNearby,
      );

      if (isNearby) {
        AppLogger().info(
          'Returned ${popularPlaces.length} popular nearby places (50km radius)',
        );
      } else {
        AppLogger().info(
          'Returned ${popularPlaces.length} popular global places',
        );
      }

      return popularPlaces;
    }

    AppLogger().info(
      'Returned ${places.length} places with coordinates (parallel fetch)',
    );
    return places;
  }

  /// Filter places by rating and review count
  ///
  /// For GLOBAL search: Only returns places with rating >= 4.0 and 100+ reviews
  /// For NEARBY search: More lenient - rating >= 3.5 and 50+ reviews (already filtered by popular types)
  Future<List<GooglePlace>> _filterByPopularity(
    List<GooglePlace> places, {
    bool isNearby = false,
  }) async {
    if (places.isEmpty) return places;

    try {
      // Get detailed information for each place to check ratings
      final detailFutures = places
          .map((place) => _getPlaceDetailsWithRating(place.id))
          .toList();

      final detailsList = await Future.wait(detailFutures);

      final popularPlaces = <GooglePlace>[];

      // Set thresholds based on search mode
      final minRating = isNearby ? 3.5 : 4.0;
      final minReviews = isNearby ? 50 : 100;

      AppLogger().info(
        'Filtering ${places.length} places (min rating: $minRating, min reviews: $minReviews)',
      );

      for (var i = 0; i < places.length; i++) {
        final details = detailsList[i];
        if (details != null) {
          final rating = details['rating'] as num?;
          final reviewCount = details['user_ratings_total'] as num?;

          // Filter for high-rated and popular places
          if ((rating?.toDouble() ?? 0.0) >= minRating &&
              (reviewCount?.toInt() ?? 0) >= minReviews) {
            popularPlaces.add(places[i]);
            AppLogger().info(
              '✓ Included: ${places[i].name} (rating: $rating, reviews: $reviewCount)',
            );
          } else {
            AppLogger().info(
              '✗ Excluded: ${places[i].name} (rating: $rating, reviews: $reviewCount)',
            );
          }
        } else {
          // If we can't get details, include it anyway (better than nothing)
          popularPlaces.add(places[i]);
          AppLogger().info('? Included (no rating data): ${places[i].name}');
        }
      }

      return popularPlaces.isEmpty ? places : popularPlaces;
    } catch (e) {
      AppLogger().error('Error filtering by popularity: $e');
      return places;
    }
  }

  /// Get place details with rating information
  Future<Map<String, dynamic>?> _getPlaceDetailsWithRating(
    String placeId, {
    String? sessionToken,
    String language = 'id',
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/place/details/json').replace(
        queryParameters: {
          'place_id': placeId,
          'key': _apiKey,
          'language': language,
          'fields':
              'place_id,name,formatted_address,geometry,rating,user_ratings_total',
          if (sessionToken != null) 'sessiontoken': sessionToken,
        },
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['result'] as Map<String, dynamic>?;
      }

      return null;
    } catch (e) {
      AppLogger().error('Error getting place details with rating: $e');
      return null;
    }
  }

  /// Reverse geocoding - get address from coordinates
  Future<String?> getAddressFromCoordinates({
    required double latitude,
    required double longitude,
    String language = 'id',
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/geocode/json').replace(
        queryParameters: {
          'latlng': '$latitude,$longitude',
          'key': _apiKey,
          'language': language,
        },
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List? ?? [];

        if (results.isNotEmpty) {
          return results[0]['formatted_address'] as String?;
        }
      }

      return null;
    } catch (e) {
      AppLogger().error('Error reverse geocoding: $e');
      return null;
    }
  }
}
