import 'package:equatable/equatable.dart';
import 'community_category.dart';

class Community extends Equatable {
  final String id;
  final String name;
  final String description;
  final String? coverImage;
  final String? icon;
  final CommunityCategory category;
  final String location;
  final int memberCount;
  final List<String> memberIds;
  final List<String> adminIds;
  final DateTime createdAt;
  final bool isPublic;
  final bool isVerified;
  final Map<String, dynamic>? settings;

  const Community({
    required this.id,
    required this.name,
    required this.description,
    this.coverImage,
    this.icon,
    required this.category,
    required this.location,
    required this.memberCount,
    this.memberIds = const [],
    this.adminIds = const [],
    required this.createdAt,
    this.isPublic = true,
    this.isVerified = false,
    this.settings,
  });

  bool get isJoined => false; // Will be determined by current user context

  Community copyWith({
    String? id,
    String? name,
    String? description,
    String? coverImage,
    String? icon,
    CommunityCategory? category,
    String? location,
    int? memberCount,
    List<String>? memberIds,
    List<String>? adminIds,
    DateTime? createdAt,
    bool? isPublic,
    bool? isVerified,
    Map<String, dynamic>? settings,
  }) {
    return Community(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      coverImage: coverImage ?? this.coverImage,
      icon: icon ?? this.icon,
      category: category ?? this.category,
      location: location ?? this.location,
      memberCount: memberCount ?? this.memberCount,
      memberIds: memberIds ?? this.memberIds,
      adminIds: adminIds ?? this.adminIds,
      createdAt: createdAt ?? this.createdAt,
      isPublic: isPublic ?? this.isPublic,
      isVerified: isVerified ?? this.isVerified,
      settings: settings ?? this.settings,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        coverImage,
        icon,
        category,
        location,
        memberCount,
        memberIds,
        adminIds,
        createdAt,
        isPublic,
        isVerified,
        settings,
      ];
}
