import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/feedback_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/feedback_card.dart';
import 'analytics_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late final FirebaseAuth _auth = FirebaseAuth.instance;
  late final FirestoreService _firestoreService = FirestoreService();
  late final Stream<List<FeedbackModel>> _feedbackStream = _firestoreService
      .getAllFeedback();

  String _filterCategory = 'All';
  bool _isAddingSampleFeedback = false;

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

  Future<void> _addSampleFeedback() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add sample feedback?'),
        content: const Text(
          'This adds 15 clearly labeled demo entries with mixed ratings '
          'to the feedback dashboard. Existing entries are left unchanged.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Add samples'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to add sample feedback.')),
      );
      return;
    }

    setState(() => _isAddingSampleFeedback = true);
    try {
      final addedCount = await _firestoreService.addSampleFeedback(user.uid);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            addedCount == 0
                ? 'Sample feedback has already been added.'
                : 'Added $addedCount sample feedback entries.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not add sample feedback: $error')),
      );
    } finally {
      if (mounted) setState(() => _isAddingSampleFeedback = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Analytics',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: DropdownButtonFormField<String>(
              initialValue: _filterCategory,
              decoration: const InputDecoration(
                labelText: 'Filter by Category',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'All', child: Text('All')),
                DropdownMenuItem(value: 'Course', child: Text('Course')),
                DropdownMenuItem(value: 'Task', child: Text('Task')),
                DropdownMenuItem(value: 'Service', child: Text('Service')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _filterCategory = value);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: OutlinedButton.icon(
              onPressed: _isAddingSampleFeedback ? null : _addSampleFeedback,
              icon: _isAddingSampleFeedback
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.science_outlined),
              label: Text(
                _isAddingSampleFeedback
                    ? 'Adding sample feedback...'
                    : 'Add 15 sample feedback entries',
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<FeedbackModel>>(
              stream: _feedbackStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No feedback yet.'));
                }

                final feedbackList = _filterCategory == 'All'
                    ? snapshot.data!
                    : snapshot.data!
                          .where(
                            (feedback) => feedback.category == _filterCategory,
                          )
                          .toList();

                if (feedbackList.isEmpty) {
                  return const Center(
                    child: Text('No feedback in this category.'),
                  );
                }

                final averageRating =
                    feedbackList
                        .map((feedback) => feedback.rating)
                        .reduce((first, second) => first + second) /
                    feedbackList.length;

                return Column(
                  children: [
                    Card(
                      margin: const EdgeInsets.all(12),
                      color: Colors.blue.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                Text(
                                  '${feedbackList.length}',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Text('Total Feedback'),
                              ],
                            ),
                            Column(
                              children: [
                                Text(
                                  averageRating.toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Text('Avg Rating'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: feedbackList.length,
                        itemBuilder: (context, index) {
                          return FeedbackCard(feedback: feedbackList[index]);
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
