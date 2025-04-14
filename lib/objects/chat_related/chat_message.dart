import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String messageId;
  final String content;
  final String senderId;
  final bool isBot;
  final bool isAIMode;
  final DateTime timestamp;

  ChatMessage({
    required this.messageId,
    required this.content,
    required this.senderId,
    required this.isBot,
    required this.isAIMode,
    required this.timestamp,
  });

  factory ChatMessage.fromUser(String content, String senderId, bool isAIMode) {
    return ChatMessage(
      messageId: '',
      content: content,
      senderId: senderId,
      isBot: false,
      isAIMode: isAIMode,
      timestamp: DateTime.now(),
    );
  }

  factory ChatMessage.fromBot(String content, bool isAIMode) {
    return ChatMessage(
      messageId: '',
      content: content,
      senderId: 'bot',
      isBot: true,
      isAIMode: isAIMode,
      timestamp: DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'messageId': messageId,
      'content': content,
      'senderId': senderId,
      'isBot': isBot,
      'isAIMode': isAIMode,
      'timestamp': timestamp,
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      messageId: map['messageId'] ?? '',
      content: map['content'] ?? '',
      senderId: map['senderId'] ?? '',
      isBot: map['isBot'] ?? false,
      isAIMode: map['isAIMode'] ?? true,
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }

  String toJson() {
    return json.encode({
      'messageId': messageId,
      'content': content,
      'senderId': senderId,
      'isBot': isBot,
      'isAIMode': isAIMode,
      'timestamp': timestamp.toIso8601String(),
    });
  }

  factory ChatMessage.fromJson(String jsonString) {
    final Map<String, dynamic> jsonMap = json.decode(jsonString);
    return ChatMessage(
      messageId: jsonMap['messageId'] as String,
      content: jsonMap['content'] as String,
      senderId: jsonMap['senderId'] as String,
      isBot: jsonMap['isBot'] as bool,
      isAIMode: jsonMap['isAIMode'] as bool,
      timestamp: DateTime.parse(jsonMap['timestamp'] as String),
    );
  }
}
