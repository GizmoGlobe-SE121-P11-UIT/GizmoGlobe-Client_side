import 'package:equatable/equatable.dart';

class UserScreenState with EquatableMixin {
  final String username;

  const UserScreenState(
      {
        required this.username,
      });

  @override
  List<Object?> get props =>
      [
        username,
      ];

  UserScreenState copyWith({
    String? username,
  }) {
    return UserScreenState(
        username: username ?? this.username,
    );
  }
}
