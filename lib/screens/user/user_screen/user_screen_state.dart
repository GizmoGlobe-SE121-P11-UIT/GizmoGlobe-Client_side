import 'package:equatable/equatable.dart';

class UserScreenState with EquatableMixin {
  final String username;
  final String email;
  final String? avatarUrl;
  final bool isLoading;

  const UserScreenState({
    required this.username,
    required this.email,
    this.avatarUrl,
    this.isLoading = false,
  });

  @override
  List<Object?> get props => [username, email, avatarUrl, isLoading];

  UserScreenState copyWith({
    String? username,
    String? email,
    String? avatarUrl,
    bool? isLoading,
  }) {
    return UserScreenState(
      username: username ?? this.username,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
