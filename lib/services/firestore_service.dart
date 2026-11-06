import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/feedback_model.dart';

class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore})
    : _feedbackCollection = (firestore ?? FirebaseFirestore.instance)
          .collection('feedbacks'),
      _usersCollection = (firestore ?? FirebaseFirestore.instance).collection(
        'users',
      );

  final CollectionReference<Map<String, dynamic>> _feedbackCollection;
  final CollectionReference<Map<String, dynamic>> _usersCollection;

  Future<void> submitFeedback(FeedbackModel feedback) async {
    await _feedbackCollection.add(feedback.toMap());
  }

  Future<void> updateFeedbackStatus(String feedbackId, String newStatus) async {
    await _feedbackCollection.doc(feedbackId).update({'status': newStatus});
  }

  Future<void> updateFeedback({
    required String feedbackId,
    required String taskOrCourse,
    required String category,
    required double rating,
    required String comment,
  }) async {
    await _feedbackCollection.doc(feedbackId).update({
      'taskOrCourse': taskOrCourse,
      'category': category,
      'rating': rating,
      'comment': comment,
    });
  }

  Future<void> deleteFeedback(String feedbackId) async {
    await _feedbackCollection.doc(feedbackId).delete();
  }

  Stream<int> getTotalUsersCount() {
    return _usersCollection.snapshots().map((snapshot) => snapshot.size);
  }

  Stream<List<FeedbackModel>> getUserFeedback(String userId) {
    return _feedbackCollection
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(_mapFeedbackDocuments);
  }

  Stream<List<FeedbackModel>> getAllFeedback() {
    return _feedbackCollection
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(_mapFeedbackDocuments);
  }

  Stream<List<Map<String, dynamic>>> getAllUsers() {
    return _usersCollection.snapshots().map(
      (snapshot) => snapshot.docs.map((doc) {
        final data = doc.data();
        data['uid'] = doc.id;
        return data;
      }).toList(),
    );
  }

  Future<void> addAdminReply(String feedbackId, String reply) async {
    await _feedbackCollection.doc(feedbackId).update({'adminReply': reply});
  }

  List<FeedbackModel> _mapFeedbackDocuments(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    return snapshot.docs
        .map((document) => FeedbackModel.fromMap(document.id, document.data()))
        .toList();
  }
}
