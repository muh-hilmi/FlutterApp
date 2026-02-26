import 'dart:async';
import 'dart:math';
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
import 'widgets/discover_map_view.dart';

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

  // Toggle state — default to map view
  bool _isMapView = true;

  // Flags
  bool _hasTriggeredRanking = false;
  bool _hasAppliedRankedResults = false;
  bool _hasAppliedInitialFilter = false;
  bool _hasCenteredMap = false;
  bool _isMapReady = false;

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

  Future<LatLng?> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }

    if (permission == LocationPermission.deniedForever) return null;

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 5),
        ),
      );

      if (mounted) {
        final newPosition = LatLng(position.latitude, position.longitude);
        setState(() {
          _currentPosition = newPosition;
        });

        // Always move to real GPS position when first obtained.
        // _hasCenteredMap may already be true (set by onMapReady with default Jakarta),
        // but we must still move to the actual user location.
        if (_mapController.isCompleted) {
          _centerMapOnLocation(newPosition);
        }

        // Do geocoding in background AFTER map is centered (non-blocking)
        _updateLocationName(position.latitude, position.longitude);

        return newPosition;
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
    return null;
  }

  /// Update location name in background (non-blocking)
  void _updateLocationName(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty && mounted) {
        final place = placemarks.first;
        final name = [
          place.subLocality,
          place.locality,
        ].where((e) => e != null && e.isNotEmpty).join(', ');
        setState(() {
          _locationName = name.isEmpty ? place.name : name;
        });
      }
    } catch (e) {
      debugPrint('Geocoding error: $e');
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

  /// Re-fetch current GPS location and center map
  Future<void> _refreshLocationAndCenter() async {
    // Show quick feedback - move to last known position first
    final lastPosition = await Geolocator.getLastKnownPosition();
    if (lastPosition != null && _mapController.isCompleted) {
      final quickPos = LatLng(lastPosition.latitude, lastPosition.longitude);
      await _centerMapOnLocation(quickPos);
    }

    // Then get fresh position
    final position = await _determinePosition();
    if (position != null && _mapController.isCompleted) {
      await _centerMapOnLocation(position);
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

    // Filter out ended events using actual time check (not just status field,
    // since backend may not update status to 'ended' immediately)
    filtered = filtered.where((event) {
      return !event.hasEnded &&
          (event.status == EventStatus.upcoming ||
              event.status == EventStatus.ongoing);
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

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    return '${dt.day} ${months[dt.month - 1]}';
  }

  String _formatPrice(Event event) {
    if (event.isFree || event.price == null || event.price == 0) return 'Gratis';
    return 'Rp ${event.price!.toStringAsFixed(0)}';
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

  // ─── Build ────────────────────────────────────────────────────────────────

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
      body: BlocBuilder<PostsBloc, PostsState>(
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
                  return _isMapView
                      ? _buildMapMode(locationName)
                      : _buildCardsMode(locationName);
                },
              );
            },
          );
        },
      ),
    );
  }

  // ─── Map Mode ─────────────────────────────────────────────────────────────

  Widget _buildMapMode(String locationName) {
    return Stack(
      children: [
        // Full-screen map
        DiscoverMapView(
          events: _filteredEvents,
          userLocation: _currentPosition,
          mapController: _mapController,
          onEventTap: (event) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EventDetailScreen(event: event),
              ),
            );
          },
          onMapReady: () {
            setState(() {
              _isMapReady = true;
            });
            if (!_hasCenteredMap) {
              _centerMapOnLocation(_currentPosition);
            }
          },
        ),

        // Top gradient + controls overlay
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: _buildMapTopBar(),
        ),

        // GPS FAB — right side, above create FAB
        Positioned(
          right: 16,
          bottom: 100,
          child: _buildLocationFab(),
        ),
      ],
    );
  }

  Widget _buildMapTopBar() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.5),
            Colors.black.withValues(alpha: 0.0),
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search bar + toggle row
              Row(
                children: [
                  Expanded(child: _buildSearchBar(isMapMode: true)),
                  const SizedBox(width: 10),
                  _buildViewToggle(),
                ],
              ),
              const SizedBox(height: 12),
              // Filter chips
              _buildFilterChips(isMapMode: true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationFab() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        icon: const Icon(
          Icons.my_location,
          color: AppColors.secondary,
          size: 22,
        ),
        onPressed: _refreshLocationAndCenter,
        padding: EdgeInsets.zero,
      ),
    );
  }

  // ─── Cards Mode ───────────────────────────────────────────────────────────

  Widget _buildCardsMode(String locationName) {
    return Column(
      children: [
        // Top bar — light style with white bg
        _buildCardsTopBar(),
        // Event list
        Expanded(
          child: _filteredEvents.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  itemCount: _filteredEvents.length,
                  itemBuilder: (context, index) {
                    return _buildVerticalEventCard(_filteredEvents[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCardsTopBar() {
    return Container(
      color: AppColors.surface,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: _buildSearchBar(isMapMode: false)),
                  const SizedBox(width: 10),
                  _buildViewToggle(),
                ],
              ),
              const SizedBox(height: 12),
              _buildFilterChips(isMapMode: false),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Shared Widgets ───────────────────────────────────────────────────────

  Widget _buildSearchBar({required bool isMapMode}) {
    return Container(
      decoration: BoxDecoration(
        color: isMapMode
            ? AppColors.white.withValues(alpha: 0.95)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 14, right: 10),
            child: Icon(
              Icons.search,
              color: isMapMode ? AppColors.textTertiary : AppColors.textTertiary,
              size: 20,
            ),
          ),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Cari event di sekitar...',
                hintStyle: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textTertiary,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewToggle() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: _isMapView
            ? AppColors.white
            : AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleButton(
            icon: Icons.map_outlined,
            isActive: _isMapView,
            onTap: () {
              if (!_isMapView) setState(() => _isMapView = true);
            },
          ),
          _buildToggleButton(
            icon: Icons.view_list_rounded,
            isActive: !_isMapView,
            onTap: () {
              if (_isMapView) setState(() => _isMapView = false);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 36,
        height: 36,
        margin: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: isActive ? AppColors.secondary : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isActive ? AppColors.primary : AppColors.textTertiary,
        ),
      ),
    );
  }

  Widget _buildFilterChips({required bool isMapMode}) {
    final chips = [
      (label: 'Semua', icon: Icons.auto_awesome, category: 'all'),
      (label: 'Belajar', icon: Icons.menu_book, category: 'learning'),
      (label: 'Nongkrong', icon: Icons.coffee, category: 'social'),
      (label: 'Hangout', icon: Icons.groups, category: 'meetup'),
    ];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final chip = chips[index];
          final isSelected = _selectedCategory == chip.category;
          return _buildFilterChip(
            label: chip.label,
            icon: chip.icon,
            isSelected: isSelected,
            isMapMode: isMapMode,
            onTap: () => _changeCategory(chip.category),
          );
        },
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required bool isMapMode,
    required VoidCallback onTap,
  }) {
    Color bgColor;
    Color borderColor;
    Color iconColor;
    Color textColor;

    if (isSelected) {
      bgColor = AppColors.secondary;
      borderColor = AppColors.secondary;
      iconColor = AppColors.primary;
      textColor = AppColors.primary;
    } else if (isMapMode) {
      bgColor = AppColors.white.withValues(alpha: 0.95);
      borderColor = AppColors.border;
      iconColor = AppColors.textTertiary;
      textColor = AppColors.textPrimary;
    } else {
      bgColor = AppColors.surfaceAlt;
      borderColor = AppColors.border;
      iconColor = AppColors.textTertiary;
      textColor = AppColors.textSecondary;
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: 1),
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
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Vertical Event Card (Cards mode) ─────────────────────────────────────

  Widget _buildVerticalEventCard(Event event) {
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
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with badges
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: Image.network(
                      (event.imageUrl?.isNotEmpty ?? false)
                          ? event.imageUrl!
                          : 'https://via.placeholder.com/400x225',
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: AppColors.surfaceAlt,
                          child: const Center(
                            child: Icon(
                              Icons.event,
                              color: AppColors.textTertiary,
                              size: 40,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  // Category badge
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        event.category.displayName,
                        style: AppTextStyles.label.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  // Distance badge
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getDistance(event),
                        style: AppTextStyles.label.copyWith(
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Info section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    event.title,
                    style: AppTextStyles.h3.copyWith(
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 8),

                  // Location row
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          event.location.name,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textTertiary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Date row
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 14,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(event.startTime),
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Price + CTA row
                  Row(
                    children: [
                      Text(
                        _formatPrice(event),
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      SizedBox(
                        height: 36,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    EventDetailScreen(event: event),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondary,
                            foregroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Lihat Detail →',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Empty State ──────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.event_busy,
            size: 64,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 16),
          Text(
            'Belum ada event di sini',
            style: AppTextStyles.h3.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'Coba ubah filter atau perluas pencarian',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
