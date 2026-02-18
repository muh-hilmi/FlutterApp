import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:anigmaa/domain/entities/event.dart';
import 'package:anigmaa/domain/entities/event_category.dart'; // Contains EventStatus & displayName extension
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
import 'components/discover_search_bar.dart';
import 'widgets/discover_header_new.dart';
import 'widgets/discover_map_view.dart';
import 'widgets/event_card.dart';
import '../../../injection_container.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/error_state_widget.dart';
import '../../widgets/common/loading_widget.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => DiscoverScreenState();
}

class DiscoverScreenState extends State<DiscoverScreen>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  late RankedFeedBloc _rankedFeedBloc;

  List<Event> _allEvents = [];
  List<Event> _filteredEvents = [];
  Map<String, List<String>> _rankedEventIds = {};
  String _selectedMode = 'trending';
  bool _isMapView = false;
  LatLng _currentPosition = const LatLng(-6.2088, 106.8456); // Default: Jakarta
  String? _locationName;

  // Flags
  bool _hasTriggeredRanking = false;
  bool _hasAppliedRankedResults = false;
  bool _hasAppliedInitialFilter = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _rankedFeedBloc = sl<RankedFeedBloc>();
    _searchController.addListener(_filterEvents);
    _loadInitialData();
    _determinePosition();
  }

  void _loadInitialData() {
    context.read<EventsBloc>().add(const LoadEventsByMode(mode: 'for_you'));
    context.read<PostsBloc>().add(LoadPosts());
  }

  // Basic Geolocator implementation with better accuracy and feedback
  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 1. Check Service
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location services are disabled. Please enable GPS.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    // 2. Check Permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permissions are denied'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Location permissions are permanently denied. Please check settings.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // 3. Get Position
    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Updating location...'),
            duration: Duration(seconds: 1),
            backgroundColor: Color(0xFFBBC863),
          ),
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      if (mounted) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
        });

        // 4. Reverse Geocode to get address name
        try {
          List<Placemark> placemarks = await placemarkFromCoordinates(
            position.latitude,
            position.longitude,
          );

          if (placemarks.isNotEmpty) {
            final place = placemarks.first;
            // Construct a readable name e.g. "Kebayoran Baru, Jakarta Selatan"
            final name = [
              place.subLocality,
              place.locality,
              // place.subAdministrativeArea,
            ].where((e) => e != null && e.isNotEmpty).join(', ');

            if (mounted) {
              setState(() {
                _locationName = name.isEmpty ? place.name : name;
              });
            }
          }
        } catch (geocodeError) {
          debugPrint('Geocoding error: $geocodeError');
        }

        // Optional: Call BLOC here to update user location in backend/state if needed
        // context.read<UserBloc>().add(UpdateUserLocation(lat: position.latitude, lng: position.longitude));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Location updated: ${_locationName ?? 'Jakarta'}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to get location: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _rankedFeedBloc.close();
    super.dispose();
  }

  void _filterEvents() {
    _applyModeFilter();
  }

  void _changeMode(String mode) {
    setState(() {
      _selectedMode = mode;
      // Reset flags when mode changes? Maybe not for ranking if we want to keep it.
    });
    _applyModeFilter();
  }

  void _applyModeFilter() {
    final searchQuery = _searchController.text.toLowerCase();
    var filtered = _allEvents;

    // Status filter
    filtered = filtered.where((event) {
      return event.status == EventStatus.upcoming ||
          event.status == EventStatus.ongoing;
    }).toList();

    // Search filter
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((event) {
        return event.title.toLowerCase().contains(searchQuery) ||
            event.description.toLowerCase().contains(searchQuery) ||
            event.location.name.toLowerCase().contains(searchQuery) ||
            event.category.displayName.toLowerCase().contains(searchQuery);
      }).toList();
    }

    // Ranking Logic
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

  Future<void> _refreshData() async {
    context.read<EventsBloc>().add(LoadEventsByMode(mode: _selectedMode));
    context.read<PostsBloc>().add(LoadPosts());
    _determinePosition();
    await Future.delayed(const Duration(seconds: 1));
  }

  void _refreshLocation() {
    _determinePosition();
  }

  String _getUserFriendlyError(String technicalError) {
    final lowerError = technicalError.toLowerCase();

    if (lowerError.contains('network') ||
        lowerError.contains('connection') ||
        lowerError.contains('socket')) {
      return 'Koneksi internet bermasalah.\nCek koneksi kamu ya! 📡';
    } else if (lowerError.contains('timeout')) {
      return 'Server lagi lelet nih.\nCoba lagi yuk! ⏱️';
    } else if (lowerError.contains('404') || lowerError.contains('not found')) {
      return 'Data ga ketemu.\nMungkin udah dihapus 🤔';
    } else if (lowerError.contains('500') ||
        lowerError.contains('server') ||
        lowerError.contains('unexpected')) {
      return 'Server lagi bermasalah.\nTunggu sebentar ya! 🔧';
    } else if (lowerError.contains('unauthorized') ||
        lowerError.contains('401')) {
      return 'Sesi kamu habis.\nYuk login lagi! 🔐';
    } else {
      return 'Ada kendala nih.\nCoba lagi ya! 😅';
    }
  }

  // Public method called by main.dart or other widgets to add a newly created event
  void addNewEvent(Event newEvent) {
    setState(() {
      _allEvents.insert(0, newEvent);
    });
    _applyModeFilter();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // Use local geocoded name as priority, then UserBloc, then generic
    final userState = context.watch<UserBloc>().state;
    final locationName =
        _locationName ??
        (userState is UserLoaded
            ? (userState.user.location ?? 'Jakarta Area')
            : 'Jakarta Area');

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: BlocBuilder<PostsBloc, PostsState>(
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

                    return RefreshIndicator(
                      onRefresh: _refreshData,
                      color: const Color(0xFFBBC863),
                      child: CustomScrollView(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          // 1. Header & Search Area
                          SliverToBoxAdapter(
                            child: Column(
                              children: [
                                DiscoverHeader(
                                  location: locationName,
                                  onRefreshLocation: _refreshLocation,
                                  onToggleView: () =>
                                      setState(() => _isMapView = !_isMapView),
                                  isMapView: _isMapView,
                                ),
                                DiscoverSearchBar(
                                  controller: _searchController,
                                ),
                                _buildRankingFilter(),
                              ],
                            ),
                          ),

                          // 2. Main Content (Map or List Slivers)
                          if (_isMapView)
                            SliverToBoxAdapter(
                              child: SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.7,
                                child: _buildMapView(),
                              ),
                            )
                          else
                            ..._buildContentListSlivers(eventsState),

                          const SliverToBoxAdapter(child: SizedBox(height: 80)),
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
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

  Widget _buildMapView() {
    return DiscoverMapView(
      events: _filteredEvents,
      userLocation: _currentPosition,
      onEventTap: (event) {
        // Show simplified review or navigate?
        // Let's navigate to detail
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventDetailScreen(event: event),
          ),
        );
      },
    );
  }

  Widget _buildRankingFilter() {
    return Container(
      height: 48, // Reduced from 60
      margin: const EdgeInsets.only(top: 4, bottom: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          _buildIconicChip(
            id: 'trending',
            label: 'Trending',
            icon: '🔥',
            isSelected: _selectedMode == 'trending',
          ),
          const SizedBox(width: 10),
          _buildIconicChip(
            id: 'for_you',
            label: 'For You',
            icon: '✨',
            isSelected: _selectedMode == 'for_you',
          ),
          const SizedBox(width: 10),
          _buildIconicChip(
            id: 'matches',
            label: 'Matches',
            icon: '🤝',
            isSelected: _selectedMode == 'matches',
          ),
        ],
      ),
    );
  }

  Widget _buildIconicChip({
    required String id,
    required String label,
    required String icon,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => _changeMode(id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFBBC863) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFBBC863)
                : const Color(0xFFF1F1F1),
            width: 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFBBC863).withValues(alpha: 0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.grey[700],
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildContentListSlivers(EventsState state) {
    if (state is EventsLoading) {
      return [
        const SliverFillRemaining(
          child: LoadingWidget(message: 'Loading events...'),
        ),
      ];
    }

    if (state is EventsError) {
      return [
        SliverFillRemaining(
          child: ErrorStateWidget(
            message: _getUserFriendlyError(state.message),
            onRetry: _refreshData,
          ),
        ),
      ];
    }

    if (_filteredEvents.isEmpty) {
      return [
        SliverFillRemaining(
          child: EmptyStateWidget(
            icon: Icons.event_outlined,
            title: 'No events found',
            subtitle: _searchController.text.isNotEmpty
                ? 'Try adjusting your search or filters'
                : 'Check back later for new events',
            iconColor: Colors.grey[400],
          ),
        ),
      ];
    }

    return [
      const SliverToBoxAdapter(child: SizedBox(height: 16)),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.62,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
          ),
          delegate: SliverChildBuilderDelegate((context, index) {
            return EventCard(
              event: _filteredEvents[index],
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        EventDetailScreen(event: _filteredEvents[index]),
                  ),
                );
              },
            );
          }, childCount: _filteredEvents.length),
        ),
      ),
    ];
  }
}
