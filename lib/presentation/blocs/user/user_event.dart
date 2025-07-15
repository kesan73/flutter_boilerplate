import 'package:equatable/equatable.dart';

abstract class UserEvent extends Equatable {
  const UserEvent();

  @override
  List<Object> get props => [];
}

class GetUserProfileEvent extends UserEvent {
  final String userId;

  const GetUserProfileEvent(this.userId);

  @override
  List<Object> get props => [userId];
}

class UpdateUserProfileEvent extends UserEvent {
  final String userId;
  final Map<String, dynamic> userData;

  const UpdateUserProfileEvent(this.userId, this.userData);

  @override
  List<Object> get props => [userId, userData];
}

class ClearUserEvent extends UserEvent {}
