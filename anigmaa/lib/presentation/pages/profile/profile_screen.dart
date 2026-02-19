import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../settings/settings_screen.dart';
import '../tickets/my_tickets_screen.dart';
import '../transactions/transaction_history_screen.dart';
import '../my_events/my_events_screen.dart';
import '../event_detail/event_detail_screen.dart';
// import '../saved/saved_items_screen.dart';
// import '../qr/qr_code_screen.dart';
import 'edit_profile_screen.dart';
import 'followers_following_screen.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/utils/app_logger.dart';
import '../../../injection_container.dart' as di;
import '../../bloc/user/user_bloc.dart';
import '../../bloc/user/user_state.dart';
import '../../bloc/user/user_event.dart';
import '../../widgets/posts/modern_post_card.dart';
import '../../widgets/profile/profile_header_widget.dart';
import '../../widgets/profile/profile_menu_widget.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Refactored profile screen with cleaner architecture
/// - Extracted widgets for better maintainability
/// - Simplified state management
/// - Removed unused mixins and complex logic
class ProfileScreen extends StatefulWidget {
  final String? userId;

  const ProfileScreen({super.key, this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  String? _currentUserId;
  bool _isOwnProfile = false;
  TabController? _tabController;
  bool _isProcessing = false;
  bool _unfollowConfirmation = false;
  Timer? _confirmationTimer;
  String? _lastLoadedUserId;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void didUpdateWidget(ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      _initialize();
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _confirmationTimer?.cancel();
    _lastLoadedUserId = null;
    super.dispose();
  }

  Future<void> _initialize() async {
    final authService = di.sl<AuthService>();
    _currentUserId = authService.userId;
    final targetUserId = widget.userId ?? _currentUserId;

    if (targetUserId != null && mounted) {
      if (_lastLoadedUserId != targetUserId) {
        _lastLoadedUserId = targetUserId;

        setState(() {
          _isOwnProfile = targetUserId == _currentUserId;
          _tabController?.dispose();
          _tabController = TabController(length: 2, vsync: this);
        });

        context.read<UserBloc>().add(LoadUserById(targetUserId));
        context.read<UserBloc>().add(LoadUserPostsEvent(targetUserId));
      }
    }
  }

  void _handleFollow(String userId, bool isFollowing) {
    if (_isProcessing) return;

    if (isFollowing) {
      if (!_unfollowConfirmation) {
        setState(() => _unfollowConfirmation = true);
        _confirmationTimer?.cancel();
        _confirmationTimer = Timer(const Duration(seconds: 3), () {
          if (mounted) setState(() => _unfollowConfirmation = false);
        });
      } else {
        _confirmationTimer?.cancel();
        setState(() {
          _unfollowConfirmation = false;
          _isProcessing = true;
        });
        context.read<UserBloc>().add(UnfollowUserEvent(userId));
      }
    } else {
      setState(() => _isProcessing = true);
      context.read<UserBloc>().add(FollowUserEvent(userId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: BlocListener<UserBloc, UserState>(
        listener: (context, state) {
          if (state is UserLoaded ||
              state is UserActionSuccess ||
              state is UserError) {
            _confirmationTimer?.cancel();
            setState(() {
              _isProcessing = false;
              _unfollowConfirmation = false;
            });

            if (state is UserError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          }
        },
        child: BlocBuilder<UserBloc, UserState>(
          buildWhen: (previous, current) {
            return current is UserLoading ||
                current is UserLoaded ||
                current is UserError ||
                current is UserActionSuccess;
          },
          builder: (context, state) {
            if (state is UserLoading) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.secondary),
              );
            }

            if (state is UserError) {
              return _buildErrorState(state);
            }

            if (state is UserLoaded) {
              if (_tabController == null) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.secondary),
                );
              }

              return _buildProfileContent(state);
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildErrorState(UserError state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: 16),
          Text(
            'Gagal memuat profil',
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
            onPressed: _initialize,
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

  Widget _buildProfileContent(UserLoaded state) {
    final user = state.user;

    return Stack(
      children: [
        NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverToBoxAdapter(
                child: ProfileHeaderWidget(
                  user: user,
                  isOwnProfile: _isOwnProfile,
                  isFollowing: user.isFollowing ?? false,
                  isProcessing: _isProcessing,
                  unfollowConfirmation: _unfollowConfirmation,
                ),
              ),
              SliverToBoxAdapter(
                child: ProfileInfoWidget(
                  user: user,
                  isOwnProfile: _isOwnProfile,
                  isFollowing: user.isFollowing ?? false,
                  isProcessing: _isProcessing,
                  unfollowConfirmation: _unfollowConfirmation,
                  onFollowTap: () =>
                      _handleFollow(user.id, user.isFollowing ?? false),
                  onEditProfileTap: () {
                    final userBloc = context.read<UserBloc>();
                    final currentUserId = _currentUserId;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditProfileScreen(user: user),
                      ),
                    ).then((_) {
                      // Refresh user data when returning from Edit Profile
                      if (currentUserId != null && mounted) {
                        userBloc.add(LoadUserById(currentUserId));
                      }
                    });
                  },
                  onFollowersTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FollowersFollowingScreen(
                          userId: user.id,
                          isFollowers: true,
                        ),
                      ),
                    );
                  },
                  onFollowingTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FollowersFollowingScreen(
                          userId: user.id,
                          isFollowers: false,
                        ),
                      ),
                    );
                  },
                  onPostsTap: () {
                    if (_tabController != null) {
                      _tabController!.animateTo(0);
                    }
                  },
                  onEventsTap: () {
                    if (_tabController != null) {
                      _tabController!.animateTo(1);
                    }
                  },
                  onManageEventsTap: () {
                    final userBloc = context.read<UserBloc>();
                    final currentUserId = _currentUserId;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MyEventsScreen(),
                      ),
                    ).then((_) {
                      // Refresh user data when returning from My Events
                      if (currentUserId != null && mounted) {
                        userBloc.add(LoadUserById(currentUserId));
                      }
                    });
                  },
                  postsCount: state.postsCount,
                  eventsHosted: state.eventsHosted,
                  activeEventsCount: state.activeEventsCount,
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _StickyTabBarDelegate(
                  TabBar(
                    controller: _tabController!,
                    labelColor: AppColors.textPrimary,
                    unselectedLabelColor: AppColors.textPrimary,
                    indicatorColor: AppColors.secondary,
                    indicatorWeight: 3,
                    indicatorSize: TabBarIndicatorSize.label, // Minimalist indicator
                    labelStyle: AppTextStyles.tabLabel,
                    unselectedLabelStyle: AppTextStyles.tabLabel,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    tabs: [
                      Tab(child: _buildTabLabel('Postingan', state.postsCount)),
                      Tab(child: _buildTabLabel('Event', state.eventsHosted)),
                    ],
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            controller: _tabController!,
            children: [
              _buildPostsTab(state.userPosts),
              _buildEventsGrid(state.eventsHosted),
            ],
          ),
        ),
        // Fixed Back Button (for other users only) - Minimalist
        if (!_isOwnProfile)
          Positioned(
            top: 8,
            left: 8,
            child: SafeArea(
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        // Fixed Menu Button - Minimalist
        Positioned(
          top: 8,
          right: 8,
          child: SafeArea(
            child: IconButton(
              icon: Icon(
                _isOwnProfile ? Icons.menu : Icons.more_vert,
                color: AppColors.textPrimary,
              ),
              onPressed: () {
                if (_isOwnProfile) {
                  ProfileMenuWidget.showMenuBottomSheet(
                    context,
                    onMyEvents: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MyEventsScreen(),
                        ),
                      ).then((_) {
                        // Refresh user data when returning from My Events
                        if (_currentUserId != null && mounted) {
                          context.read<UserBloc>().add(
                            LoadUserById(_currentUserId!),
                          );
                        }
                      });
                    },
                    onMyTickets: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MyTicketsScreen(),
                        ),
                      );
                    },
                    onTransactions: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const TransactionHistoryScreen(),
                        ),
                      );
                    },
                    onSavedItems: () {
                      Navigator.pop(context);
                      // EXPERIMENTAL: SavedItemsScreen moved to EXPERIMENTAL/
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Saved Items - Feature in development'),
                        ),
                      );
                    },
                    onQRCode: () {
                      Navigator.pop(context);
                      // EXPERIMENTAL: QRCodeScreen moved to EXPERIMENTAL/
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('QR Code - Feature in development'),
                        ),
                      );
                    },
                    onSettings: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsScreen(),
                        ),
                      );
                    },
                    onLogout: () {
                      ProfileMenuWidget.showLogoutDialog(context);
                    },
                  );
                } else {
                  ProfileMenuWidget.showMenuBottomSheet(
                    context,
                    isOwnProfile: false,
                  );
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabLabel(String label, int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(label),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            count.toString(),
            style: AppTextStyles.tabLabel.copyWith(color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }

  Widget _buildPostsTab(List<dynamic> posts) {
    if (posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.article_outlined, size: 64, color: AppColors.border),
            const SizedBox(height: 16),
            Text(
              'Belum ada postingan',
              style: AppTextStyles.bodyLargeBold.copyWith(color: AppColors.textTertiary),
            ),
            if (_isOwnProfile) ...[
              const SizedBox(height: 8),
              Text(
                'Mulai berbagi momenmu!',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textTertiary),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 0),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        return ModernPostCard(post: posts[index]);
      },
    );
  }

  Widget _buildEventsGrid(int eventsCount) {
    final userState = context.read<UserBloc>().state;
    final events = userState is UserLoaded ? userState.userEvents : [];

    if (eventsCount == 0 || events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.event_outlined, size: 64, color: AppColors.border),
            const SizedBox(height: 16),
            Text(
              'Belum ada event',
              style: AppTextStyles.bodyLargeBold.copyWith(color: AppColors.textTertiary),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return GestureDetector(
          onTap: () {
            // Navigate to event detail when tapped
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EventDetailScreen(event: event),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Event image
                  event.fullImageUrls.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: event.fullImageUrls.first,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: AppColors.secondary.withValues(alpha: 0.1),
                            child: const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.secondary,
                                ),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) {
                            // Debug log
                            AppLogger().error(
                              '[Profile Event Grid] Failed to load image for "${event.title}"',
                            );
                            AppLogger().error('[Profile Event Grid] URL: $url');
                            AppLogger().error('[Profile Event Grid] Error: $error');
                            return Container(
                              color: AppColors.secondary.withValues(alpha: 0.1),
                              child: const Icon(
                                Icons.event,
                                color: AppColors.secondary,
                                size: 40,
                              ),
                            );
                          },
                        )
                      : Container(
                          color: AppColors.secondary.withValues(alpha: 0.1),
                          child: const Icon(
                            Icons.event,
                            color: AppColors.secondary,
                            size: 40,
                          ),
                        ),
                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppColors.primary.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                  ),
                  // Event info at bottom
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            event.title,
                            style: AppTextStyles.bodyMediumBold.copyWith(color: AppColors.white),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 12,
                                color: AppColors.white.withValues(alpha: 0.7),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatEventDate(event.startTime),
                                style: AppTextStyles.captionSmall.copyWith(
                                  color: AppColors.white.withValues(alpha: 0.7),
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
          ),
        );
      },
    );
  }

  String _formatEventDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${date.day} ${months[date.month - 1]}';
  }
}

// Sticky Tab Bar Delegate
class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  const _StickyTabBarDelegate(this.tabBar);

  final TabBar tabBar;

  @override
  double get minExtent => tabBar.preferredSize.height + 1; // +1 for divider line

  @override
  double get maxExtent => tabBar.preferredSize.height + 1;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: AppColors.white,
      child: Column(
        children: [
          tabBar,
          const Divider(height: 1, color: AppColors.divider),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_StickyTabBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar;
  }
}
