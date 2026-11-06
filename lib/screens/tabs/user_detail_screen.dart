import 'package:flutter/material.dart';

import '../../models/feedback_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/feedback_card.dart';
import '../feedback_detail_sheet.dart';

class UserDetailScreen extends StatelessWidget {
  const UserDetailScreen({super.key, required this.user});

  final Map<String, dynamic> user;

  @override
  Widget build(BuildContext context) {
    final name = (user['name'] ?? 'User').toString();
    final email = (user['email'] ?? '').toString();
    final role = (user['role'] ?? 'user').toString();
    final uid = (user['uid'] ?? '').toString();
    final firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Theme.of(context).primaryColor,
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(email, style: TextStyle(color: Colors.grey[600])),
                const SizedBox(height: 8),
                Chip(
                  label: Text(role),
                  backgroundColor: role == 'admin'
                      ? Colors.deepPurple.withValues(alpha: 0.12)
                      : Colors.green.withValues(alpha: 0.12),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<FeedbackModel>>(
              stream: firestoreService.getUserFeedback(uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final feedbacks = snapshot.data ?? const <FeedbackModel>[];
                if (feedbacks.isEmpty) {
                  return const Center(
                    child: Text('No feedback submitted yet.'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: feedbacks.length,
                  itemBuilder: (context, index) {
                    final item = feedbacks[index];
                    return FeedbackCard(
                      feedback: item,
                      onTap: () => showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                        ),
                        builder: (_) => FeedbackDetailSheet(feedback: item),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
