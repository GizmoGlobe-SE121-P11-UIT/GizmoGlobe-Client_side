import 'package:cloud_firestore/cloud_firestore.dart';

class Rating {
  String? ratingID;
  String userID;
  String? username;
  String productID;
  DateTime timeSent;
  int rating;
  String? comment;
  List<String>? imagesUrl;
  String? videoUrl;

  Rating({
    this.ratingID = '',
    required this.userID,
    required this.productID,
    required this.timeSent,
    required this.rating,
    this.username,
    this.comment,
    this.imagesUrl,
    this.videoUrl,
  });

  List<Object?> get props => [
    ratingID,
    userID,
    productID,
    timeSent,
    rating,
    username,
    comment,
    imagesUrl,
    videoUrl,
  ];

  Rating copyWith({
    String? ratingID,
    String? userID,
    String? productID,
    DateTime? timeSent,
    int? rating,
    String? comment,
    String? username,
    List<String>? imagesUrl,
    String? videoUrl,
  }) {
    return Rating(
      ratingID: ratingID ?? this.ratingID,
      userID: userID ?? this.userID,
      productID: productID ?? this.productID,
      timeSent: timeSent ?? this.timeSent,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      username: username ?? this.username,
      imagesUrl: imagesUrl ?? this.imagesUrl,
      videoUrl: videoUrl ?? this.videoUrl,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ratingID': ratingID,
      'userID': userID,
      'productID': productID,
      'timeSent': timeSent,
      'rating': rating,
      'comment': comment,
      'imagesUrl': imagesUrl,
      'videoUrl': videoUrl,
    };
  }

  static Rating fromMap(String id, Map<String, dynamic> map) {
    final timeValue = map['timeSent'];
    DateTime parsedTime;
    if (timeValue is Timestamp) {
      parsedTime = timeValue.toDate();
    } else if (timeValue is String) {
      parsedTime = DateTime.tryParse(timeValue) ?? DateTime.now();
    } else if (timeValue is DateTime) {
      parsedTime = timeValue;
    } else {
      parsedTime = DateTime.now();
    }

    final ratingVal = map['rating'];
    int? parsedRating;
    if (ratingVal is int) {
      parsedRating = ratingVal;
    } else if (ratingVal is num) {
      parsedRating = ratingVal.toInt();
    } else if (ratingVal is String) {
      parsedRating = int.tryParse(ratingVal);
    } else {
      parsedRating = null;
    }

    List<String>? parsedImages;
    final imagesVal = map['imagesUrl'];
    if (imagesVal is List) {
      parsedImages = imagesVal.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList();
      if (parsedImages.isEmpty) parsedImages = null;
    } else if (imagesVal is String && imagesVal.isNotEmpty) {
      parsedImages = [imagesVal];
    } else {
      parsedImages = null;
    }

    final videoVal = map['videoUrl'];
    final parsedVideo = (videoVal is String && videoVal.isNotEmpty) ? videoVal : null;

    return Rating(
      ratingID: id,
      userID: (map['userID'] as String?) ?? '',
      productID: (map['productID'] as String?) ?? (map['productId'] as String?) ?? '',
      timeSent: parsedTime,
      rating: parsedRating ?? 0,
      comment: map['comment'] as String?,
      imagesUrl: parsedImages,
      videoUrl: parsedVideo,
    );
  }
}
