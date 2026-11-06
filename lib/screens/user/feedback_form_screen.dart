import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/feedback_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/star_rating.dart';

class FeedbackFormScreen extends StatefulWidget {
  const FeedbackFormScreen({super.key, this.isBottomSheet = false});

  final bool isBottomSheet;

  @override
  State<FeedbackFormScreen> createState() => _FeedbackFormScreenState();
}

class _FeedbackFormScreenState extends State<FeedbackFormScreen> {
  final _taskController = TextEditingController();
  final _commentController = TextEditingController();
  late final FirebaseAuth _auth = FirebaseAuth.instance;
  late final FirestoreService _firestoreService = FirestoreService();

  String _selectedCategory = 'Course';
  double _rating = 0;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _taskController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_taskController.text.trim().isEmpty || _rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task/Course name aur rating dono zaroori hain'),
        ),
      );
      return;
    }

    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to submit feedback')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final feedback = FeedbackModel(
        id: '',
        userId: user.uid,
        userName: user.email ?? 'Unknown',
        taskOrCourse: _taskController.text.trim(),
        category: _selectedCategory,
        rating: _rating,
        comment: _commentController.text.trim(),
        timestamp: DateTime.now(),
      );

      await _firestoreService.submitFeedback(feedback);

      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _rating = 0;
      });
      _taskController.clear();
      _commentController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Feedback submitted successfully!')),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $error')));
    }
  }

  Future<void> _handleLogout() async {
    try {
      await _auth.signOut();
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Logout failed: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Submit Feedback'),
        leading: widget.isBottomSheet
            ? IconButton(
                tooltip: 'Close',
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        actions: [
          if (!widget.isBottomSheet)
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Log out',
              onPressed: _handleLogout,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'Course', child: Text('Course')),
                DropdownMenuItem(value: 'Task', child: Text('Task')),
                DropdownMenuItem(value: 'Service', child: Text('Service')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _selectedCategory = value);
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _taskController,
              decoration: const InputDecoration(
                labelText: 'Task / Course Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Your Rating',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            StarRating(
              rating: _rating,
              onRatingChanged: (value) => setState(() => _rating = value),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _commentController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Comments / Suggestions',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 24),
            _isSubmitting
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _handleSubmit,
                    child: const Text('Submit Feedback'),
                  ),
          ],
        ),
      ),
    );
  }
}
