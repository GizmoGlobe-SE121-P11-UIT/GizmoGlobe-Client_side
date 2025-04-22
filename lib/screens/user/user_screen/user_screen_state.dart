import 'package:equatable/equatable.dart';

class UserScreenState extends Equatable {
  final String username;
  final String email;
  final String? avatarUrl;
  final bool isGuest;

  const UserScreenState({
    this.username = '',
    this.email = '',
    this.avatarUrl,
    this.isGuest = false,
  });

  @override
  List<Object?> get props => [username, email, avatarUrl, isGuest];

  UserScreenState copyWith({
    String? username,
    String? email,
    String? avatarUrl,
    bool? isGuest,
  }) {
    return UserScreenState(
      username: username ?? this.username,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isGuest: isGuest ?? this.isGuest,
    );
  }
}