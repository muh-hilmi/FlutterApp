import 'package:flutter/material.dart';
import '../../../domain/entities/user.dart';
import '../../../core/services/api_service.dart';
import '../../pages/profile/profile_screen.dart';

class FindMatchesModal extends StatelessWidget {
  final String eventId;
  final String eventTitle;

  const FindMatchesModal({
    super.key,
    required this.eventId,
    required this.eventTitle,
  });

  @override
  Widget build(BuildContext context) {
    // Mock matched users with scoring
    final matches = _getMockedMatches();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.people_alt,
                        color: Colors.purple.shade700,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Find Matches',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            'People also joining "$eventTitle"',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Matches list
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.all(16),
              itemCount: matches.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _buildMatchCard(context, matches[index]);
              },
            ),
          ),

          // Footer tip
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              border: Border(
                top: BorderSide(color: Colors.blue.shade100),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb_outline, size: 18, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Connecting before the event increases show-up rate by 3x!',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade900,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchCard(BuildContext context, UserMatch match) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar with match score badge
          Stack(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundImage: match.user.avatar != null
                    ? NetworkImage(match.user.avatar!)
                    : null,
                child: match.user.avatar == null
                    ? Text(
                        match.user.name[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getMatchColor(match.matchScore),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Text(
                    '${(match.matchScore * 100).toInt()}%',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),

          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      match.user.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    if (match.user.isVerified) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.verified, size: 16, color: Colors.blue),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.auto_awesome, size: 12, color: Colors.purple.shade600),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        match.reason,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Action buttons
          Column(
            children: [
              ElevatedButton(
                onPressed: () {
                  _sendConnectionRequest(context, match.user);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Connect',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: () => _viewProfile(context, match.user),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                ),
                child: Text(
                  'View Profile',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getMatchColor(double score) {
    if (score >= 0.8) return Colors.green.shade600;
    if (score >= 0.6) return Colors.orange.shade600;
    return Colors.blue.shade600;
  }

  void _sendConnectionRequest(BuildContext context, User user) async {
    try {
      final apiService = ApiService();
      await apiService.sendConnectionRequest(user.id);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connection request sent to ${user.name}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send connection request: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _viewProfile(BuildContext context, User user) {
    Navigator.of(context).pop(); // Close modal first
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileScreen(userId: user.id),
      ),
    );
  }

  Future<List<UserMatch>> _getMatchesFromAPI() async {
    try {
      final apiService = ApiService();
      final scanResults = await apiService.getEventMatches(eventId);
      
      // Convert ScanResultModel to UserMatch (mock conversion for now)
      return scanResults.map((scanResult) {
        return UserMatch(
          user: User(
            id: scanResult.userId ?? scanResult.eventId ?? 'unknown',
            name: scanResult.type == 'profile' ? 'User ${scanResult.userId}' : 'Event User',
            bio: scanResult.additionalData.toString(),
            createdAt: DateTime.now(),
            settings: const UserSettings(
              pushNotifications: true,
              emailNotifications: true,
              darkMode: false,
              language: 'en',
              locationEnabled: true,
              showOnlineStatus: true,
            ),
            stats: const UserStats(
              eventsAttended: 0,
              eventsCreated: 0,
              followersCount: 0,
              followingCount: 0,
              reviewsGiven: 0,
              averageRating: 0.0,
            ),
            privacy: const UserPrivacy(
              profileVisible: true,
              eventsVisible: true,
              allowFollowers: true,
              showEmail: false,
              showLocation: true,
            ),
          ),
          matchScore: 0.8, // Default score
          reason: 'Connected via event',
        );
      }).toList();
    } catch (e) {
      // Return empty list on error, handle gracefully
      return [];
    }
  }

  List<UserMatch> _getMockedMatches() {
    // Replace with actual API call
    return [
      UserMatch(
        user: User(
          id: '1',
          name: 'Sarah Johnson',
          bio: 'Product Designer at Tech Company',
          isVerified: true,
          createdAt: DateTime.now(),
          settings: const UserSettings(
            pushNotifications: true,
            emailNotifications: true,
            darkMode: false,
            language: 'en',
            locationEnabled: true,
            showOnlineStatus: true,
          ),
          stats: const UserStats(
            eventsAttended: 0,
            eventsCreated: 0,
            followersCount: 0,
            followingCount: 0,
            reviewsGiven: 0,
            averageRating: 0.0,
          ),
          privacy: const UserPrivacy(
            profileVisible: true,
            eventsVisible: true,
            allowFollowers: true,
            showEmail: false,
            showLocation: true,
          ),
        ),
        matchScore: 0.92,
        reason: 'Both interested in Design Thinking workshops',
      ),
      UserMatch(
        user: User(
          id: '2',
          name: 'Michael Chen',
          bio: 'Software Developer',
          isVerified: false,
          createdAt: DateTime.now(),
          settings: const UserSettings(
            pushNotifications: true,
            emailNotifications: true,
            darkMode: false,
            language: 'en',
            locationEnabled: true,
            showOnlineStatus: true,
          ),
          stats: const UserStats(
            eventsAttended: 0,
            eventsCreated: 0,
            followersCount: 0,
            followingCount: 0,
            reviewsGiven: 0,
            averageRating: 0.0,
          ),
          privacy: const UserPrivacy(
            profileVisible: true,
            eventsVisible: true,
            allowFollowers: true,
            showEmail: false,
            showLocation: true,
          ),
        ),
        matchScore: 0.78,
        reason: 'Similar tech interests and skill level',
      ),
    ];
  }
}

class UserMatch {
  final User user;
  final double matchScore;
  final String reason;

  UserMatch({
    required this.user,
    required this.matchScore,
    required this.reason,
  });
}
