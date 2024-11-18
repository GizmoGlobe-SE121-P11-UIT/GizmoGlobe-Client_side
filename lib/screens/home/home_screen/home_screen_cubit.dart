import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'home_screen_state.dart';


class HomeScreenCubit extends Cubit<HomeScreenState> {
  HomeScreenCubit():
        super(const HomeScreenState(
      ));
}