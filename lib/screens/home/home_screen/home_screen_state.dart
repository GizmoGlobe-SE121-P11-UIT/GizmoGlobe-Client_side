import 'package:equatable/equatable.dart';

class HomeScreenState extends Equatable {
  final String username;
  final List<String> categories;

  const HomeScreenState({
    this.username = '',
    this.categories = const [],
  });

  HomeScreenState copyWith({
    String? username,
    List<String>? categories,
  }) {
    return HomeScreenState(
      username: username ?? this.username,
      categories: categories ?? this.categories,
    );
  }

  @override
  List<Object?> get props => [username, categories];
}