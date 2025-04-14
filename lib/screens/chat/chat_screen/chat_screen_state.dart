import '../../../enums/processing/process_state_enum.dart';
import '../../../objects/chat_related/chat_message.dart';

class ChatScreenState {
  final bool isAIMode;
  final List<ChatMessage> aiMessages;
  final List<ChatMessage> adminMessages;
  final ProcessState processState;
  final String? error;
  final String? modeNotification;

  ChatScreenState({
    this.isAIMode = true,
    this.aiMessages = const [],
    this.adminMessages = const [],
    this.processState = ProcessState.idle,
    this.error,
    this.modeNotification,
  });

  List<ChatMessage> get messages => isAIMode ? aiMessages : adminMessages;

  ChatScreenState copyWith({
    bool? isAIMode,
    List<ChatMessage>? aiMessages,
    List<ChatMessage>? adminMessages,
    ProcessState? processState,
    String? error,
    String? modeNotification,
  }) {
    return ChatScreenState(
      isAIMode: isAIMode ?? this.isAIMode,
      aiMessages: aiMessages ?? this.aiMessages,
      adminMessages: adminMessages ?? this.adminMessages,
      processState: processState ?? this.processState,
      error: error,
      modeNotification: modeNotification,
    );
  }
}
