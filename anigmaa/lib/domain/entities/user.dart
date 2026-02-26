class User {
  final String id;
  final String? email;
  final String name;
  final String? bio;
  final String? avatar;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final List<String> interests;
  final UserSettings settings;
  final UserStats stats;
  final bool isVerified;
  final bool isEmailVerified;
  final UserPrivacy privacy;

  // Essential fields (required after first login)
  final String? phone;
  final DateTime? dateOfBirth;
  final String? gender; // 'male', 'female', 'other', 'prefer_not_to_say'
  final String? location;

  // Follow status (null if viewing own profile, true/false if viewing other user)
  final bool? isFollowing;

  const User({
    required this.id,
    this.email,
    required this.name,
    this.bio,
    this.avatar,
    required this.createdAt,
    this.lastLoginAt,
    this.interests = const [],
    required this.settings,
    required this.stats,
    this.isVerified = false,
    this.isEmailVerified = false,
    required this.privacy,
    this.phone,
    this.dateOfBirth,
    this.gender,
    this.location,
    this.isFollowing,
  });

  User copyWith({
    String? id,
    String? email,
    String? name,
    String? bio,
    String? avatar,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    List<String>? interests,
    UserSettings? settings,
    UserStats? stats,
    bool? isVerified,
    bool? isEmailVerified,
    UserPrivacy? privacy,
    String? phone,
    DateTime? dateOfBirth,
    String? gender,
    String? location,
    bool? isFollowing,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      bio: bio ?? this.bio,
      avatar: avatar ?? this.avatar,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      interests: interests ?? this.interests,
      settings: settings ?? this.settings,
      stats: stats ?? this.stats,
      isVerified: isVerified ?? this.isVerified,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      privacy: privacy ?? this.privacy,
      phone: phone ?? this.phone,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      location: location ?? this.location,
      isFollowing: isFollowing ?? this.isFollowing,
    );
  }

  /// Check if user has completed essential profile fields
  bool get hasCompletedEssentialProfile {
    return dateOfBirth != null && location != null;
  }
}

class UserSettings {
  final bool pushNotifications;
  final bool emailNotifications;
  final bool darkMode;
  final String language;
  final bool locationEnabled;
  final bool showOnlineStatus;

  const UserSettings({
    this.pushNotifications = true,
    this.emailNotifications = true,
    this.darkMode = false,
    this.language = 'en',
    this.locationEnabled = true,
    this.showOnlineStatus = true,
  });

  UserSettings copyWith({
    bool? pushNotifications,
    bool? emailNotifications,
    bool? darkMode,
    String? language,
    bool? locationEnabled,
    bool? showOnlineStatus,
  }) {
    return UserSettings(
      pushNotifications: pushNotifications ?? this.pushNotifications,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      darkMode: darkMode ?? this.darkMode,
      language: language ?? this.language,
      locationEnabled: locationEnabled ?? this.locationEnabled,
      showOnlineStatus: showOnlineStatus ?? this.showOnlineStatus,
    );
  }
}

class UserStats {
  final int eventsAttended;
  final int eventsCreated;
  final int totalUniqueEvents; // Unique events (host + attended, no duplicates)
  final int followersCount;
  final int followingCount;
  final int reviewsGiven;
  final double averageRating;

  const UserStats({
    this.eventsAttended = 0,
    this.eventsCreated = 0,
    this.totalUniqueEvents = 0,
    this.followersCount = 0,
    this.followingCount = 0,
    this.reviewsGiven = 0,
    this.averageRating = 0.0,
  });

  UserStats copyWith({
    int? eventsAttended,
    int? eventsCreated,
    int? totalUniqueEvents,
    int? followersCount,
    int? followingCount,
    int? reviewsGiven,
    double? averageRating,
  }) {
    return UserStats(
      eventsAttended: eventsAttended ?? this.eventsAttended,
      eventsCreated: eventsCreated ?? this.eventsCreated,
      totalUniqueEvents: totalUniqueEvents ?? this.totalUniqueEvents,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      reviewsGiven: reviewsGiven ?? this.reviewsGiven,
      averageRating: averageRating ?? this.averageRating,
    );
  }
}

class UserPrivacy {
  final bool profileVisible;
  final bool eventsVisible;
  final bool allowFollowers;
  final bool showEmail;
  final bool showLocation;

  const UserPrivacy({
    this.profileVisible = true,
    this.eventsVisible = true,
    this.allowFollowers = true,
    this.showEmail = false,
    this.showLocation = true,
  });

  UserPrivacy copyWith({
    bool? profileVisible,
    bool? eventsVisible,
    bool? allowFollowers,
    bool? showEmail,
    bool? showLocation,
  }) {
    return UserPrivacy(
      profileVisible: profileVisible ?? this.profileVisible,
      eventsVisible: eventsVisible ?? this.eventsVisible,
      allowFollowers: allowFollowers ?? this.allowFollowers,
      showEmail: showEmail ?? this.showEmail,
      showLocation: showLocation ?? this.showLocation,
    );
  }
}