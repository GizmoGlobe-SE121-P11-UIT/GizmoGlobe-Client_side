import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String messageId;
  final String content;
  final String senderId;
  final String receiverId;
  final bool isAIMode;
  final DateTime timestamp;
  final String userId;

  ChatMessage({
    required this.messageId,
    required this.content,
    required this.senderId,
    required this.receiverId,
    required this.isAIMode,
    required this.timestamp,
    required this.userId,
  });

  factory ChatMessage.fromUser(String content, String senderId, bool isAIMode) {
    return ChatMessage(
      messageId: '',
      content: content,
      senderId: senderId,
      receiverId: isAIMode ? 'ai' : 'admin',
      isAIMode: isAIMode,
      timestamp: DateTime.now(),
      userId: senderId,
    );
  }

  factory ChatMessage.fromBot(String content, bool isAIMode,
      {String? receiverId}) {
    return ChatMessage(
      messageId: '',
      content: content,
      senderId: isAIMode ? 'ai' : 'admin',
      receiverId: receiverId ?? '',
      isAIMode: isAIMode,
      timestamp: DateTime.now(),
      userId: receiverId ?? '',
    );
  }

  bool get isFromBot => senderId == 'ai' || senderId == 'admin';
  bool get isFromUser => !isFromBot;
  bool get isFromAI => senderId == 'ai';
  bool get isFromAdmin => senderId == 'admin';

  Map<String, dynamic> toMap() {
    return {
      'messageId': messageId,
      'content': content,
      'senderId': senderId,
      'receiverId': receiverId,
      'isAIMode': isAIMode,
      'timestamp': timestamp,
      'userId': userId,
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    DateTime timestamp;
    if (map['timestamp'] is Timestamp) {
      timestamp = (map['timestamp'] as Timestamp).toDate();
    } else if (map['timestamp'] is int) {
      timestamp = DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int);
    } else {
      timestamp = DateTime.now();
    }

    return ChatMessage(
      messageId: map['messageId'] ?? '',
      content: map['content'] ?? '',
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      isAIMode: map['isAIMode'] ?? true,
      timestamp: timestamp,
      userId: map['userId'] ?? '',
    );
  }

  String toJson() {
    return json.encode({
      'messageId': messageId,
      'content': content,
      'senderId': senderId,
      'receiverId': receiverId,
      'isAIMode': isAIMode,
      'timestamp': timestamp.toIso8601String(),
      'userId': userId,
    });
  }

  factory ChatMessage.fromJson(String jsonString) {
    final Map<String, dynamic> jsonMap = json.decode(jsonString);
    return ChatMessage(
      messageId: jsonMap['messageId'] as String,
      content: jsonMap['content'] as String,
      senderId: jsonMap['senderId'] as String,
      receiverId: jsonMap['receiverId'] as String,
      isAIMode: jsonMap['isAIMode'] as bool,
      timestamp: DateTime.parse(jsonMap['timestamp'] as String),
      userId: jsonMap['userId'] as String,
    );
  }

  ChatMessage copyWith({
    String? messageId,
    String? content,
    String? senderId,
    String? receiverId,
    bool? isAIMode,
    DateTime? timestamp,
    String? userId,
  }) {
    return ChatMessage(
      messageId: messageId ?? this.messageId,
      content: content ?? this.content,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      isAIMode: isAIMode ?? this.isAIMode,
      timestamp: timestamp ?? this.timestamp,
      userId: userId ?? this.userId,
    );
  }
}
