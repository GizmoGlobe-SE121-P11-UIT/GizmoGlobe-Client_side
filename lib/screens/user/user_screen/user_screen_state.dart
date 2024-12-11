import 'package:equatable/equatable.dart';

class UserScreenState with EquatableMixin {
  final String username;
  final String email;

  const UserScreenState({
    required this.username,
    required this.email,
  });

  @override
  List<Object?> get props => [username, email];

  UserScreenState copyWith({
    String? username,
    String? email,
  }) {
    return UserScreenState(
      username: username ?? this.username,
      email: email ?? this.email,
    );
  }
}