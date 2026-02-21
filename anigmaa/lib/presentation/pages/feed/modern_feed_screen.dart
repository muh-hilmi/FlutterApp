import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../domain/entities/post.dart';
import '../../../domain/entities/event.dart';
import '../../bloc/posts/posts_bloc.dart';
import '../../bloc/posts/posts_event.dart';
import '../../bloc/posts/posts_state.dart';
import '../../bloc/events/events_bloc.dart';
import '../../bloc/events/events_event.dart';
import '../../bloc/events/events_state.dart';
import '../../bloc/ranked_feed/ranked_feed_bloc.dart';
import '../../bloc/ranked_feed/ranked_feed_event.dart';
import '../../bloc/ranked_feed/ranked_feed_state.dart';
import '../../widgets/common/error_state_widget.dart';
import '../../widgets/posts/modern_post_card.dart';
import '../create_post/create_post_screen.dart';
import '../../../injection_container.dart';
import '../../../core/utils/image_optimizer.dart';
import 'package:anigmaa/core/theme/app_colors.dart';

class ModernFeedScreen extends StatefulWidget {
  const ModernFeedScreen({super.key});

  @override
  State<ModernFeedScreen> createState() => _ModernFeedScreenState();
}

class _ModernFeedScreenState extends State<ModernFeedScreen> {
  late ScrollController _scrollController;
  late RankedFeedBloc _rankedFeedBloc;

  // Flag to prevent infinite loop
  bool _hasLoadedRanking = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _rankedFeedBloc = sl<RankedFeedBloc>();

    // Load posts and events
    context.read<PostsBloc>().add(LoadPosts());
    context.read<EventsBloc>().add(LoadEvents());
  }

  // Helper function to convert technical errors to user-friendly messages
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

  // Instagram-style scroll listener for prefetching
  void _onScroll() {
    if (_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;

      // Preload more images when 70% scrolled
      if (currentScroll > maxScroll * 0.7) {
        _precacheUpcomingImages();
      }
    }
  }

  // Precache first 15 visible post images on page load
  void _precacheVisibleImages(List<Post> posts) {
    if (!mounted) return;

    // Take first 15 posts
    final visiblePosts = posts.take(15).toList();

    for (final post in visiblePosts) {
      if (post.imageUrls.isNotEmpty) {
        for (final imageUrl in post.imageUrls) {
          ImageOptimizer.safePrecacheImage(
            context,
            imageUrl,
            width: 800,
            height: 600,
          );
        }
      }
    }
  }

  // Precache next 10 upcoming post images when scrolling
  void _precacheUpcomingImages() {
    if (!mounted) return;

    // Get current posts from state
    final postsState = context.read<PostsBloc>().state;
    if (postsState is! PostsLoaded) return;

    // Use all posts for precaching
    final feedPosts = postsState.posts;

    if (feedPosts.isEmpty) return;

    // Calculate current scroll position in terms of items
    final currentScroll = _scrollController.position.pixels;
    final itemHeight = 500.0; // Approximate height of a post card
    final currentIndex = (currentScroll / itemHeight).floor();

    // Precache next 10 posts
    final startIndex = currentIndex + 1;
    final endIndex = (startIndex + 10).clamp(0, feedPosts.length);

    for (int i = startIndex; i < endIndex; i++) {
      final post = feedPosts[i];
      if (post.imageUrls.isNotEmpty) {
        for (final imageUrl in post.imageUrls) {
          ImageOptimizer.safePrecacheImage(
            context,
            imageUrl,
            width: 800,
            height: 600,
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _rankedFeedBloc.close();
    super.dispose();
  }

  void _loadRankedFeed(List<Post> posts, List<Event> events) {
    _rankedFeedBloc.add(LoadRankedFeed(posts: posts, events: events));
  }

  List<Post> _sortPostsByRanking(List<Post> posts, List<String> rankedIds) {
    if (rankedIds.isEmpty) return posts;

    // Create map for O(1) lookup
    final postMap = {for (var post in posts) post.id: post};

    // Sort posts according to ranked IDs
    final sortedPosts = <Post>[];
    for (final id in rankedIds) {
      if (postMap.containsKey(id)) {
        sortedPosts.add(postMap[id]!);
      }
    }

    // Add remaining posts that weren't in ranking
    for (final post in posts) {
      if (!rankedIds.contains(post.id)) {
        sortedPosts.add(post);
      }
    }

    return sortedPosts;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocBuilder<PostsBloc, PostsState>(
        buildWhen: (previous, current) {
          // Only rebuild when posts actually change
          return previous.runtimeType != current.runtimeType ||
              (current is PostsLoaded &&
                  previous is PostsLoaded &&
                  current.posts.length != previous.posts.length);
        },
        builder: (context, postsState) {
          return BlocBuilder<EventsBloc, EventsState>(
            buildWhen: (previous, current) {
              // Only rebuild when events actually change
              return previous.runtimeType != current.runtimeType;
            },
            builder: (context, eventsState) {
              // Wait for both posts and events to load
              if (postsState is PostsLoading || eventsState is EventsLoading) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFFBBC863),
                    strokeWidth: 3,
                  ),
                );
              }

              if (postsState is PostsError) {
                return ErrorStateWidget(
                  message: _getUserFriendlyError(postsState.message),
                  onRetry: () {
                    context.read<PostsBloc>().add(LoadPosts());
                    context.read<EventsBloc>().add(LoadEvents());
                  },
                );
              }

              if (eventsState is EventsError) {
                return ErrorStateWidget(
                  message: _getUserFriendlyError(eventsState.message),
                  onRetry: () {
                    context.read<PostsBloc>().add(LoadPosts());
                    context.read<EventsBloc>().add(LoadEvents());
                  },
                );
              }

              if (postsState is PostsLoaded && eventsState is EventsLoaded) {
                // Trigger ranking when data is ready (only once to prevent infinite loop)
                if (!_hasLoadedRanking) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _hasLoadedRanking = true;
                    _loadRankedFeed(postsState.posts, eventsState.events);
                  });
                }

                // Build UI with ranking results
                return BlocBuilder<RankedFeedBloc, RankedFeedState>(
                  bloc: _rankedFeedBloc,
                  buildWhen: (previous, current) {
                    // Only rebuild when ranking actually changes
                    return previous.runtimeType != current.runtimeType;
                  },
                  builder: (context, rankedState) {
                    List<Post> displayPosts = postsState.posts;

                    // If ranking succeeded, sort posts
                    if (rankedState is RankedFeedLoaded) {
                      displayPosts = _sortPostsByRanking(
                        postsState.posts,
                        rankedState.rankedFeed.forYouPosts,
                      );
                    }

                    // Show ALL posts including current user's posts
                    final feedPosts = displayPosts;

                    // Precache visible images when posts are loaded
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _precacheVisibleImages(feedPosts);
                    });

                    if (feedPosts.isEmpty) {
                      return _buildEmptyState();
                    }

                    return RefreshIndicator(
                      onRefresh: () async {
                        context.read<PostsBloc>().add(RefreshPosts());
                        context.read<EventsBloc>().add(LoadEvents());
                        await Future.delayed(const Duration(seconds: 1));
                      },
                      color: const Color(0xFFBBC863),
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: EdgeInsets.zero,
                        itemCount: feedPosts.length,
                        itemBuilder: (context, index) {
                          final post = feedPosts[index];
                          return ModernPostCard(post: post);
                        },
                      ),
                    );
                  },
                );
              }

              return _buildEmptyState();
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Stack(
        children: [
          // Decorative Background
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFBBC863).withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            bottom: 50,
            left: -50,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFE8EDDA).withValues(alpha: 0.2),
              ),
            ),
          ),

          // Main Content
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFFBBC863,
                          ).withValues(alpha: 0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Image.network(
                      'https://cdn-icons-png.flaticon.com/512/7486/7486754.png',
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.rocket_launch_rounded,
                        size: 60,
                        color: Color(0xFFBBC863),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Masih Sepi Nih...',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF2D3142),
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Yuk gas connect sama yang sefrekuensi! 🚀\natau mulai duluan dengan postingan kamu.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      color: Colors.black,
                      // height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () async {
                      final result = await CreatePostSheet.show(context);
                      if (!mounted) return;

                      if (result != null) {
                        context.read<PostsBloc>().add(
                          CreatePostRequested(result),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFBBC863),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                      shadowColor: const Color(
                        0xFFBBC863,
                      ).withValues(alpha: 0.4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.add_circle_outline_rounded,
                          size: 18,
                          color: Colors.black,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Bikin Postingan baru',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // const SizedBox(height: 4),
                  TextButton(
                    onPressed: () {
                      context.read<PostsBloc>().add(LoadPosts());
                      context.read<EventsBloc>().add(LoadEvents());
                    },
                    child: Text(
                      'Coba lagi?',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
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
}
