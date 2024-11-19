import 'package:bloc/bloc.dart';

class DrawerState {
  final bool isOpen;
  final List<String> categories;

  DrawerState({this.isOpen = false, this.categories = const []});

  DrawerState copyWith({bool? isOpen, List<String>? categories}) {
    return DrawerState(
      isOpen: isOpen ?? this.isOpen,
      categories: categories ?? this.categories,
    );
  }
}