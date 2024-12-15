import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gizmoglobe_client/enums/processing/dialog_name_enum.dart';
import 'package:gizmoglobe_client/screens/authentication/forget_password_screen/forget_password_state.dart';
import '../../../enums/processing/notify_message_enum.dart';
import '../../../enums/processing/process_state_enum.dart';

class ForgetPasswordCubit extends Cubit<ForgetPasswordState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  ForgetPasswordCubit() : super(const ForgetPasswordState());

  void emailChanged(String email) {
    emit(state.copyWith(email: email));
  }

  Future<void> sendVerificationLink(String email) async {
    try {
      emit(state.copyWith(processState: ProcessState.loading));

      await _auth.sendPasswordResetEmail(email: email);
      emit(state.copyWith(processState: ProcessState.success, dialogName: DialogName.success, message: NotifyMessage.msg8));
    } catch (e) {
      emit(state.copyWith(processState: ProcessState.failure, dialogName: DialogName.failure, message: NotifyMessage.msg3));
    }
  }
}