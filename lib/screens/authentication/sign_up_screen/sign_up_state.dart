import 'package:equatable/equatable.dart';
import 'package:gizmoglobe_client/enums/processing/dialog_name_enum.dart';
import 'package:gizmoglobe_client/enums/processing/notify_message_enum.dart';
import '../../../enums/processing/process_state_enum.dart';

class SignUpState with EquatableMixin {
  final ProcessState processState;
  final NotifyMessage message;
  final DialogName dialogName;
  final String username;
  final String email;
  final String password;
  final String confirmPassword;
  final String phoneNumber;

  const SignUpState({
    this.processState = ProcessState.idle,
    this.dialogName = DialogName.empty,
    this.message = NotifyMessage.empty,
    this.username = '',
    this.email = '',
    this.password = '',
    this.confirmPassword = '',
    this.phoneNumber = '',
  });

  @override
  List<Object?> get props => [processState, dialogName, message, username, email, password, confirmPassword, phoneNumber];

  SignUpState copyWith({
    ProcessState? processState,
    DialogName? dialogName,
    NotifyMessage? message,
    String? username,
    String? email,
    String? password,
    String? confirmPassword,
    String? phoneNumber,
  }) {
    return SignUpState(
      processState: processState ?? this.processState,
      dialogName: dialogName ?? this.dialogName,
      message: message ?? this.message,
      username: username ?? this.username,
      email: email ?? this.email,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      phoneNumber: phoneNumber ?? this.phoneNumber,
    );
  }
}