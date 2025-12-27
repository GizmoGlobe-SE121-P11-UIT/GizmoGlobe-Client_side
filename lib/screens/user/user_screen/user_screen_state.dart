import 'package:equatable/equatable.dart';

class UserScreenState extends Equatable {
  final String username;
  final String email;
  final String? avatarUrl;
  final bool isGuest;
  final int loyalPoint;

  const UserScreenState({
    this.username = '',
    this.email = '',
    this.avatarUrl,
    this.isGuest = false,
    this.loyalPoint = 0,
  });

  @override
  List<Object?> get props => [username, email, avatarUrl, isGuest, loyalPoint];

  UserScreenState copyWith({
    String? username,
    String? email,
    String? avatarUrl,
    bool? isGuest,
    int? loyalPoint,
  }) {
    return UserScreenState(
      username: username ?? this.username,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isGuest: isGuest ?? this.isGuest,
      loyalPoint: loyalPoint ?? this.loyalPoint,
    );
  }
}