import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
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
  static const String _hasShownAdminReminderKey = 'has_shown_admin_reminder';
  SharedPreferences? _prefs;
  bool _hasShownModeNotification = false;
  bool _hasShownAdminReplyMessage = false;
  StreamSubscription? _adminMessagesSubscription;

  ChatScreenCubit() : super(ChatScreenState()) {
    _initPrefs();
  }

  @override
  Future<void> close() {
    _adminMessagesSubscription?.cancel();
    return super.close();
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    _hasShownModeNotification =
        _prefs?.getBool('hasShownModeNotification') ?? false;
    _hasShownAdminReplyMessage =
        _prefs?.getBool(_hasShownAdminReminderKey) ?? false;

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

      // Set up real-time listener for admin messages
      _setupAdminMessagesListener(user.uid);

      // Load messages from Firebase
      final firebaseAiMessages = await _loadMessages(user.uid, true);
      final firebaseAdminMessages = await _loadMessages(user.uid, false);

      // Get local messages from SharedPreferences
      final aiMessagesJson = _prefs?.getStringList(_aiMessagesKey) ?? [];
      final adminMessagesJson = _prefs?.getStringList(_adminMessagesKey) ?? [];

      final localAiMessages =
          aiMessagesJson.map((json) => ChatMessage.fromJson(json)).toList();
      final localAdminMessages =
          adminMessagesJson.map((json) => ChatMessage.fromJson(json)).toList();

      // Merge messages, prioritizing Firebase messages for new messages
      final List<ChatMessage> mergedAiMessages =
          _mergeMessagesWithFirebasePriority(
              localAiMessages, firebaseAiMessages);
      final List<ChatMessage> mergedAdminMessages =
          _mergeMessagesWithFirebasePriority(
              localAdminMessages, firebaseAdminMessages);

      // Add welcome messages if needed
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

      await _saveMessagesToPrefs();
    } catch (e) {
      emit(state.copyWith(
        processState: ProcessState.failure,
        error: e.toString(),
      ));
    }
  }

  void _setupAdminMessagesListener(String userId) {
    _adminMessagesSubscription?.cancel();
    _adminMessagesSubscription = _firestore
        .collection('chats')
        .doc(userId)
        .snapshots()
        .listen((snapshot) async {
      if (!snapshot.exists) return;

      final data = snapshot.data() as Map<String, dynamic>;
      final messages = data['messages'] as List<dynamic>? ?? [];

      final adminMessages = messages
          .map((msg) => ChatMessage.fromMap(msg as Map<String, dynamic>))
          .where((msg) => !msg.isAIMode && msg.isFromBot)
          .toList();

      if (adminMessages.isNotEmpty) {
        final currentAdminMessages = state.adminMessages;
        final newMessages = adminMessages
            .where((msg) => !currentAdminMessages.any((existing) =>
                existing.content == msg.content &&
                existing.timestamp == msg.timestamp))
            .toList();

        if (newMessages.isNotEmpty) {
          final updatedMessages = [...newMessages, ...currentAdminMessages];
          updatedMessages.sort((a, b) => b.timestamp.compareTo(a.timestamp));

          emit(state.copyWith(
            adminMessages: updatedMessages,
          ));

          await _saveMessagesToPrefs();

          // Show admin response reminder only once per conversation
          if (!_hasShownAdminReplyMessage) {
            _hasShownAdminReplyMessage = true;
            await _prefs?.setBool(_hasShownAdminReminderKey, true);
            emit(state.copyWith(
              modeNotification: 'Admin will respond to your message shortly...',
            ));
          }
        }
      }
    });
  }

  List<ChatMessage> _mergeMessagesWithFirebasePriority(
      List<ChatMessage> localMessages, List<ChatMessage> firebaseMessages) {
    final Map<String, ChatMessage> messageMap = {};

    // Add local messages first
    for (var message in localMessages) {
      messageMap[message.content] = message;
    }

    // Add Firebase messages, overwriting local messages if they exist
    for (var message in firebaseMessages) {
      messageMap[message.content] = message;
    }

    // Convert map values to list and sort by timestamp
    final mergedMessages = messageMap.values.toList();
    mergedMessages.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return mergedMessages;
  }

  Future<List<ChatMessage>> _loadMessages(String userId, bool isAIMode) async {
    final messagesSnapshot =
        await _firestore.collection('chats').doc(userId).get();

    if (!messagesSnapshot.exists) {
      return [];
    }

    final data = messagesSnapshot.data() as Map<String, dynamic>;
    final messages = data['messages'] as List<dynamic>? ?? [];

    return messages
        .map((msg) => ChatMessage.fromMap(msg as Map<String, dynamic>))
        .where((msg) => msg.isAIMode == isAIMode)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  Future<bool> _saveMessageToFirebase(ChatMessage message) async {
    // Only save user messages and AI responses
    if (message.isFromBot && !message.isAIMode) {
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

      final userRef = _firestore.collection('chats').doc(user.uid);
      final messageData = message.toMap();
      final timestamp = DateTime.now();
      messageData['messageId'] = timestamp.millisecondsSinceEpoch.toString();
      messageData['userId'] = user.uid;
      messageData['timestamp'] = Timestamp.fromDate(timestamp);

      await userRef.set({
        'messages': FieldValue.arrayUnion([messageData])
      }, SetOptions(merge: true));

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

      // Check if message already exists in local storage
      final existingMessages =
          state.isAIMode ? state.aiMessages : state.adminMessages;
      final isDuplicate = existingMessages.any((msg) => msg.content == content);

      if (!isDuplicate) {
        // Save user message to Firebase
        final savedUserMessage = await _saveMessageToFirebase(userMessage);
        if (!savedUserMessage) return;

        // Update UI with user message
        if (state.isAIMode) {
          emit(state.copyWith(
            aiMessages: [userMessage, ...state.aiMessages],
            processState: ProcessState.loading,
          ));

          // Get AI response
          final response =
              await _aiService.generateResponse(content, userId: user.uid);
          final botMessage = ChatMessage.fromBot(
            response,
            true,
            receiverId: user.uid,
          );

          // Save AI response to Firebase
          await _saveMessageToFirebase(botMessage);

          emit(state.copyWith(
            aiMessages: [botMessage, ...state.aiMessages],
            processState: ProcessState.success,
          ));
        } else {
          emit(state.copyWith(
            adminMessages: [userMessage, ...state.adminMessages],
            processState: ProcessState.loading,
          ));

          if (!_hasShownAdminReplyMessage) {
            final response = S.of(context).firstAdminResponse;
            _hasShownAdminReplyMessage = true;
            final botMessage = ChatMessage.fromBot(
              response,
              false,
              receiverId: user.uid,
            );
            emit(state.copyWith(
              adminMessages: [botMessage, ...state.adminMessages],
              processState: ProcessState.success,
            ));
          } else {
            emit(state.copyWith(
              processState: ProcessState.success,
            ));
          }
        }

        await _saveMessagesToPrefs();
      } else {
        emit(state.copyWith(processState: ProcessState.success));
      }
    } catch (e) {
      emit(state.copyWith(
        processState: ProcessState.failure,
        error: e.toString(),
      ));
    }
  }

  Future<void> switchToAdmin(String adminWelcomeMessage) async {
    try {
      emit(state.copyWith(processState: ProcessState.loading));
      await _saveLastMode(false);

      final user = _auth.currentUser;
      if (user == null) {
        emit(state.copyWith(
          processState: ProcessState.failure,
          error: 'User not logged in',
        ));
        return;
      }

      if (state.adminMessages.isEmpty || _shouldShowWelcomeMessage(false)) {
        final welcomeMessage = ChatMessage.fromBot(adminWelcomeMessage, false);

        await _updateLastWelcomeTime(false);

        emit(state.copyWith(
          isAIMode: false,
          adminMessages: [welcomeMessage, ...state.adminMessages],
          processState: ProcessState.success,
        ));

        await _saveMessagesToPrefs();
      } else {
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

  Future<void> switchToAI(String aiWelcomeMessage) async {
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

      if (state.aiMessages.isEmpty || _shouldShowWelcomeMessage(true)) {
        final welcomeMessage = ChatMessage.fromBot(aiWelcomeMessage, true);

        await _updateLastWelcomeTime(true);

        emit(state.copyWith(
          isAIMode: true,
          aiMessages: [welcomeMessage, ...state.aiMessages],
          processState: ProcessState.success,
        ));

        await _saveMessagesToPrefs();
      } else {
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

  // Future<void> toggleMode() async {
  //   final newMode = !state.isAIMode;
  //   if (newMode) {
  //     switchToAI();
  //   } else {
  //     switchToAdmin();
  //   }
  // }
}
