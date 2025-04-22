import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../enums/processing/process_state_enum.dart';
import '../../../generated/l10n.dart';
import '../../../objects/chat_related/chat_message.dart';
import '../../../services/ai_service.dart';
import 'chat_screen_state.dart';

class ChatScreenCubit extends Cubit<ChatScreenState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AIService _aiService = AIService();
  static const String _lastModeKey = 'last_chat_mode';
  static const String _aiMessagesKey = 'ai_messages';
  static const String _adminMessagesKey = 'admin_messages';
  static const String _lastAIWelcomeTimeKey = 'last_ai_welcome_time';
  static const String _lastAdminWelcomeTimeKey = 'last_admin_welcome_time';
  SharedPreferences? _prefs;
  bool _hasShownModeNotification = false;
  bool _hasShownAdminReplyMessage = false;

  ChatScreenCubit() : super(ChatScreenState()) {
    _initPrefs();
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    _hasShownModeNotification =
        _prefs?.getBool('hasShownModeNotification') ?? false;

    // Khôi phục tin nhắn từ SharedPreferences
    final aiMessagesJson = _prefs?.getStringList(_aiMessagesKey) ?? [];
    final adminMessagesJson = _prefs?.getStringList(_adminMessagesKey) ?? [];

    final aiMessages =
        aiMessagesJson.map((json) => ChatMessage.fromJson(json)).toList();
    final adminMessages =
        adminMessagesJson.map((json) => ChatMessage.fromJson(json)).toList();

    emit(state.copyWith(
      aiMessages: aiMessages,
      adminMessages: adminMessages,
    ));
  }

  Future<void> _saveMessagesToPrefs() async {
    final aiMessagesJson = state.aiMessages.map((msg) => msg.toJson()).toList();
    final adminMessagesJson =
        state.adminMessages.map((msg) => msg.toJson()).toList();

    await _prefs?.setStringList(_aiMessagesKey, aiMessagesJson);
    await _prefs?.setStringList(_adminMessagesKey, adminMessagesJson);
  }

  Future<void> _loadLastMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isAIMode = prefs.getBool(_lastModeKey) ?? true;
      emit(state.copyWith(isAIMode: isAIMode));
    } catch (e) {
      if (kDebugMode) {
        print('Error loading last mode: $e');
      }
    }
  }

  Future<void> _saveLastMode(bool isAIMode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_lastModeKey, isAIMode);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving last mode: $e');
      }
    }
  }

  bool _shouldShowWelcomeMessage(bool isAIMode) {
    final lastWelcomeTimeKey =
        isAIMode ? _lastAIWelcomeTimeKey : _lastAdminWelcomeTimeKey;
    final lastWelcomeTime = _prefs?.getString(lastWelcomeTimeKey);
    if (lastWelcomeTime == null) return true;

    final lastTime = DateTime.parse(lastWelcomeTime);
    final now = DateTime.now();
    final difference = now.difference(lastTime);

    return difference.inHours >= 24;
  }

  Future<void> _updateLastWelcomeTime(bool isAIMode) async {
    final lastWelcomeTimeKey =
        isAIMode ? _lastAIWelcomeTimeKey : _lastAdminWelcomeTimeKey;
    await _prefs?.setString(
        lastWelcomeTimeKey, DateTime.now().toIso8601String());
  }

  void initialize(BuildContext context) async {
    try {
      emit(state.copyWith(processState: ProcessState.loading));

      await _loadLastMode();

      final user = _auth.currentUser;
      if (user == null) {
        if (kDebugMode) {
          print('User not logged in');
        }
        emit(state.copyWith(
          processState: ProcessState.failure,
          error: 'User not logged in',
        ));
        return;
      }

      // Load messages from Firebase
      final firebaseAiMessages = await _loadMessages(user.uid, true);
      final firebaseAdminMessages = await _loadMessages(user.uid, false);

      // Khôi phục tin nhắn từ SharedPreferences chỉ để lấy tin nhắn bot
      final aiMessagesJson = _prefs?.getStringList(_aiMessagesKey) ?? [];
      final adminMessagesJson = _prefs?.getStringList(_adminMessagesKey) ?? [];

      final localAiMessages = aiMessagesJson
          .map((json) => ChatMessage.fromJson(json))
          .where((msg) => msg.isBot) // Chỉ lấy tin nhắn bot
          .toList();
      final localAdminMessages = adminMessagesJson
          .map((json) => ChatMessage.fromJson(json))
          .where((msg) => msg.isBot) // Chỉ lấy tin nhắn bot
          .toList();

      // Kết hợp tin nhắn
      final List<ChatMessage> mergedAiMessages = [...firebaseAiMessages];
      final List<ChatMessage> mergedAdminMessages = [...firebaseAdminMessages];

      // Thêm tin nhắn bot từ local vào đầu danh sách
      mergedAiMessages.insertAll(0, localAiMessages);
      mergedAdminMessages.insertAll(0, localAdminMessages);

      // Sắp xếp theo thời gian
      mergedAiMessages.sort((a, b) => (b.timestamp)
          .compareTo(a.timestamp));
      mergedAdminMessages.sort((a, b) => (b.timestamp)
          .compareTo(a.timestamp));

      // Thêm tin nhắn chào mừng nếu cần
      if (mergedAiMessages.isEmpty) {
        final aiWelcomeMessage = ChatMessage.fromBot(
          S.of(context).aiWelcomeMessage,
          true,
        );
        mergedAiMessages.insert(0, aiWelcomeMessage);
      }

      if (mergedAdminMessages.isEmpty) {
        final adminWelcomeMessage = ChatMessage.fromBot(
          S.of(context).adminWelcomeMessage,
          false,
        );
        mergedAdminMessages.insert(0, adminWelcomeMessage);
      }

      emit(state.copyWith(
        aiMessages: mergedAiMessages,
        adminMessages: mergedAdminMessages,
        processState: ProcessState.success,
      ));

      // Lưu messages vào SharedPreferences
      await _saveMessagesToPrefs();
    } catch (e) {
      emit(state.copyWith(
        processState: ProcessState.failure,
        error: e.toString(),
      ));
    }
  }

  Future<List<ChatMessage>> _loadMessages(String userId, bool isAIMode) async {
    final messagesSnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection(isAIMode ? 'ai_messages' : 'admin_messages')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .get();

    return messagesSnapshot.docs
        .map((doc) => ChatMessage.fromMap(doc.data()))
        .toList();
  }

  Future<bool> _saveMessageToFirebase(ChatMessage message) async {
    // Không lưu tin nhắn của bot vào Firebase
    if (message.isBot) {
      return true;
    }

    try {
      final user = _auth.currentUser;
      if (user == null) {
        if (kDebugMode) {
          print('User not logged in');
        }
        emit(state.copyWith(
          processState: ProcessState.failure,
          error: 'User not logged in',
        ));
        return false;
      }

      final messageRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection(state.isAIMode ? 'ai_messages' : 'admin_messages')
          .doc();

      final messageData = message.toMap();
      messageData['messageId'] = messageRef.id;
      messageData['timestamp'] = FieldValue.serverTimestamp();

      await messageRef.set(messageData);
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error saving message: $e');
      }
      emit(state.copyWith(
        processState: ProcessState.failure,
        error: 'Error saving message: ${e.toString()}',
      ));
      return false;
    }
  }

  void sendMessage(String content, BuildContext context) async {
    try {
      emit(state.copyWith(processState: ProcessState.loading));

      final user = _auth.currentUser;
      if (user == null) {
        if (kDebugMode) {
          print('User not logged in');
        }
        emit(state.copyWith(
          processState: ProcessState.failure,
          error: 'User not logged in',
        ));
        return;
      }

      final userMessage = ChatMessage.fromUser(
        content,
        user.uid,
        state.isAIMode,
      );

      // Save user message to Firebase
      final savedUserMessage = await _saveMessageToFirebase(userMessage);
      if (!savedUserMessage) return;

      // Update UI with user message
      if (state.isAIMode) {
        emit(state.copyWith(
          aiMessages: [userMessage, ...state.aiMessages],
          processState: ProcessState.loading,
        ));

        // Gọi AI để tạo câu trả lời
        final response = await _aiService.generateResponse(content);
        final botMessage = ChatMessage.fromBot(response, true);

        emit(state.copyWith(
          aiMessages: [botMessage, ...state.aiMessages],
          processState: ProcessState.success,
        ));
      } else {
        emit(state.copyWith(
          adminMessages: [userMessage, ...state.adminMessages],
          processState: ProcessState.loading,
        ));

        // Chỉ hiển thị thông báo admin reply một lần
        if (!_hasShownAdminReplyMessage) {
          final response = S.of(context).firstAdminResponse;
          _hasShownAdminReplyMessage = true;
          final botMessage = ChatMessage.fromBot(response, false);
          emit(state.copyWith(
            adminMessages: [botMessage, ...state.adminMessages],
            processState: ProcessState.success,
          ));
        }
      }

      // Lưu messages vào SharedPreferences sau mỗi lần gửi tin nhắn
      await _saveMessagesToPrefs();
    } catch (e) {
      emit(state.copyWith(
        processState: ProcessState.failure,
        error: e.toString(),
      ));
    }
  }

  void switchToAI() async {
    try {
      emit(state.copyWith(processState: ProcessState.loading));
      await _saveLastMode(true);

      final user = _auth.currentUser;
      if (user == null) {
        emit(state.copyWith(
          processState: ProcessState.failure,
          error: 'User not logged in',
        ));
        return;
      }

      // Kiểm tra xem có nên hiển thị tin nhắn chào mừng cho chế độ AI không
      if (state.aiMessages.isEmpty || _shouldShowWelcomeMessage(true)) {
        final welcomeMessage = ChatMessage.fromBot(
          S.of(context as BuildContext).aiWelcomeMessage,
          true,
        );

        // Cập nhật thời gian chào mừng cuối cùng cho AI mode
        await _updateLastWelcomeTime(true);

        emit(state.copyWith(
          isAIMode: true,
          aiMessages: [welcomeMessage, ...state.aiMessages],
          processState: ProcessState.success,
        ));

        // Lưu messages vào SharedPreferences
        await _saveMessagesToPrefs();
      } else {
        // Nếu chưa đủ 24 giờ, chỉ chuyển mode
        emit(state.copyWith(
          isAIMode: true,
          processState: ProcessState.success,
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        processState: ProcessState.failure,
        error: e.toString(),
      ));
    }
  }

  void switchToAdmin() async {
    try {
      emit(state.copyWith(processState: ProcessState.loading));
      await _saveLastMode(false);

      final user = _auth.currentUser;
      if (user == null) {
        if (kDebugMode) {
          print('User not logged in');
        }
        emit(state.copyWith(
          processState: ProcessState.failure,
          error: 'User not logged in',
        ));
        return;
      }

      // Kiểm tra xem có nên hiển thị tin nhắn chào mừng cho chế độ Admin không
      if (state.adminMessages.isEmpty || _shouldShowWelcomeMessage(false)) {
        final welcomeMessage = ChatMessage.fromBot(
          S.of(context as BuildContext).adminWelcomeMessage,
          false,
        );

        // Cập nhật thời gian chào mừng cuối cùng cho Admin mode
        await _updateLastWelcomeTime(false);

        emit(state.copyWith(
          isAIMode: false,
          adminMessages: [welcomeMessage, ...state.adminMessages],
          processState: ProcessState.success,
        ));

        // Lưu messages vào SharedPreferences
        await _saveMessagesToPrefs();
      } else {
        // Nếu chưa đủ 24 giờ, chỉ chuyển mode
        emit(state.copyWith(
          isAIMode: false,
          processState: ProcessState.success,
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        processState: ProcessState.failure,
        error: e.toString(),
      ));
    }
  }

  Future<void> toggleMode() async {
    final newMode = !state.isAIMode;
    if (newMode) {
      switchToAI();
    } else {
      switchToAdmin();
    }
  }
}
