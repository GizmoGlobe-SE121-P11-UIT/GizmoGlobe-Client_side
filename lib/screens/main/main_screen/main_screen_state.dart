part of 'main_screen_cubit.dart';

class MainScreenState extends Equatable {
  final String username;

  const MainScreenState({this.username = ''});

  MainScreenState copyWith({String? username}) {
    return MainScreenState(
      username: username ?? this.username,
    );
  }

  @override
  List<Object?> get props => [username];
}