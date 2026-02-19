import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../domain/entities/community.dart';
import '../../../domain/entities/community_category.dart';
import '../../bloc/communities/communities_bloc.dart';
import '../../bloc/communities/communities_state.dart';
import '../../bloc/communities/communities_event.dart';
import '../../widgets/common/error_state_widget.dart';
import 'community_detail_screen.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// X-style Discover Communities Screen
/// Shows communities with recent post previews
class DiscoverCommunitiesScreen extends StatefulWidget {
  const DiscoverCommunitiesScreen({super.key});

  @override
  State<DiscoverCommunitiesScreen> createState() =>
      _DiscoverCommunitiesScreenState();
}

class _DiscoverCommunitiesScreenState extends State<DiscoverCommunitiesScreen> {
  CommunityCategory? _selectedCategory;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    context.read<CommunitiesBloc>().add(LoadCommunities());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
      return 'Komunitas ga ketemu.\nMungkin udah dihapus 🤔';
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

  void _precacheVisibleImages(List<Community> communities) {
    if (!mounted) return;

    // Take first 15 communities
    final visibleCommunities = communities.take(15).toList();

    for (final community in visibleCommunities) {
      if (community.icon != null && community.icon!.isNotEmpty) {
        precacheImage(
          CachedNetworkImageProvider(
            community.icon!,
            maxWidth: 112,
            maxHeight: 112,
          ),
          context,
        );
      }
    }
  }

  void _precacheUpcomingImages() {
    if (!mounted) return;

    final state = context.read<CommunitiesBloc>().state;
    if (state is! CommunitiesLoaded) return;

    var communities = state.filteredCommunities;
    if (_selectedCategory != null) {
      communities = communities
          .where((c) => c.category == _selectedCategory)
          .toList();
    }

    if (communities.isEmpty) return;

    // Calculate current scroll position in terms of items
    final currentScroll = _scrollController.position.pixels;
    final itemHeight = 200.0; // Approximate height of a community card
    final currentIndex = (currentScroll / itemHeight).floor();

    // Precache next 10 communities
    final startIndex = currentIndex + 1;
    final endIndex = (startIndex + 10).clamp(0, communities.length);

    for (int i = startIndex; i < endIndex; i++) {
      final community = communities[i];
      if (community.icon != null && community.icon!.isNotEmpty) {
        precacheImage(
          CachedNetworkImageProvider(
            community.icon!,
            maxWidth: 112,
            maxHeight: 112,
          ),
          context,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildCategoryFilter(),
          Expanded(
            child: BlocBuilder<CommunitiesBloc, CommunitiesState>(
              builder: (context, state) {
                if (state is CommunitiesLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.secondary),
                  );
                }

                if (state is CommunitiesError) {
                  return ErrorStateWidget(
                    message: _getUserFriendlyError(state.message),
                    onRetry: () {
                      context.read<CommunitiesBloc>().add(LoadCommunities());
                    },
                  );
                }

                if (state is CommunitiesLoaded) {
                  var communities = state.filteredCommunities;

                  // Filter by category if selected
                  if (_selectedCategory != null) {
                    communities = communities
                        .where((c) => c.category == _selectedCategory)
                        .toList();
                  }

                  // Precache visible images when communities are loaded
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _precacheVisibleImages(communities);
                  });

                  if (communities.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.groups_outlined,
                            size: 64,
                            color: AppColors.border,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No communities found',
                            style: AppTextStyles.bodyLargeBold.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    color: AppColors.secondary,
                    onRefresh: () async {
                      context.read<CommunitiesBloc>().add(LoadCommunities());
                    },
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.only(top: 8),
                      itemCount: communities.length,
                      itemBuilder: (context, index) {
                        return _CommunityCard(
                          community: communities[index],
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CommunityDetailScreen(
                                  community: communities[index],
                                ),
                              ),
                            );
                          },
                          onJoin: () {
                            context.read<CommunitiesBloc>().add(
                              JoinCommunity(communities[index].id),
                            );
                          },
                        );
                      },
                    ),
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.white,
      elevation: 0,
      title: Text(
        'Discover Communities',
        style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.surfaceAlt, width: 1),
        ),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildCategoryChip('All', null),
          ...CommunityCategory.values.map((category) {
            return _buildCategoryChip(category.displayName, category);
          }),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, CommunityCategory? category) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedCategory = selected ? category : null;
          });
        },
        backgroundColor: AppColors.white,
        selectedColor: AppColors.secondary.withValues(alpha: 0.15),
        labelStyle: AppTextStyles.bodyMedium.copyWith(
          color: isSelected ? AppColors.secondary : AppColors.textPrimary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        ),
        side: BorderSide(
          color: isSelected ? AppColors.secondary : AppColors.border,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}

/// Community Card Widget (X-style)
class _CommunityCard extends StatelessWidget {
  final Community community;
  final VoidCallback onTap;
  final VoidCallback onJoin;

  const _CommunityCard({
    required this.community,
    required this.onTap,
    required this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.surfaceAlt),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                // Community Icon/Avatar
                _buildCommunityAvatar(),
                const SizedBox(width: 12),
                // Community Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              community.name,
                              style: AppTextStyles.bodyLargeBold.copyWith(
                                color: AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (community.isVerified) ...[
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.verified,
                              size: 16,
                              color: AppColors.secondary,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            community.category.emoji,
                            style: AppTextStyles.bodySmall,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            community.category.displayName,
                            style: AppTextStyles.bodySmall.copyWith(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            ' • ${_formatMemberCount(community.memberCount)} members',
                            style: AppTextStyles.bodySmall.copyWith(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Join Button
                _buildJoinButton(context),
              ],
            ),
            const SizedBox(height: 12),
            // Description
            Text(
              community.description,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textEmphasis,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            // Recent Posts Preview
            _buildRecentPostsPreview(),
          ],
        ),
      ),
    );
  }

  Widget _buildCommunityAvatar() {
    if (community.icon != null && community.icon!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          imageUrl: community.icon!,
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          fadeInDuration: Duration.zero,
          fadeOutDuration: Duration.zero,
          memCacheWidth: 112,
          memCacheHeight: 112,
          placeholder: (context, url) =>
              Container(width: 56, height: 56, color: AppColors.surfaceAlt),
          errorWidget: (context, url, error) => _buildDefaultAvatar(),
        ),
      );
    }
    return _buildDefaultAvatar();
  }

  Widget _buildDefaultAvatar() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          community.name[0].toUpperCase(),
          style: AppTextStyles.h2.copyWith(color: AppColors.secondary),
        ),
      ),
    );
  }

  Widget _buildJoinButton(BuildContext context) {
    return FilledButton(
      onPressed: onJoin,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.secondary,
        foregroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        minimumSize: const Size(80, 36),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Text(
        'Join',
        style: AppTextStyles.bodyMediumBold.copyWith(
          color: AppColors.primary,
          letterSpacing: -0.1,
        ),
      ),
    );
  }

  Widget _buildRecentPostsPreview() {
    // Mock recent posts data (replace with real data from API)
    final mockPosts = _getMockPosts();

    if (mockPosts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.article_outlined, size: 16, color: AppColors.textTertiary),
            const SizedBox(width: 8),
            Text(
              'No posts yet',
              style: AppTextStyles.bodySmall.copyWith(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.surfaceAlt),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.article_outlined, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                'Recent posts',
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...mockPosts.take(2).map((post) => _buildPostPreview(post)),
        ],
      ),
    );
  }

  Widget _buildPostPreview(Map<String, dynamic> post) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author avatar
          CircleAvatar(
            radius: 10,
            backgroundColor: AppColors.border,
            child: Text(
              post['author'][0].toUpperCase(),
              style: AppTextStyles.label.copyWith(
                fontSize: 8,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Post content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post['author'],
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textEmphasis,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  post['content'],
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getMockPosts() {
    // Mock data - replace with real API call
    return [
      {
        'author': 'John Doe',
        'content':
            'Just attended an amazing tech meetup! The discussions were insightful.',
      },
      {
        'author': 'Jane Smith',
        'content':
            'Sharing some tips on getting started with Flutter development.',
      },
    ];
  }

  String _formatMemberCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}
