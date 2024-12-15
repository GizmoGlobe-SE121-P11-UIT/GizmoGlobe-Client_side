import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:gizmoglobe_client/data/database/database.dart';

part 'main_screen_state.dart';

class MainScreenCubit extends Cubit<MainScreenState> {
  MainScreenCubit() : super(const MainScreenState());

  Future<void> getUserName() async {
    try {
      await Database().getUsername();
      emit(state.copyWith(username: Database().username));
    } catch (e) {
      debugPrint('Error fetching username: $e');
    }
  }
}