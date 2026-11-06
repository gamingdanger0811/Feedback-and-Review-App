import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/feedback_model.dart';

class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _feedbackCollection = (firestore ?? FirebaseFirestore.instance)
          .collection('feedbacks'),
      _usersCollection = (firestore ?? FirebaseFirestore.instance).collection(
        'users',
      );

  final FirebaseFirestore _firestore;
  final CollectionReference<Map<String, dynamic>> _feedbackCollection;
  final CollectionReference<Map<String, dynamic>> _usersCollection;

  static const _sampleFeedback = [
    (
      userName: 'Demo Reviewer 01',
      taskOrCourse: 'Flutter Fundamentals',
      category: 'Course',
      rating: 5.0,
      comment: 'The lessons were clear, practical, and easy to follow.',
    ),
    (
      userName: 'Demo Reviewer 02',
      taskOrCourse: 'Instructor Support',
      category: 'Instructor',
      rating: 5.0,
      comment: 'The instructor explained difficult topics patiently.',
    ),
    (
      userName: 'Demo Reviewer 03',
      taskOrCourse: 'Mobile App Project',
      category: 'Task',
      rating: 4.0,
      comment: 'A useful project that helped me practice what I learned.',
    ),
    (
      userName: 'Demo Reviewer 04',
      taskOrCourse: 'Internship Onboarding',
      category: 'Internship',
      rating: 5.0,
      comment: 'The onboarding steps were organized and welcoming.',
    ),
    (
      userName: 'Demo Reviewer 05',
      taskOrCourse: 'Student Help Desk',
      category: 'Service',
      rating: 4.0,
      comment: 'My question was answered quickly and courteously.',
    ),
    (
      userName: 'Demo Reviewer 06',
      taskOrCourse: 'Database Workshop',
      category: 'Course',
      rating: 5.0,
      comment: 'Great examples made the database concepts much easier.',
    ),
    (
      userName: 'Demo Reviewer 07',
      taskOrCourse: 'Weekly Progress Review',
      category: 'Task',
      rating: 4.0,
      comment: 'The feedback was specific and helped me improve my work.',
    ),
    (
      userName: 'Demo Reviewer 08',
      taskOrCourse: 'Learning Portal',
      category: 'Service',
      rating: 5.0,
      comment: 'The portal is easy to navigate and works well on mobile.',
    ),
    (
      userName: 'Demo Reviewer 09',
      taskOrCourse: 'Course Schedule',
      category: 'Course',
      rating: 3.0,
      comment: 'The content was helpful, but some sessions felt rushed.',
    ),
    (
      userName: 'Demo Reviewer 10',
      taskOrCourse: 'Assignment Instructions',
      category: 'Task',
      rating: 2.0,
      comment: 'Some requirements were unclear and needed extra clarification.',
    ),
    (
      userName: 'Demo Reviewer 11',
      taskOrCourse: 'Internship Check-ins',
      category: 'Internship',
      rating: 2.0,
      comment: 'More regular check-ins would make it easier to raise concerns.',
    ),
    (
      userName: 'Demo Reviewer 12',
      taskOrCourse: 'Support Response Time',
      category: 'Service',
      rating: 1.0,
      comment: 'It took several days to receive a response to my request.',
    ),
    (
      userName: 'Demo Reviewer 13',
      taskOrCourse: 'Advanced Dart Topics',
      category: 'Course',
      rating: 2.0,
      comment: 'The examples skipped steps and were difficult to reproduce.',
    ),
    (
      userName: 'Demo Reviewer 14',
      taskOrCourse: 'Project Workload',
      category: 'Task',
      rating: 1.0,
      comment: 'The deadline was too short for the amount of work required.',
    ),
    (
      userName: 'Demo Reviewer 15',
      taskOrCourse: 'General Program Experience',
      category: 'General',
      rating: 3.0,
      comment: 'A good overall experience, though communication could improve.',
    ),
  ];

  Future<int> addSampleFeedback(String userId) async {
    if (userId.trim().isEmpty) {
      throw ArgumentError.value(userId, 'userId', 'Must not be empty.');
    }

    final documents = await Future.wait(
      List.generate(
        _sampleFeedback.length,
        (index) => _feedbackCollection
            .doc('demo_feedback_${(index + 1).toString().padLeft(2, '0')}')
            .get(),
      ),
    );
    final batch = _firestore.batch();
    var addedCount = 0;

    for (var index = 0; index < _sampleFeedback.length; index++) {
      if (documents[index].exists) continue;

      final sample = _sampleFeedback[index];
      final feedback = FeedbackModel(
        id: documents[index].id,
        userId: userId,
        userName: sample.userName,
        taskOrCourse: sample.taskOrCourse,
        category: sample.category,
        rating: sample.rating,
        comment: sample.comment,
        timestamp: DateTime.now(),
      );
      batch.set(documents[index].reference, {
        ...feedback.toMap(),
        'isSample': true,
      });
      addedCount++;
    }

    if (addedCount > 0) await batch.commit();
    return addedCount;
  }

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
