import 'package:bloc/bloc.dart';

import 'drawer_state.dart';

class DrawerCubit extends Cubit<DrawerState> {
  DrawerCubit() : super(DrawerState());

  void toggleDrawer() => emit(state.copyWith(isOpen: !state.isOpen));
  void openDrawer() => emit(state.copyWith(isOpen: true));
  void closeDrawer() => emit(state.copyWith(isOpen: false));

  void fetchCategories() {
    // Fetch the categories from your data source
    emit(state.copyWith(categories: ['Category 1', 'Category 2', 'Category 3']));
  }
}