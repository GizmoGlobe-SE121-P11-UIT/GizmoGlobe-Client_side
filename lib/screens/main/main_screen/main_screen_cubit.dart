import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'main_screen_state.dart';


class HomeScreenCubit extends Cubit<MainScreenState> {
  HomeScreenCubit():
        super(const MainScreenState(
      ));
}