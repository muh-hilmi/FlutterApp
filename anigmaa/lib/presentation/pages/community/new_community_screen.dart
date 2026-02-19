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
import 'create_community_screen.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class NewCommunityScreen extends StatefulWidget {
  const NewCommunityScreen({super.key});

  @override
  State<NewCommunityScreen> createState() => _NewCommunityScreenState();
}

class _NewCommunityScreenState extends State<NewCommunityScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Load joined communities
    context.read<CommunitiesBloc>().add(LoadJoinedCommunities());
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        surfaceTintColor: AppColors.white,
        elevation: 0,
        toolbarHeight: 88,
        titleSpacing: 20,
        automaticallyImplyLeading: false,
        title: Padding(
          padding: const EdgeInsets.fromLTRB(0, 16, 0, 12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.groups_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Communities',
                style: AppTextStyles.h2.copyWith(letterSpacing: -0.8),
              ),
              const Spacer(),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(
                    Icons.add_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CreateCommunityScreen(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(57),
          child: TabBar(
            controller: _tabController,
            labelColor: AppColors.textPrimary,
            unselectedLabelColor: AppColors.textPrimary,
            indicatorColor: AppColors.textPrimary,
            indicatorWeight: 5,
            labelStyle: AppTextStyles.bodyLargeBold.copyWith(letterSpacing: -0.3),
            unselectedLabelStyle: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w500,
              letterSpacing: -0.3,
            ),
            tabs: const [
              Tab(text: 'Discover'),
              Tab(text: 'Joined'),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildExploreTab(), _buildJoinedTab()],
      ),
    );
  }

  Widget _buildExploreTab() {
    return BlocBuilder<CommunitiesBloc, CommunitiesState>(
      builder: (context, state) {
        if (state is CommunitiesLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.secondary),
          );
        }

        if (state is CommunitiesError) {
          return ErrorStateWidget(
            message: state.message,
            onRetry: () {
              context.read<CommunitiesBloc>().add(LoadCommunities());
            },
          );
        }

        if (state is CommunitiesLoaded) {
          if (state.filteredCommunities.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            color: AppColors.secondary,
            onRefresh: () async {
              context.read<CommunitiesBloc>().add(LoadCommunities());
            },
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 8),
              itemCount: state.filteredCommunities.length,
              itemBuilder: (context, index) {
                return _buildXStyleCommunityCard(
                  state.filteredCommunities[index],
                  state.joinedCommunities,
                );
              },
            ),
          );
        }

        return const SizedBox();
      },
    );
  }

  Widget _buildJoinedTab() {
    return BlocBuilder<CommunitiesBloc, CommunitiesState>(
      builder: (context, state) {
        if (state is CommunitiesLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.secondary),
          );
        }

        if (state is CommunitiesError) {
          return ErrorStateWidget(
            message: state.message,
            onRetry: () {
              context.read<CommunitiesBloc>().add(LoadJoinedCommunities());
            },
          );
        }

        if (state is CommunitiesLoaded) {
          if (state.joinedCommunities.isEmpty) {
            return _buildJoinedEmptyState();
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: state.joinedCommunities.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              return _buildCommunityCard(
                state.joinedCommunities[index],
                state.joinedCommunities,
                isJoined: true,
              );
            },
          );
        }

        return const SizedBox();
      },
    );
  }

  Widget _buildJoinedEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.groups_outlined, size: 80, color: AppColors.textTertiary),
            const SizedBox(height: 20),
            Text(
              'No communities yet',
              style: AppTextStyles.h3.copyWith(
                fontSize: 18,
                color: AppColors.textEmphasis,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Find communities to join',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                _tabController.animateTo(0);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 0,
              ),
              child: Text(
                'Discover communities',
                style: AppTextStyles.button.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildCommunityCard(
    Community community,
    List<Community> joinedCommunities, {
    bool isJoined = false,
  }) {
    final bool userJoined = joinedCommunities.any((c) => c.id == community.id);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CommunityDetailScreen(
              community: community,
              isJoined: userJoined,
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon - small circle like X
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  community.icon ?? community.category.emoji,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + Verified
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          community.name,
                          style: AppTextStyles.button.copyWith(
                            fontSize: 15,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (community.isVerified)
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Icon(
                            Icons.verified,
                            size: 16,
                            color: AppColors.info,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  // Stats - inline like X
                  Text(
                    '${_formatNumber(community.memberCount)} members · ${community.location}',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Description
                  Text(
                    community.description,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textEmphasis,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Join button - small like X
            userJoined
                ? OutlinedButton(
                    onPressed: () {
                      context.read<CommunitiesBloc>().add(
                        LeaveCommunity(community.id),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: BorderSide(color: AppColors.textTertiary),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      minimumSize: const Size(0, 32),
                    ),
                    child: Text(
                      'Joined',
                      style: AppTextStyles.bodyMediumBold,
                    ),
                  )
                : ElevatedButton(
                    onPressed: () {
                      context.read<CommunitiesBloc>().add(
                        JoinCommunity(community.id),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 0,
                      minimumSize: const Size(0, 32),
                    ),
                    child: Text(
                      'Join',
                      style: AppTextStyles.bodyMediumBold.copyWith(
                        color: AppColors.white,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  /// X-style Community Card with Post Previews
  Widget _buildXStyleCommunityCard(
    Community community,
    List<Community> joinedCommunities,
  ) {
    final isJoined = joinedCommunities.any((c) => c.id == community.id);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CommunityDetailScreen(community: community),
          ),
        );
      },
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
                _buildCommunityAvatar(community),
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
                OutlinedButton(
                  onPressed: () {
                    if (isJoined) {
                      context.read<CommunitiesBloc>().add(
                        LeaveCommunity(community.id),
                      );
                    } else {
                      context.read<CommunitiesBloc>().add(
                        JoinCommunity(community.id),
                      );
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isJoined
                        ? AppColors.textSecondary
                        : AppColors.secondary,
                    side: BorderSide(
                      color: isJoined
                          ? AppColors.border
                          : AppColors.secondary,
                    ),
                    backgroundColor: isJoined ? AppColors.surfaceAlt : null,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    minimumSize: const Size(70, 32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    isJoined ? 'Joined' : 'Join',
                    style: AppTextStyles.bodyMediumBold,
                  ),
                ),
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
            _buildRecentPostsPreview(community),
          ],
        ),
      ),
    );
  }

  Widget _buildCommunityAvatar(Community community) {
    if (community.icon != null && community.icon!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          imageUrl: community.icon!,
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            width: 56,
            height: 56,
            color: AppColors.surfaceAlt,
            child: const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.secondary,
              ),
            ),
          ),
          errorWidget: (context, url, error) =>
              _buildDefaultCommunityAvatar(community),
        ),
      );
    }
    return _buildDefaultCommunityAvatar(community);
  }

  Widget _buildDefaultCommunityAvatar(Community community) {
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

  Widget _buildRecentPostsPreview(Community community) {
    // Mock recent posts data (replace with real data from API)
    final mockPosts = _getMockPosts(community.id);

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

  List<Map<String, dynamic>> _getMockPosts(String communityId) {
    // Mock data - replace with real API call
    return [
      {
        'author': 'Sarah Johnson',
        'content':
            'Just joined this community! Excited to connect with everyone here.',
      },
      {
        'author': 'Mike Chen',
        'content':
            'Looking forward to the upcoming event next week. See you all there!',
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 64, color: AppColors.textTertiary),
            const SizedBox(height: 20),
            Text(
              'No results found',
              style: AppTextStyles.h3.copyWith(
                fontSize: 18,
                color: AppColors.textEmphasis,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try different filters or keywords',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}
