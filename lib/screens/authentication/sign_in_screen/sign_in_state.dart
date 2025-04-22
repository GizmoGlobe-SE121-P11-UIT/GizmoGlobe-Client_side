import 'package:equatable/equatable.dart';
import 'package:gizmoglobe_client/enums/processing/dialog_name_enum.dart';
import 'package:gizmoglobe_client/enums/processing/notify_message_enum.dart';

import '../../../enums/processing/process_state_enum.dart';

class SignInState with EquatableMixin {
  final ProcessState processState;
  final DialogName dialogName;
  final NotifyMessage message;
  final String email;
  final String password;
  final bool isGuestLogin;

  const SignInState({
    this.processState = ProcessState.idle,
    this.dialogName = DialogName.empty,
    this.message = NotifyMessage.empty,
    this.email = '',
    this.password = '',
    this.isGuestLogin = false,
  });

  @override
  List<Object?> get props =>
      [processState, dialogName, message, email, password, isGuestLogin];

  SignInState copyWith({
    ProcessState? processState,
    DialogName? dialogName,
    NotifyMessage? message,
    String? email,
    String? password,
    bool? isGuestLogin,
  }) {
    return SignInState(
      processState: processState ?? this.processState,
      dialogName: dialogName ?? this.dialogName,
      message: message ?? this.message,
      email: email ?? this.email,
      password: password ?? this.password,
      isGuestLogin: isGuestLogin ?? this.isGuestLogin,
    );
  }
}