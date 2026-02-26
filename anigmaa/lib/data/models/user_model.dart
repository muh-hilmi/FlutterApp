import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    super.email,
    required super.name,
    super.bio,
    super.avatar,
    required super.createdAt,
    super.lastLoginAt,
    super.interests = const [],
    required super.settings,
    required super.stats,
    super.isVerified = false,
    super.isEmailVerified = false,
    required super.privacy,
    super.phone,
    super.dateOfBirth,
    super.gender,
    super.location,
    super.isFollowing,
  });

  // REVIEW: DUAL NAMING CONVENTION FALLBACKS - This is technical debt from backend inconsistency
  // Backend SHOULD always use snake_case (avatar_url, created_at, is_verified) but this code hedges with both formats.
  // Once backend is confirmed 100% snake_case, remove camelCase fallbacks to catch future regressions early.
  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Support both camelCase and snake_case from backend
    final avatarUrl = json['avatar'] ?? json['avatar_url'];
    final createdAt = json['createdAt'] ?? json['created_at'];
    final lastLoginAt = json['lastLoginAt'] ?? json['last_login_at'];
    final isVerified = json['isVerified'] ?? json['is_verified'];
    final isEmailVerified =
        json['isEmailVerified'] ?? json['is_email_verified'];
    final dateOfBirth = json['dateOfBirth'] ?? json['date_of_birth'];

    // Validate required fields
    if (json['id'] == null) {
      throw Exception('Missing user id in response');
    }
    if (json['name'] == null || (json['name'] as String).isEmpty) {
      throw Exception('Missing user name in response');
    }

    // Handle both integer and string IDs from backend
    final userId = json['id'] is int
        ? json['id'].toString()
        : json['id'] as String;
    if (userId.isEmpty) {
      throw Exception('Missing user id in response');
    }

    return UserModel(
      id: userId,
      email: json['email'] as String?,
      name: json['name'] as String,
      bio: json['bio'] as String?,
      avatar: avatarUrl as String?,
      createdAt: createdAt != null
          ? DateTime.parse(createdAt as String)
          : DateTime.now(),
      lastLoginAt: lastLoginAt != null
          ? DateTime.parse(lastLoginAt as String)
          : null,
      interests: List<String>.from(json['interests'] ?? []),
      settings: UserSettingsModel.fromJson(json['settings'] ?? {}),
      stats: UserStatsModel.fromJson(json['stats'] ?? {}),
      isVerified: isVerified as bool? ?? false,
      isEmailVerified: isEmailVerified as bool? ?? false,
      privacy: UserPrivacyModel.fromJson(json['privacy'] ?? {}),
      phone: json['phone'] as String?,
      dateOfBirth: dateOfBirth != null
          ? DateTime.parse(dateOfBirth as String)
          : null,
      gender: json['gender'] as String?,
      location: json['location'] as String?,
      isFollowing: json['is_following'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'bio': bio,
      'avatar': avatar,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'interests': interests,
      'settings': (settings as UserSettingsModel).toJson(),
      'stats': (stats as UserStatsModel).toJson(),
      'isVerified': isVerified,
      'isEmailVerified': isEmailVerified,
      'privacy': (privacy as UserPrivacyModel).toJson(),
      'phone': phone,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'gender': gender,
      'location': location,
    };
  }

  factory UserModel.fromEntity(User user) {
    return UserModel(
      id: user.id,
      email: user.email,
      name: user.name,
      bio: user.bio,
      avatar: user.avatar,
      createdAt: user.createdAt,
      lastLoginAt: user.lastLoginAt,
      interests: user.interests,
      settings: user.settings,
      stats: user.stats,
      isVerified: user.isVerified,
      isEmailVerified: user.isEmailVerified,
      privacy: user.privacy,
      phone: user.phone,
      dateOfBirth: user.dateOfBirth,
      gender: user.gender,
      location: user.location,
      isFollowing: user.isFollowing,
    );
  }
}

class UserSettingsModel extends UserSettings {
  const UserSettingsModel({
    super.pushNotifications = true,
    super.emailNotifications = true,
    super.darkMode = false,
    super.language = 'en',
    super.locationEnabled = true,
    super.showOnlineStatus = true,
  });

  factory UserSettingsModel.fromJson(Map<String, dynamic> json) {
    return UserSettingsModel(
      pushNotifications: json['push_notifications'] as bool? ?? true,
      emailNotifications: json['email_notifications'] as bool? ?? true,
      darkMode: json['dark_mode'] as bool? ?? false,
      language: json['language'] as String? ?? 'en',
      locationEnabled: json['location_enabled'] as bool? ?? true,
      showOnlineStatus: json['show_online_status'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pushNotifications': pushNotifications,
      'emailNotifications': emailNotifications,
      'darkMode': darkMode,
      'language': language,
      'locationEnabled': locationEnabled,
      'showOnlineStatus': showOnlineStatus,
    };
  }
}

class UserStatsModel extends UserStats {
  const UserStatsModel({
    super.eventsAttended = 0,
    super.eventsCreated = 0,
    super.totalUniqueEvents = 0,
    super.followersCount = 0,
    super.followingCount = 0,
    super.reviewsGiven = 0,
    super.averageRating = 0.0,
  });

  factory UserStatsModel.fromJson(Map<String, dynamic> json) {
    // Support multiple naming conventions from backend
    final followersCount =
        json['followers_count'] ?? json['followersCount'] ?? json['followers'];
    final followingCount =
        json['following_count'] ?? json['followingCount'] ?? json['following'];
    final eventsAttended =
        json['events_attended'] ??
        json['eventsAttended'] ??
        json['attended_count'];
    final eventsCreated =
        json['events_created'] ??
        json['eventsCreated'] ??
        json['created_count'];
    final totalUniqueEvents =
        json['total_unique_events'] ??
        json['totalUniqueEvents'] ??
        json['unique_events_count'];
    final reviewsGiven =
        json['reviews_given'] ?? json['reviewsCount'] ?? json['reviews'];
    final averageRating =
        json['average_rating'] ?? json['averageRating'] ?? json['rating'];

    return UserStatsModel(
      eventsAttended: eventsAttended is int
          ? eventsAttended
          : (int.tryParse(eventsAttended?.toString() ?? '0') ?? 0),
      eventsCreated: eventsCreated is int
          ? eventsCreated
          : (int.tryParse(eventsCreated?.toString() ?? '0') ?? 0),
      totalUniqueEvents: totalUniqueEvents is int
          ? totalUniqueEvents
          : (int.tryParse(totalUniqueEvents?.toString() ?? '0') ?? 0),
      followersCount: followersCount is int
          ? followersCount
          : (int.tryParse(followersCount?.toString() ?? '0') ?? 0),
      followingCount: followingCount is int
          ? followingCount
          : (int.tryParse(followingCount?.toString() ?? '0') ?? 0),
      reviewsGiven: reviewsGiven is int
          ? reviewsGiven
          : (int.tryParse(reviewsGiven?.toString() ?? '0') ?? 0),
      averageRating: averageRating is num
          ? averageRating.toDouble()
          : (double.tryParse(averageRating?.toString() ?? '0.0') ?? 0.0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'eventsAttended': eventsAttended,
      'eventsCreated': eventsCreated,
      'totalUniqueEvents': totalUniqueEvents,
      'followersCount': followersCount,
      'followingCount': followingCount,
      'reviewsGiven': reviewsGiven,
      'averageRating': averageRating,
    };
  }
}

class UserPrivacyModel extends UserPrivacy {
  const UserPrivacyModel({
    super.profileVisible = true,
    super.eventsVisible = true,
    super.allowFollowers = true,
    super.showEmail = false,
    super.showLocation = true,
  });

  factory UserPrivacyModel.fromJson(Map<String, dynamic> json) {
    return UserPrivacyModel(
      profileVisible: json['profile_visible'] as bool? ?? true,
      eventsVisible: json['events_visible'] as bool? ?? true,
      allowFollowers: json['allow_followers'] as bool? ?? true,
      showEmail: json['show_email'] as bool? ?? false,
      showLocation: json['show_location'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'profileVisible': profileVisible,
      'eventsVisible': eventsVisible,
      'allowFollowers': allowFollowers,
      'showEmail': showEmail,
      'showLocation': showLocation,
    };
  }
}
