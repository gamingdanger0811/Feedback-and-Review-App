import 'package:cloud_firestore/cloud_firestore.dart';

class FeedbackModel {
  const FeedbackModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.taskOrCourse,
    required this.category,
    required this.rating,
    required this.comment,
    this.status = 'New',
    required this.timestamp,
  });

  final String id;
  final String userId;
  final String userName;
  final String taskOrCourse;
  final String category;
  final double rating;
  final String comment;
  final String status;
  final DateTime timestamp;

  factory FeedbackModel.fromMap(String id, Map<String, dynamic> map) {
    final rawRating = map['rating'];
    final rawTimestamp = map['timestamp'];

    return FeedbackModel(
      id: id,
      userId: map['userId'] as String? ?? '',
      userName: map['userName'] as String? ?? '',
      taskOrCourse: map['taskOrCourse'] as String? ?? '',
      category: map['category'] as String? ?? '',
      rating: rawRating is num ? rawRating.toDouble() : 0,
      comment: map['comment'] as String? ?? '',
      status: map['status'] as String? ?? 'New',
      timestamp: rawTimestamp is Timestamp
          ? rawTimestamp.toDate()
          : rawTimestamp is DateTime
          ? rawTimestamp
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'taskOrCourse': taskOrCourse,
      'category': category,
      'rating': rating,
      'comment': comment,
      'status': status,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }
}
