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
      backgroundColor: const Color(0xFFFAF8F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFBBC863),
        foregroundColor: const Color(0xFF000000),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF000000)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Connections',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF000000),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF000000),
          indicatorWeight: 3,
          labelColor: const Color(0xFF000000),
          unselectedLabelColor: const Color(0xFF666666),
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
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
                Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  'Gagal memuat data',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  state.message,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _loadData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFBBC863),
                    foregroundColor: const Color(0xFF000000),
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
              color: Color(0xFFBBC863),
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
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    isFollowers ? Icons.people_outline : Icons.person_add_outlined,
                    size: 64,
                    color: Colors.grey[300],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  isFollowers ? 'Belum ada followers' : 'Belum ada following',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
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
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
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
                  border: Border.all(color: Colors.grey[200]!, width: 2),
                ),
                child: ClipOval(
                  child: (user.avatar != null && user.avatar!.isNotEmpty)
                      ? CachedNetworkImage(
                          imageUrl: user.avatar!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: const Color(0xFFCCFF00).withValues(alpha: 0.2),
                            child: const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFFCCFF00),
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
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (user.isVerified) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.verified,
                            size: 16,
                            color: Color(0xFFCCFF00),
                          ),
                        ],
                      ],
                    ),
                    if (user.bio != null && user.bio!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        user.bio!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              // Follow indicator arrow
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
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
            Color(0xFFCCFF00),
            Color(0xFFA8B86D),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
