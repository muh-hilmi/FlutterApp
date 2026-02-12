import 'package:equatable/equatable.dart';

abstract class UserEvent extends Equatable {
  const UserEvent();

  @override
  List<Object?> get props => [];
}

class LoadUserProfile extends UserEvent {}

class LoadUserById extends UserEvent {
  final String userId;

  const LoadUserById(this.userId);

  @override
  List<Object?> get props => [userId];
}

class UpdateUserProfile extends UserEvent {
  final String? name;
  final String? bio;
  final String? avatar;
  final List<String>? interests;
  final String? phone;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? location;

  const UpdateUserProfile({
    this.name,
    this.bio,
    this.avatar,
    this.interests,
    this.phone,
    this.dateOfBirth,
    this.gender,
    this.location,
  });

  @override
  List<Object?> get props => [name, bio, avatar, interests, phone, dateOfBirth, gender, location];
}

class TogglePremium extends UserEvent {}

class AddInterest extends UserEvent {
  final String interest;

  const AddInterest(this.interest);

  @override
  List<Object?> get props => [interest];
}

class RemoveInterest extends UserEvent {
  final String interest;

  const RemoveInterest(this.interest);

  @override
  List<Object?> get props => [interest];
}

// New events for social features
class SearchUsersEvent extends UserEvent {
  final String query;

  const SearchUsersEvent(this.query);

  @override
  List<Object?> get props => [query];
}

class FollowUserEvent extends UserEvent {
  final String userId;

  const FollowUserEvent(this.userId);

  @override
  List<Object?> get props => [userId];
}

class UnfollowUserEvent extends UserEvent {
  final String userId;

  const UnfollowUserEvent(this.userId);

  @override
  List<Object?> get props => [userId];
}

class LoadFollowersEvent extends UserEvent {
  final String userId;

  const LoadFollowersEvent(this.userId);

  @override
  List<Object?> get props => [userId];
}

class LoadFollowingEvent extends UserEvent {
  final String userId;

  const LoadFollowingEvent(this.userId);

  @override
  List<Object?> get props => [userId];
}

class LoadUserPostsEvent extends UserEvent {
  final String userId;

  const LoadUserPostsEvent(this.userId);

  @override
  List<Object?> get props => [userId];
}
