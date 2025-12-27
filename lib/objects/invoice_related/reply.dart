import 'package:cloud_firestore/cloud_firestore.dart';

class Reply {
  final String id;
  final String comment;
  final DateTime timestamp;

  Reply({
    required this.id,
    required this.comment,
    required this.timestamp,
  });

  factory Reply.fromMap(Map<String, dynamic>? map) {
    if (map == null) return Reply(id: '', comment: '', timestamp: DateTime.now());
    return Reply(
      id: map['id'] ?? '',
      comment: map['comment'] ?? '',
      timestamp: map['timestamp'] is Timestamp
          ? (map['timestamp'] as Timestamp).toDate()
          : (map['timestamp'] is String ? DateTime.tryParse(map['timestamp']) ?? DateTime.now() : DateTime.now()),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'comment': comment,
    'timestamp': Timestamp.fromDate(timestamp),
  };
}
