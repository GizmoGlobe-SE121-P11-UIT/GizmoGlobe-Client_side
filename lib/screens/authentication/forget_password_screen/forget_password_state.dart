import 'package:equatable/equatable.dart';
import 'package:gizmoglobe_client/enums/processing/dialog_name_enum.dart';
import 'package:gizmoglobe_client/enums/processing/notify_message_enum.dart';

import '../../../enums/processing/process_state_enum.dart';

class ForgetPasswordState with EquatableMixin {
  final String email;
  final ProcessState processState;
  final DialogName dialogName;
  final NotifyMessage message;

  const ForgetPasswordState({
    this.email = '',
    this.processState = ProcessState.idle,
    this.dialogName = DialogName.empty,
    this.message = NotifyMessage.empty,
  });

  @override
  List<Object?> get props => [email, processState, dialogName, message];

  ForgetPasswordState copyWith({
    String? email,
    ProcessState? processState,
    DialogName? dialogName,
    NotifyMessage? message,
  }) {
    return ForgetPasswordState(
      email: email ?? this.email,
      processState: processState ?? this.processState,
      dialogName: dialogName ?? this.dialogName,
      message: message ?? this.message,
    );
  }
}