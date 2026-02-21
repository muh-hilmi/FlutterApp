import 'package:flutter/material.dart';
import '../../../domain/entities/community.dart';
import '../../../domain/entities/community_category.dart';
import '../../../domain/entities/user.dart';
import '../profile/profile_screen.dart';
import 'community_utils.dart';
import 'community_cards.dart';
import '../profile/sticky_tab_bar.dart';
import 'package:anigmaa/core/theme/app_colors.dart';

class CommunityDetailScreen extends StatefulWidget {
  final Community community;
  final bool isJoined;

  const CommunityDetailScreen({
    super.key,
    required this.community,
    this.isJoined = false,
  });

  @override
  State<CommunityDetailScreen> createState() => _CommunityDetailScreenState();
}

class _CommunityDetailScreenState extends State<CommunityDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late bool _isJoined;

  // Mock data
  final List<User> _members = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _isJoined = widget.isJoined;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(child: _buildCommunityInfo()),
          SliverPersistentHeader(
            pinned: true,
            delegate: StickyTabBarDelegate(
              TabBar(
                controller: _tabController,
                labelColor: Colors.black,
                unselectedLabelColor: AppColors.textTertiary,
                indicatorColor: const Color(0xFFBBC863),
                indicatorWeight: 3,
                labelStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                tabs: const [
                  Tab(text: 'Feed'),
                  Tab(text: 'Events'),
                  Tab(text: 'Members'),
                ],
              ),
            ),
          ),
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildFeedTab(),
                _buildEventsTab(),
                _buildMembersTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _isJoined
          ? FloatingActionButton.extended(
              onPressed: () => CommunityDialogs.showCreatePostDialog(context),
              backgroundColor: const Color(0xFFBBC863),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Post',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: const Color(0xFFBBC863),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFFBBC863),
                const Color(0xFFBBC863).withValues(alpha: 0.8),
              ],
            ),
          ),
          child: Center(
            child: Text(
              widget.community.icon ?? widget.community.category.emoji,
              style: const TextStyle(fontSize: 80),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCommunityInfo() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.community.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ),
              if (widget.community.isVerified)
                const Icon(Icons.verified, color: Color(0xFFBBC863), size: 24),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.people, size: 16, color: AppColors.textTertiary),
              const SizedBox(width: 4),
              Text(
                '${widget.community.memberCount} members',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textTertiary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 16),
              Icon(Icons.location_on, size: 16, color: AppColors.textTertiary),
              const SizedBox(width: 4),
              Text(
                widget.community.location,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textTertiary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.community.description,
            style: TextStyle(
              fontSize: 15,
              color: AppColors.textEmphasis,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _isJoined = !_isJoined;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _isJoined
                    ? AppColors.surfaceAlt
                    : const Color(0xFFBBC863),
                foregroundColor: _isJoined ? Colors.black87 : Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _isJoined ? 'Joined ✓' : 'Join Community',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedTab() {
    if (!_isJoined) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 64, color: AppColors.textTertiary),
            const SizedBox(height: 16),
            Text(
              'Join community untuk lihat feed',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textTertiary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.chat_bubble_outline, size: 64, color: AppColors.textTertiary),
          const SizedBox(height: 16),
          Text(
            'Belum ada postingan',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Jadilah yang pertama posting!',
            style: TextStyle(fontSize: 14, color: AppColors.textDisabled),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.event_busy, size: 64, color: AppColors.textTertiary),
          const SizedBox(height: 16),
          Text(
            'Belum ada event',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _members.length,
      itemBuilder: (context, index) {
        return CommunityMemberCard(
          member: _members[index],
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfileScreen(userId: _members[index].id),
              ),
            );
          },
        );
      },
    );
  }
}
