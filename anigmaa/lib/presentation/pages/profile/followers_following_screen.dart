// FILE STATUS: EXPERIMENTAL
// REASON: Unreachable from main routing - secondary feature screen
// DATE_CLASSIFIED: 2025-12-29

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../bloc/user/user_bloc.dart';
import '../../bloc/user/user_state.dart';
import '../../bloc/user/user_event.dart';
import '../../../domain/entities/user.dart';
import 'profile_screen.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Screen untuk menampilkan daftar followers atau following
class FollowersFollowingScreen extends StatefulWidget {
  final String userId;
  final bool isFollowers; // true = followers, false = following

  const FollowersFollowingScreen({
    super.key,
    required this.userId,
    required this.isFollowers,
  });

  @override
  State<FollowersFollowingScreen> createState() =>
      _FollowersFollowingScreenState();
}

class _FollowersFollowingScreenState extends State<FollowersFollowingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<User> _followersCache = [];
  List<User> _followingCache = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.isFollowers ? 0 : 1,
    );

    // Load followers and following
    _loadData();

    // Listen to tab changes
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _loadData();
      }
    });
  }

  void _loadData() {
    if (_tabController.index == 0) {
      // Load followers
      context.read<UserBloc>().add(LoadFollowersEvent(widget.userId));
    } else {
      // Load following
      context.read<UserBloc>().add(LoadFollowingEvent(widget.userId));
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.secondary,
        foregroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Connections',
          style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: AppTextStyles.button,
          tabs: const [
            Tab(text: 'Followers'),
            Tab(text: 'Following'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUserList(isFollowers: true),
          _buildUserList(isFollowers: false),
        ],
      ),
    );
  }

  Widget _buildUserList({required bool isFollowers}) {
    return BlocConsumer<UserBloc, UserState>(
      listener: (context, state) {
        // Update cache when data is loaded
        if (state is FollowersLoaded) {
          setState(() {
            _followersCache = state.followers;
          });
        } else if (state is FollowingLoaded) {
          setState(() {
            _followingCache = state.following;
          });
        }
      },
      builder: (context, state) {
        // Check loading state based on which tab we're on
        final bool isLoading = (isFollowers && state is FollowersLoading) ||
            (!isFollowers && state is FollowingLoading);

        if (state is UserError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                const SizedBox(height: 16),
                Text(
                  'Gagal memuat data',
                  style: AppTextStyles.bodyLargeBold.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                Text(
                  state.message,
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _loadData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: AppColors.primary,
                  ),
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          );
        }

        // Use cached data for current tab
        final List<User> users = isFollowers ? _followersCache : _followingCache;

        // Show loading if no cache and still loading
        if (users.isEmpty && isLoading) {
          return const Center(
            child: CircularProgressIndicator(
              color: AppColors.secondary,
            ),
          );
        }

        if (users.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    isFollowers ? Icons.people_outline : Icons.person_add_outlined,
                    size: 64,
                    color: AppColors.border,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  isFollowers ? 'Belum ada followers' : 'Belum ada following',
                  style: AppTextStyles.h3.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          itemBuilder: (context, index) {
            return _buildUserCard(users[index]);
          },
        );
      },
    );
  }

  Widget _buildUserCard(User user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppColors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: () {
          // Navigate to user profile with unique key
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProfileScreen(
                key: ValueKey('profile_${user.id}'),
                userId: user.id,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border, width: 2),
                ),
                child: ClipOval(
                  child: (user.avatar != null && user.avatar!.isNotEmpty)
                      ? CachedNetworkImage(
                          imageUrl: user.avatar!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: AppColors.electricLime.withValues(alpha: 0.2),
                            child: const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.electricLime,
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) =>
                              _buildDefaultAvatar(user.name),
                        )
                      : _buildDefaultAvatar(user.name),
                ),
              ),
              const SizedBox(width: 12),
              // Name and bio
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            user.name,
                            style: AppTextStyles.button.copyWith(color: AppColors.textPrimary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (user.isVerified) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.verified,
                            size: 16,
                            color: AppColors.electricLime,
                          ),
                        ],
                      ],
                    ),
                    if (user.bio != null && user.bio!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        user.bio!,
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              // Follow indicator arrow
              const Icon(
                Icons.chevron_right,
                color: AppColors.textTertiary,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar(String name) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.electricLime,
            Color(0xFFA8B86D),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: AppTextStyles.h3.copyWith(color: AppColors.white),
        ),
      ),
    );
  }
}
