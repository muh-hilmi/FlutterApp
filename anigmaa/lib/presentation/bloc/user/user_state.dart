import 'package:equatable/equatable.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/entities/post.dart';
import '../../../domain/entities/event.dart';

abstract class UserState extends Equatable {
  const UserState();

  @override
  List<Object?> get props => [];
}

class UserInitial extends UserState {}

class UserLoading extends UserState {}

class UserLoaded extends UserState {
  final User user;
  final int eventsHosted; // All events (for tab bar)
  final int activeEventsCount; // Active events only (for header)
  final int eventsAttended;
  final int connections;
  final int postsCount;
  final int totalInvitedAttendees;
  final List<Post> userPosts;
  final List<Event> userEvents; // Added: actual event data for profile tabs

  const UserLoaded({
    required this.user,
    required this.eventsHosted,
    this.activeEventsCount = 0, // Default to 0 for backward compatibility
    required this.eventsAttended,
    required this.connections,
    this.postsCount = 0,
    this.totalInvitedAttendees = 0,
    this.userPosts = const [],
    this.userEvents = const [], // Added
  });

  @override
  List<Object?> get props => [user, eventsHosted, activeEventsCount, eventsAttended, connections, postsCount, totalInvitedAttendees, userPosts, userEvents];

  UserLoaded copyWith({
    User? user,
    int? eventsHosted,
    int? activeEventsCount,
    int? eventsAttended,
    int? connections,
    int? postsCount,
    int? totalInvitedAttendees,
    List<Post>? userPosts,
    List<Event>? userEvents, // Added
  }) {
    return UserLoaded(
      user: user ?? this.user,
      eventsHosted: eventsHosted ?? this.eventsHosted,
      activeEventsCount: activeEventsCount ?? this.activeEventsCount,
      eventsAttended: eventsAttended ?? this.eventsAttended,
      connections: connections ?? this.connections,
      postsCount: postsCount ?? this.postsCount,
      totalInvitedAttendees: totalInvitedAttendees ?? this.totalInvitedAttendees,
      userPosts: userPosts ?? this.userPosts,
      userEvents: userEvents ?? this.userEvents, // Added
    );
  }
}

class UserError extends UserState {
  final String message;

  const UserError(this.message);

  @override
  List<Object?> get props => [message];
}

// New states for social features
class UsersSearchLoading extends UserState {}

class UsersSearchLoaded extends UserState {
  final List<User> users;

  const UsersSearchLoaded(this.users);

  @override
  List<Object?> get props => [users];
}

class UsersSearchError extends UserState {
  final String message;

  const UsersSearchError(this.message);

  @override
  List<Object?> get props => [message];
}

class FollowersLoading extends UserState {}

class FollowersLoaded extends UserState {
  final List<User> followers;

  const FollowersLoaded(this.followers);

  @override
  List<Object?> get props => [followers];
}

class FollowingLoading extends UserState {}

class FollowingLoaded extends UserState {
  final List<User> following;

  const FollowingLoaded(this.following);

  @override
  List<Object?> get props => [following];
}

class UserActionSuccess extends UserState {
  final String message;

  const UserActionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}
