import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/feedback_model.dart';
import '../services/firestore_service.dart';
import '../widgets/star_rating.dart';

class SubmitFeedbackSheet extends StatefulWidget {
  const SubmitFeedbackSheet({super.key, this.existingFeedback});

  final FeedbackModel? existingFeedback;

  @override
  State<SubmitFeedbackSheet> createState() => _SubmitFeedbackSheetState();
}

class _SubmitFeedbackSheetState extends State<SubmitFeedbackSheet> {
  late final TextEditingController _topicController;
  late final TextEditingController _messageController;
  late final FirestoreService _firestoreService = FirestoreService();

  final List<String> _categories = [
    'Course',
    'Instructor',
    'Task',
    'Internship',
    'Service',
    'Other',
    'General',
  ];

  late String _selectedCategory;
  late double _rating;
  bool _isSubmitting = false;

  bool get _isEditMode => widget.existingFeedback != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingFeedback;
    _topicController = TextEditingController(
      text: existing?.taskOrCourse ?? '',
    );
    _messageController = TextEditingController(text: existing?.comment ?? '');
    final existingCategory = existing?.category;
    if (existingCategory != null && !_categories.contains(existingCategory)) {
      _categories.add(existingCategory);
    }
    _selectedCategory = existingCategory ?? _categories.first;
    _rating = existing?.rating ?? 0;
  }

  Future<void> _handleSubmit() async {
    if (_isSubmitting) return;
    if (_topicController.text.trim().isEmpty || _rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task/Course name aur rating dono zaroori hain'),
        ),
      );
      return;
    }

    final user = _isEditMode ? null : FirebaseAuth.instance.currentUser;
    if (!_isEditMode && user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to submit feedback.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final existing = widget.existingFeedback;
      if (existing != null) {
        await _firestoreService.updateFeedback(
          feedbackId: existing.id,
          taskOrCourse: _topicController.text.trim(),
          category: _selectedCategory,
          rating: _rating,
          comment: _messageController.text.trim(),
        );
      } else {
        final feedback = FeedbackModel(
          id: '',
          userId: user!.uid,
          userName: user.email ?? 'Unknown',
          taskOrCourse: _topicController.text.trim(),
          category: _selectedCategory,
          rating: _rating,
          comment: _messageController.text.trim(),
          status: 'New',
          timestamp: DateTime.now(),
        );
        await _firestoreService.submitFeedback(feedback);
      }

      if (!mounted) return;

      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            _isEditMode
                ? 'Feedback updated!'
                : 'Feedback submitted successfully!',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $error')));
    }
  }

  @override
  void dispose() {
    _topicController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _isEditMode ? 'Edit Feedback' : 'Submit Feedback',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  key: const Key('feedback-category'),
                  initialValue: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: _categories
                      .map(
                        (category) => DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedCategory = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  'Your Rating',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                StarRating(
                  rating: _rating,
                  onRatingChanged: (value) => setState(() => _rating = value),
                ),
                const SizedBox(height: 16),
                TextField(
                  key: const Key('feedback-topic'),
                  controller: _topicController,
                  decoration: const InputDecoration(
                    labelText: 'Topic',
                    hintText: 'e.g. Onboarding, Support, App Speed',
                    border: OutlineInputBorder(),
                  ),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                TextField(
                  key: const Key('feedback-message'),
                  controller: _messageController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Message',
                    hintText: 'Tell us more...',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: _isSubmitting
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: _handleSubmit,
                          child: Text(
                            _isEditMode ? 'Update Feedback' : 'Submit Feedback',
                          ),
                        ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
