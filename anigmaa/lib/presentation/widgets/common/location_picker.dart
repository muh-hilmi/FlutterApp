import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/services/google_places_service.dart';
import '../../../core/theme/app_colors.dart';
import 'snackbar_helper.dart';

class LocationData {
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String? placeId; // Google place ID (optional)

  LocationData({
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.placeId,
  });
}

class LocationPicker extends StatefulWidget {
  final Function(LocationData) onLocationSelected;
  final LocationData? initialLocation;

  const LocationPicker({
    super.key,
    required this.onLocationSelected,
    this.initialLocation,
  });

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  final Completer<GoogleMapController> _mapController = Completer();
  final TextEditingController _searchController = TextEditingController();

  // Google Places service
  late final GooglePlacesService _placesService;
  String? _googleMapsApiKey;

  // Debounce timer for search
  Timer? _debounceTimer;

  LatLng _currentPosition = const LatLng(
    -7.5568,
    110.8316,
  ); // Default: Solo, Indonesia
  String _currentAddress = 'Memuat lokasi...';
  String _locationName = '';
  bool _isLoadingAddress = false;
  bool _isLoadingLocation = true;
  bool _showSearchResults = false;
  List<GooglePlace> _searchResults = [];
  List<GooglePlace> _nearbyPlaces = [];
  String? _selectedPlaceId;
  String? _lastSelectedPlaceName; // Track last selected place for feedback

  // Set of markers for the map
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    // Initialize Google Places service
    _googleMapsApiKey = dotenv.env['GOOGLE_MAPS_API_KEY'];
    if (_googleMapsApiKey == null || _googleMapsApiKey!.isEmpty) {
      AppLogger().error('GOOGLE_MAPS_API_KEY not found in .env file!');
    }
    _placesService = GooglePlacesService(_googleMapsApiKey ?? '');

    // Load map immediately with default location (Solo, Indonesia)
    // Get GPS in background to avoid blocking UI
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _initializeLocation();
        }
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel(); // Cancel debounce timer
    super.dispose();
  }

  Future<void> _initializeLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) setState(() => _isLoadingLocation = false);
        _showError('Layanan lokasi tidak aktif. Aktifkan GPS terlebih dahulu.');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) setState(() => _isLoadingLocation = false);
          _showError('Permission lokasi ditolak');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) setState(() => _isLoadingLocation = false);
        _showError('Permission lokasi ditolak permanen. Aktifkan di Settings.');
        return;
      }

      // Step 1: Try last known position first — instant, no GPS wait
      try {
        final lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null && mounted) {
          setState(() {
            _currentPosition = LatLng(lastKnown.latitude, lastKnown.longitude);
            _isLoadingLocation = false;
          });
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _animateMapToPosition(_currentPosition, zoom: 16.0);
          });
          // Start address + nearby in parallel, don't await
          Future.wait([
            _updateAddress(_currentPosition),
            _loadNearbyPlaces(),
          ]);
        }
      } catch (_) {}

      // Step 2: Get fresh GPS position with a hard timeout
      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 6),
        ),
      );

      if (!mounted) return;

      final newPos = LatLng(position.latitude, position.longitude);
      setState(() {
        _currentPosition = newPos;
        _isLoadingLocation = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _animateMapToPosition(newPos, zoom: 16.0);
      });

      // Address + nearby places in parallel (not sequential)
      await Future.wait([
        _updateAddress(newPos),
        _loadNearbyPlaces(),
      ]);
    } catch (e) {
      AppLogger().debug('GPS error (using default/last known): $e');
      if (mounted) setState(() => _isLoadingLocation = false);
      // Only show error if we have no position at all (still at default)
      if (_locationName.isEmpty) {
        _showError('Gagal mendapatkan lokasi GPS. Cari manual atau tap di peta.');
      }
    }
  }

  Future<void> _loadNearbyPlaces() async {
    try {
      AppLogger().info('Requesting nearby places from Google:');
      AppLogger().info('Center: ${_currentPosition.latitude}, ${_currentPosition.longitude}');
      _validateCoordinates('Google request', _currentPosition.latitude, _currentPosition.longitude);

      // Search for nearby places using Google Places
      // Reduced limit from 20 to 10 for faster initial load
      final places = await _placesService.searchPlaces(
        query: 'restoran kafe stadion universitas mall', // Generic POI search
        limit: 10, // Reduced from 20 for better performance
      );

      AppLogger().info('=== NEARBY PLACES DEBUG START ===');
      AppLogger().info('Received ${places.length} places:');
      for (int i = 0; i < places.length && i < 5; i++) { // Log first 5
        final place = places[i];
        AppLogger().info('Place $i: ${place.name}');
        AppLogger().info('  Coordinates: ${place.latitude}, ${place.longitude}');
        AppLogger().info('  Address: ${place.address}');
        _validateCoordinates('Nearby place $i', place.latitude, place.longitude);
      }
      AppLogger().info('=== NEARBY PLACES DEBUG END ===');

      if (mounted) {
        setState(() {
          _nearbyPlaces = places;
          _updateMarkers();
        });
      }

      AppLogger().info('Loaded ${places.length} nearby places from Google');
    } catch (e) {
      AppLogger().error('Error loading nearby places: $e');
    }
  }

  /// Update markers on the map
  void _updateMarkers() {
    Set<Marker> markers = {};

    // Add nearby places markers (green)
    for (final place in _nearbyPlaces) {
      markers.add(
        Marker(
          markerId: MarkerId('nearby_${place.id}'),
          position: LatLng(place.latitude, place.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          onTap: () => _selectSearchResult(place),
          infoWindow: InfoWindow(
            title: place.name,
            snippet: place.address,
          ),
        ),
      );
    }

    // Add current position marker (custom emoji marker handled by UI overlay)
    // Note: The emoji marker 📍 is handled separately in the UI overlay

    setState(() {
      _markers = markers;
    });
  }

  Future<void> _animateMapToPosition(LatLng position, {double zoom = 16.0}) async {
    if (!mounted) return;

    try {
      final controller = await _mapController.future;
      controller.animateCamera(CameraUpdate.newLatLngZoom(position, zoom));
      AppLogger().info('Map moved to: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      AppLogger().warning('Failed to move map: $e');
    }
  }

  /// Validate if coordinates make sense for Indonesia region
  /// Indonesia is roughly between lat: -10 to 6, lng: 95 to 141
  void _validateCoordinates(String context, double lat, double lng) {
    AppLogger().info('COORD VALIDATE [$context]: Lat=$lat, Lng=$lng');

    // Basic range validation
    if (lat < -90 || lat > 90) {
      AppLogger().error('INVALID COORDINATE: Latitude out of range: $lat');
    }
    if (lng < -180 || lng > 180) {
      AppLogger().error('INVALID COORDINATE: Longitude out of range: $lng');
    }

    // Indonesia region sanity check (Solo is approximately -7.55, 110.83)
    if (lat < -20 || lat > 20) {
      AppLogger().warning('POSSIBLE SWAP: Latitude $lat seems far from Indonesia (-7.5)');
    }
    if (lng < 80 || lng > 150) {
      AppLogger().warning('POSSIBLE SWAP: Longitude $lng seems far from Indonesia (110.8)');
    }

    // Check for obvious swap (lat in lng range and vice versa)
    if (lat >= 80 && lat <= 150 && lng >= -20 && lng <= 20) {
      AppLogger().error('!!! COORDINATE SWAP DETECTED !!!');
      AppLogger().error('Lat=$lat looks like longitude, Lng=$lng looks like latitude');
      AppLogger().error('Coordinates should be swapped!');
    }
  }

  Future<void> _updateAddress(LatLng position) async {
    if (!mounted) return;
    setState(() => _isLoadingAddress = true);

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        if (mounted) {
          setState(() {
            _locationName = _getLocationName(place);
            _currentAddress = _formatAddress(place);
            _isLoadingAddress = false;
          });
        }
        AppLogger().info('Address updated: $_currentAddress');
      }
    } catch (e) {
      AppLogger().error('Error updating address: $e');
      if (mounted) {
        setState(() {
          _currentAddress = 'Alamat tidak ditemukan';
          _locationName = 'Lokasi Terpilih';
          _isLoadingAddress = false;
        });
      }
    }
  }

  String _getLocationName(Placemark place) {
    // Use subAdministrativeArea for profile location (e.g., "Kabupaten Boyolali")
    if (place.subAdministrativeArea != null &&
        place.subAdministrativeArea!.isNotEmpty) {
      return place.subAdministrativeArea!;
    }
    // Fallback to locality
    if (place.locality != null && place.locality!.isNotEmpty) {
      return place.locality!;
    }
    // Last resort: name (but avoid overly specific names)
    if (place.name != null &&
        place.name!.isNotEmpty &&
        place.name!.length < 50) {
      return place.name!;
    }
    return 'Lokasi Terpilih';
  }

  String _formatAddress(Placemark place) {
    // Only use subAdministrativeArea (e.g., "Kabupaten Boyolali" → "Boyolali")
    if (place.subAdministrativeArea != null &&
        place.subAdministrativeArea!.isNotEmpty) {
      return place.subAdministrativeArea!;
    }
    // Fallback to locality if subAdministrativeArea is not available
    if (place.locality != null && place.locality!.isNotEmpty) {
      return place.locality!;
    }
    return 'Alamat tidak tersedia';
  }

  Future<void> _searchLocation(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _showSearchResults = false;
        _searchResults = [];
      });
      return;
    }

    // Cancel previous timer if user is still typing
    _debounceTimer?.cancel();

    // Show loading state immediately for better UX
    setState(() => _isLoadingAddress = true);

    // Debounce: wait 500ms after user stops typing before searching
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      try {
        // Use Google Places for search with reduced limit for faster results
        final places = await _placesService.searchPlaces(
          query: query,
          limit: 15, // Reduced from 30 for faster search
        );

        if (mounted) {
          setState(() {
            _searchResults = places;
            _showSearchResults = true;
            _isLoadingAddress = false;
          });
        }

        AppLogger().info('Search found ${places.length} results');
      } catch (e) {
        AppLogger().error('Error searching location: $e');
        if (mounted) {
          _showError('Gagal mencari lokasi. Coba lagi.');
          setState(() => _isLoadingAddress = false);
        }
      }
    });
  }

  void _selectSearchResult(GooglePlace place) {
    AppLogger().info('=== SELECT SEARCH RESULT DEBUG START ===');
    AppLogger().info('Place: ${place.name}');
    AppLogger().info('Google - Lat: ${place.latitude}, Lng: ${place.longitude}');
    AppLogger().info('Google - Address: ${place.address}');

    // Validate coordinates are within valid ranges
    if (place.latitude < -90 || place.latitude > 90) {
      AppLogger().error('Invalid latitude: ${place.latitude} (must be between -90 and 90)');
      _showError('Koordinat lokasi tidak valid. Coba pilih lokasi lain.');
      return;
    }
    if (place.longitude < -180 || place.longitude > 180) {
      AppLogger().error('Invalid longitude: ${place.longitude} (must be between -180 and 180)');
      _showError('Koordinat lokasi tidak valid. Coba pilih lokasi lain.');
      return;
    }

    final newPosition = LatLng(place.latitude, place.longitude);
    AppLogger().info('LatLng created - Lat: ${newPosition.latitude}, Lng: ${newPosition.longitude}');
    _validateCoordinates('After LatLng creation', newPosition.latitude, newPosition.longitude);

    // BEFORE setState
    AppLogger().info('BEFORE setState - Current _currentPosition: ${_currentPosition.latitude}, ${_currentPosition.longitude}');

    // Close search results
    setState(() {
      _showSearchResults = false;
      _searchController.clear();
      // Update position IMMEDIATELY - no delay
      _currentPosition = newPosition;
      _locationName = place.name;
      _currentAddress = place.address;
      _selectedPlaceId = place.id;
    });

    // AFTER setState
    AppLogger().info('AFTER setState - New _currentPosition: ${_currentPosition.latitude}, ${_currentPosition.longitude}');

    // Move map IMMEDIATELY after state update
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        AppLogger().info('POST FRAME - About to move map to: ${newPosition.latitude}, ${newPosition.longitude}');

        try {
          _animateMapToPosition(newPosition, zoom: 16.0);
          AppLogger().info('POST FRAME - Map move called successfully');
        } catch (e) {
          AppLogger().error('POST FRAME - Failed to move map: $e');
        }

        // Load nearby places (background, no await needed)
        unawaited(_loadNearbyPlaces());

        // Show success feedback
        _lastSelectedPlaceName = place.name;
        _showLocationSelectedFeedback(place.name);
      }
    });

    AppLogger().info(
      'Selected place: ${place.name} at ${place.latitude}, ${place.longitude}',
    );

    AppLogger().info('=== SELECT SEARCH RESULT DEBUG END ===');
  }

  /// Show visual feedback when location is selected
  void _showLocationSelectedFeedback(String placeName) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Lokasi Terpilih',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    placeName,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFBBC863),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _onMapTap(LatLng position) {
    AppLogger().info('=== MAP TAP DEBUG START ===');
    AppLogger().info('Before tap - _currentPosition: ${_currentPosition.latitude}, ${_currentPosition.longitude}');
    AppLogger().info('Tapped position: ${position.latitude}, ${position.longitude}');
    _validateCoordinates('On map tap', position.latitude, position.longitude);

    setState(() {
      _currentPosition = position;
      _selectedPlaceId = null; // Clear Mapbox ID when manually selecting
    });

    AppLogger().info('After setState - _currentPosition: ${_currentPosition.latitude}, ${_currentPosition.longitude}');

    // Update address + nearby places in parallel
    Future.wait([
      _updateAddress(position),
      _loadNearbyPlaces(),
    ]);

    AppLogger().info('=== MAP TAP DEBUG END ===');
  }

  void _confirmLocation() {
    AppLogger().info('_confirmLocation called');

    // Validate location name is not empty
    if (_locationName.isEmpty) {
      _showError('Nama lokasi tidak boleh kosong. Pilih lokasi di peta.');
      return;
    }

    // Validate address is loaded and not the loading state
    if (_currentAddress.isEmpty || _currentAddress == 'Memuat lokasi...') {
      _showError('Tunggu sebentar, alamat masih dimuat...');
      return;
    }

    // Validate coordinates are valid (not default/zero)
    if (_currentPosition.latitude == 0.0 && _currentPosition.longitude == 0.0) {
      _showError('Lokasi tidak valid. Coba pilih ulang.');
      return;
    }

    final locationData = LocationData(
      name: _locationName,
      address: _currentAddress,
      latitude: _currentPosition.latitude,
      longitude: _currentPosition.longitude,
      placeId: _selectedPlaceId,
    );

    AppLogger().info('Calling onLocationSelected callback...');
    widget.onLocationSelected(locationData);
    // Don't call Navigator.pop here - the callback will handle it
    AppLogger().info('onLocationSelected callback completed');
  }

  void _showError(String message) {
    if (mounted) {
      SnackBarHelper.showError(context, message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: AppColors.surfaceAlt)),
            ),
            child: Row(
              children: [
                const Text(
                  'Pilih Lokasi',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.cardSurface,
                  ),
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari tempat (contoh: Manahan Stadium, Cafe)',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _showSearchResults = false;
                            _searchResults = [];
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.divider),
                ),
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (value) {
                setState(() {});
                if (value.length >= 3) {
                  _searchLocation(value);
                }
              },
              onSubmitted: _searchLocation,
            ),
          ),

          // Search Results or Map
          Expanded(
            child: _showSearchResults ? _buildSearchResults() : _buildMapView(),
          ),

          // Address display and confirm button (only show when not searching)
          if (!_showSearchResults)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Address title
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Color(0xFFBBC863),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _isLoadingAddress
                              ? Row(
                                  children: [
                                    const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xFFBBC863),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Memuat alamat...',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: AppColors.textTertiary,
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _locationName,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _currentAddress,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textTertiary,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Confirm button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed:
                            (_isLoadingAddress ||
                                _locationName.isEmpty ||
                                _currentAddress == 'Memuat lokasi...')
                            ? null
                            : _confirmLocation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFBBC863),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          disabledBackgroundColor: AppColors.divider,
                        ),
                        child: Text(
                          _isLoadingAddress
                              ? 'Memuat Lokasi...'
                              : 'Gunakan Lokasi Ini',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: (_isLoadingAddress || _locationName.isEmpty)
                                ? AppColors.textTertiary
                                : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isLoadingAddress) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFBBC863)),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: AppColors.border),
            const SizedBox(height: 16),
            Text(
              'Tidak ada hasil',
              style: TextStyle(fontSize: 16, color: AppColors.textTertiary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final place = _searchResults[index];
        return ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFBBC863).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.location_on, color: Color(0xFFBBC863)),
          ),
          title: Text(
            place.name,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(place.address, maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ),
          onTap: () => _selectSearchResult(place),
        );
      },
    );
  }

  Widget _buildMapView() {
    if (_isLoadingLocation) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Color(0xFFBBC863)),
            const SizedBox(height: 16),
            Text(
              'Mendapatkan lokasi Anda...',
              style: TextStyle(fontSize: 14, color: AppColors.textTertiary),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        // Google Map
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: _currentPosition,
            zoom: 16,
          ),
          onMapCreated: (GoogleMapController controller) {
            _mapController.complete(controller);
          },
          onTap: (LatLng position) => _onMapTap(position),
          myLocationEnabled: true,
          myLocationButtonEnabled: false, // We have custom button
          zoomControlsEnabled: false,
          compassEnabled: true,
          markers: _markers,
        ),

        // Center marker overlay (emoji 📍)
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          bottom: 0,
          child: Center(
            child: _buildLocationMarker(),
          ),
        ),

        // Selected location banner (shown after selection)
        if (_lastSelectedPlaceName != null)
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBBC863), width: 2),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFBBC863).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        color: Color(0xFFBBC863),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Lokasi Dipilih',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFFBBC863),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _lastSelectedPlaceName!,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () {
                        setState(() => _lastSelectedPlaceName = null);
                      },
                      color: AppColors.textTertiary,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // My Location Button (bottom right)
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            mini: true,
            backgroundColor: Colors.white,
            onPressed: _initializeLocation,
            child: const Icon(Icons.my_location, color: Color(0xFFBBC863)),
          ),
        ),
      ],
    );
  }

  /// Build the main location marker with pulse animation
  Widget _buildLocationMarker() {
    return TweenAnimationBuilder<double>(
      key: ValueKey('marker_anim_${_currentPosition.latitude}_${_currentPosition.longitude}'),
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.8 + (value * 0.2), // Scale from 0.8 to 1.0
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFBBC863).withValues(alpha: 0.4 * value),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Text(
              '📍',
              style: TextStyle(
                fontSize: 40,
                shadows: [
                  Shadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
