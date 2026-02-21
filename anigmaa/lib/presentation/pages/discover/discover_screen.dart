import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:anigmaa/domain/entities/event.dart';
import 'package:anigmaa/domain/entities/event_category.dart';
import 'package:anigmaa/presentation/bloc/events/events_bloc.dart';
import 'package:anigmaa/presentation/bloc/events/events_event.dart';
import 'package:anigmaa/presentation/bloc/events/events_state.dart';
import 'package:anigmaa/presentation/bloc/posts/posts_bloc.dart';
import 'package:anigmaa/presentation/bloc/posts/posts_event.dart';
import 'package:anigmaa/presentation/bloc/posts/posts_state.dart';
import 'package:anigmaa/presentation/bloc/user/user_bloc.dart';
import 'package:anigmaa/presentation/bloc/user/user_state.dart' show UserLoaded;
import 'package:anigmaa/presentation/pages/event_detail/event_detail_screen.dart';
import '../../bloc/ranked_feed/ranked_feed_bloc.dart';
import '../../bloc/ranked_feed/ranked_feed_event.dart';
import '../../bloc/ranked_feed/ranked_feed_state.dart';
import '../../../injection_container.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import 'dart:math';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => DiscoverScreenState();
}

class DiscoverScreenState extends State<DiscoverScreen>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  final TextEditingController _searchController = TextEditingController();
  late RankedFeedBloc _rankedFeedBloc;
  final Completer<GoogleMapController> _mapController =
      Completer<GoogleMapController>();

  List<Event> _allEvents = [];
  List<Event> _filteredEvents = [];
  Map<String, List<String>> _rankedEventIds = {};
  final String _selectedMode = 'trending';
  String _selectedCategory = 'all';
  LatLng _currentPosition = const LatLng(-6.2088, 106.8456);
  String? _locationName;

  // Flags
  bool _hasTriggeredRanking = false;
  bool _hasAppliedRankedResults = false;
  bool _hasAppliedInitialFilter = false;
  bool _hasCenteredMap = false;
  bool _isMapReady = false;

  // Map style for dark theme
  final String _mapStyle = '''
  [
    {
      "featureType": "all",
      "elementType": "geometry",
      "stylers": [
        {
          "color": "#242f3e"
        }
      ]
    },
    {
      "featureType": "all",
      "elementType": "labels.text.stroke",
      "stylers": [
        {
          "lightness": -80
        }
      ]
    },
    {
      "featureType": "all",
      "elementType": "labels.text.fill",
      "stylers": [
        {
          "color": "#746855"
        }
      ]
    },
    {
      "featureType": "administrative",
      "elementType": "geometry",
      "stylers": [
        {
          "visibility": "off"
        }
      ]
    },
    {
      "featureType": "administrative.locality",
      "elementType": "labels.text.fill",
      "stylers": [
        {
          "color": "#d59563"
        }
      ]
    },
    {
      "featureType": "poi",
      "elementType": "labels.text.fill",
      "stylers": [
        {
          "color": "#d59563"
        }
      ]
    },
    {
      "featureType": "poi.park",
      "elementType": "geometry",
      "stylers": [
        {
          "color": "#263c3f"
        }
      ]
    },
    {
      "featureType": "poi.park",
      "elementType": "labels.text.fill",
      "stylers": [
        {
          "color": "#6b9a76"
        }
      ]
    },
    {
      "featureType": "road",
      "elementType": "geometry.fill",
      "stylers": [
        {
          "color": "#38414e"
        }
      ]
    },
    {
      "featureType": "road",
      "elementType": "labels.text.fill",
      "stylers": [
        {
          "color": "#98a0b0"
        }
      ]
    },
    {
      "featureType": "water",
      "elementType": "geometry",
      "stylers": [
        {
          "color": "#17263c"
        }
      ]
    },
    {
      "featureType": "water",
      "elementType": "labels.text.fill",
      "stylers": [
        {
          "color": "#515c6d"
        }
      ]
    },
    {
      "featureType": "water",
      "elementType": "labels.text.stroke",
      "stylers": [
        {
          "lightness": -20
        }
      ]
    }
  ]
  ''';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _rankedFeedBloc = sl<RankedFeedBloc>();
    _searchController.addListener(_filterEvents);
    _loadInitialData();
    _determinePosition();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && _isMapReady) {
      _centerMapOnLocation(_currentPosition);
    }
  }

  void _loadInitialData() {
    context.read<EventsBloc>().add(const LoadEventsByMode(mode: 'for_you'));
    context.read<PostsBloc>().add(LoadPosts());
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      if (mounted) {
        final newPosition = LatLng(position.latitude, position.longitude);
        setState(() {
          _currentPosition = newPosition;
        });

        if (!_hasCenteredMap && _mapController.isCompleted) {
          _centerMapOnLocation(newPosition);
        }

        try {
          List<Placemark> placemarks = await placemarkFromCoordinates(
            position.latitude,
            position.longitude,
          );

          if (placemarks.isNotEmpty) {
            final place = placemarks.first;
            final name = [
              place.subLocality,
              place.locality,
            ].where((e) => e != null && e.isNotEmpty).join(', ');

            if (mounted) {
              setState(() {
                _locationName = name.isEmpty ? place.name : name;
              });
            }
          }
        } catch (e) {
          debugPrint('Geocoding error: $e');
        }
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  Future<void> _centerMapOnLocation(LatLng position) async {
    try {
      final controller = await _mapController.future;
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: position,
            zoom: 14.0,
          ),
        ),
      );
      setState(() {
        _hasCenteredMap = true;
        _isMapReady = true;
      });
    } catch (e) {
      debugPrint('Error centering map: $e');
      setState(() {
        _isMapReady = true;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    _rankedFeedBloc.close();
    super.dispose();
  }

  void _filterEvents() {
    _applyModeFilter();
  }

  void _changeCategory(String category) {
    setState(() {
      _selectedCategory = category;
    });
    _applyModeFilter();
  }

  void _applyModeFilter() {
    final searchQuery = _searchController.text.toLowerCase();
    var filtered = List<Event>.from(_allEvents);

    // Filter by status
    filtered = filtered.where((event) {
      return event.status == EventStatus.upcoming ||
          event.status == EventStatus.ongoing;
    }).toList();

    // Filter by category
    if (_selectedCategory != 'all') {
      filtered = filtered.where((event) {
        final categoryLower = event.category.displayName.toLowerCase();
        return categoryLower == _selectedCategory.toLowerCase();
      }).toList();
    }

    // Filter by search query
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((event) {
        return event.title.toLowerCase().contains(searchQuery) ||
            event.description.toLowerCase().contains(searchQuery) ||
            event.location.name.toLowerCase().contains(searchQuery) ||
            event.category.displayName.toLowerCase().contains(searchQuery);
      }).toList();
    }

    // Apply ranking if available
    if (_rankedEventIds.isNotEmpty &&
        _rankedEventIds.containsKey(_selectedMode)) {
      final rankedIds = _rankedEventIds[_selectedMode]!;
      filtered.sort((a, b) {
        final aIndex = rankedIds.indexOf(a.id);
        final bIndex = rankedIds.indexOf(b.id);
        if (aIndex == -1 && bIndex == -1) return 0;
        if (aIndex == -1) return 1;
        if (bIndex == -1) return -1;
        return aIndex.compareTo(bIndex);
      });
    }

    setState(() {
      _filteredEvents = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final userState = context.watch<UserBloc>().state;
    final locationName =
        _locationName ??
        (userState is UserLoaded
            ? (userState.user.location ?? 'Jakarta Area')
            : 'Jakarta Area');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Map Background
          BlocBuilder<PostsBloc, PostsState>(
            builder: (context, postsState) {
              return BlocConsumer<EventsBloc, EventsState>(
                listener: (context, state) {
                  if (state is EventsLoaded) {
                    setState(() {
                      _allEvents = state.filteredEvents;
                    });

                    if (postsState is PostsLoaded) {
                      _triggerRankingIfNeeded(postsState, state.events);
                    }

                    if (!_hasAppliedInitialFilter) {
                      _hasAppliedInitialFilter = true;
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _applyModeFilter();
                      });
                    }
                  }
                },
                builder: (context, eventsState) {
                  return BlocBuilder<RankedFeedBloc, RankedFeedState>(
                    bloc: _rankedFeedBloc,
                    builder: (context, rankedState) {
                      _updateRankedFeedData(rankedState);
                      return _buildMapContent(eventsState);
                    },
                  );
                },
              );
            },
          ),

          // Top UI Overlays
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildTopOverlays(locationName),
          ),

          // Middle Controls (Floating buttons)
          Positioned(
            right: 16,
            bottom: 280,
            child: _buildFloatingControls(),
          ),

          // Bottom Event Carousel
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomCarousel(),
          ),
        ],
      ),
    );
  }

  Widget _buildMapContent(EventsState eventsState) {
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: _currentPosition,
        zoom: 14.0,
      ),
      onMapCreated: (GoogleMapController controller) {
        _mapController.complete(controller);
        setState(() {
          _isMapReady = true;
        });
        if (!_hasCenteredMap) {
          _centerMapOnLocation(_currentPosition);
        }
      },
      style: _mapStyle,
      myLocationEnabled: false,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      compassEnabled: false,
      mapToolbarEnabled: false,
      markers: _buildMarkers(),
    );
  }

  Set<Marker> _buildMarkers() {
    return _filteredEvents.map((event) {
      return Marker(
        markerId: MarkerId(event.id),
        position: LatLng(event.location.latitude, event.location.longitude),
        onTap: () {
          // Navigate to event detail
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EventDetailScreen(event: event),
            ),
          );
        },
        icon: _getMarkerIcon(event.category),
      );
    }).toSet();
  }

  BitmapDescriptor _getMarkerIcon(EventCategory category) {
    // Use default marker for now - can be customized
    return BitmapDescriptor.defaultMarkerWithHue(
      BitmapDescriptor.hueGreen,
    );
  }

  Widget _buildTopOverlays(String locationName) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            // Search Bar
            Container(
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.textTertiary.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 16, right: 12),
                    child: Icon(
                      Icons.search,
                      color: AppColors.textTertiary,
                      size: 22,
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.white,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Cari event di sekitar...',
                        hintStyle: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textTertiary,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                  // Filter button
                  Container(
                    margin: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.tune,
                        color: AppColors.secondary,
                        size: 20,
                      ),
                      onPressed: () {
                        // Show advanced filter
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Filter Pills
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildFilterChip(
                    label: 'Semua',
                    icon: Icons.auto_awesome,
                    isSelected: _selectedCategory == 'all',
                    onTap: () => _changeCategory('all'),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    label: 'Belajar',
                    icon: Icons.menu_book,
                    isSelected: _selectedCategory == 'learning',
                    onTap: () => _changeCategory('learning'),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    label: 'Nongkrong',
                    icon: Icons.coffee,
                    isSelected: _selectedCategory == 'social',
                    onTap: () => _changeCategory('social'),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    label: 'Hangout',
                    icon: Icons.groups,
                    isSelected: _selectedCategory == 'meetup',
                    onTap: () => _changeCategory('meetup'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.secondary
              : AppColors.primary.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.secondary
                : AppColors.textTertiary.withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.secondary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? AppColors.white : AppColors.textTertiary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isSelected ? AppColors.white : AppColors.textEmphasis,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingControls() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Add button
        Container(
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.9),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.textTertiary.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: IconButton(
            icon: const Icon(
              Icons.add,
              color: AppColors.white,
            ),
            onPressed: () {
              // Navigate to create event
            },
          ),
        ),
        const SizedBox(height: 12),
        // My location button
        Container(
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.9),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.textTertiary.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: IconButton(
            icon: Icon(
              Icons.my_location,
              color: AppColors.secondary,
            ),
            onPressed: () => _centerMapOnLocation(_currentPosition),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomCarousel() {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.95),
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: AppColors.textTertiary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Event Cards
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filteredEvents.length,
              itemBuilder: (context, index) {
                return _buildEventCard(_filteredEvents[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(Event event) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventDetailScreen(event: event),
          ),
        );
      },
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.secondary,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            // Event Image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                bottomLeft: Radius.circular(14),
              ),
              child: Image.network(
                event.imageUrl ?? 'https://via.placeholder.com/150',
                width: 100,
                height: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 100,
                    color: AppColors.surfaceAlt,
                    child: Icon(
                      Icons.event,
                      color: AppColors.textTertiary,
                    ),
                  );
                },
              ),
            ),

            // Event Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Category badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        event.category.displayName,
                        style: AppTextStyles.label.copyWith(
                          color: AppColors.secondary,
                        ),
                      ),
                    ),

                    // Title
                    Text(
                      event.title,
                      style: AppTextStyles.h3.copyWith(
                        fontSize: 16,
                        color: AppColors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Location
                    Text(
                      event.location.name,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textTertiary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Distance and Join button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _getDistance(event),
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.secondary,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            'Join',
                            style: AppTextStyles.button.copyWith(
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getDistance(Event event) {
    const double earthRadiusKm = 6371.0;
    final double dLat = _degreesToRadians(
      event.location.latitude - _currentPosition.latitude,
    );
    final double dLon = _degreesToRadians(
      event.location.longitude - _currentPosition.longitude,
    );
    final double a = (sin(dLat / 2) * sin(dLat / 2)) +
        (cos(_degreesToRadians(_currentPosition.latitude)) *
            cos(_degreesToRadians(event.location.latitude)) *
            sin(dLon / 2) *
            sin(dLon / 2));
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    final double distance = earthRadiusKm * c;

    if (distance < 1) {
      return '${(distance * 1000).toStringAsFixed(0)}m';
    } else {
      return '${distance.toStringAsFixed(1)}km';
    }
  }

  double _degreesToRadians(double degrees) {
    return degrees * (pi / 180.0);
  }

  void _triggerRankingIfNeeded(PostsLoaded postsState, List<Event> events) {
    if (!_hasTriggeredRanking) {
      _hasTriggeredRanking = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _rankedFeedBloc.add(
          LoadRankedFeed(posts: postsState.posts, events: events),
        );
      });
    }
  }

  void _updateRankedFeedData(RankedFeedState rankedState) {
    if (rankedState is RankedFeedLoaded && !_hasAppliedRankedResults) {
      _hasAppliedRankedResults = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final feed = rankedState.rankedFeed;
        _rankedEventIds = {
          'trending': feed.trendingEvent,
          'for_you': feed.forYouEvents,
          'chill': feed.chillEvents,
        };
        setState(_applyModeFilter);
      });
    }
  }
}
