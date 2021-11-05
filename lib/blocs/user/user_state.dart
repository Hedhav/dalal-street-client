part of 'user_bloc.dart';

abstract class UserState extends Equatable {
  const UserState();

  @override
  List<Object> get props => [];
}

class UserLoggedOut extends UserState {
  const UserLoggedOut();
}

class UserLoading extends UserState {
  const UserLoading();
}

class UserLoggedIn extends UserState {
  final User user;

  const UserLoggedIn(this.user);
}
