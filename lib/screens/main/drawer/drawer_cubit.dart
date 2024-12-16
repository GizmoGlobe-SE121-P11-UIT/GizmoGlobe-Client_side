import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../authentication/sign_in_screen/sign_in_view.dart';
import 'drawer_state.dart';

class DrawerCubit extends Cubit<DrawerState> {
  DrawerCubit() : super(DrawerState());

  void toggleDrawer() => emit(state.copyWith(isOpen: !state.isOpen));
  void openDrawer() => emit(state.copyWith(isOpen: true));
  void closeDrawer() => emit(state.copyWith(isOpen: false));

  Future<void> logOut(BuildContext context) async {
    try {
      closeDrawer();
      await FirebaseAuth.instance.signOut();
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => SignInScreen.newInstance()),
              (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error signing out: $e');
      }
    }
  }
}