import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/feedback_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/feedback_card.dart';
import '../feedback_detail_sheet.dart';
import '../submit_feedback_sheet.dart';

class MyFeedbackTab extends StatelessWidget {
  const MyFeedbackTab({super.key});

  Future<void> _confirmDelete(
    BuildContext context,
    FirestoreService service,
    String id,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Feedback?'),
        content: const Text('Ye action wapas nahi ho sakta.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await service.deleteFeedback(id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Feedback deleted.')));
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to delete feedback.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return const Center(child: Text('Please log in to view your feedback.'));
    }

    return StreamBuilder<List<FeedbackModel>>(
      stream: firestoreService.getUserFeedback(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          );
        }

        final feedback = snapshot.data ?? const <FeedbackModel>[];
        if (feedback.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Aapne abhi tak koi feedback submit nahi kiya.\n"Submit" button dabakar shuru karo.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 80),
          itemCount: feedback.length,
          itemBuilder: (context, index) {
            final item = feedback[index];
            return FeedbackCard(
              feedback: item,
              actions: [
                IconButton(
                  tooltip: 'Edit feedback',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.edit, size: 18, color: Colors.grey),
                  onPressed: () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    builder: (_) => SubmitFeedbackSheet(existingFeedback: item),
                  ),
                ),
                IconButton(
                  tooltip: 'Delete feedback',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                  onPressed: () =>
                      _confirmDelete(context, firestoreService, item.id),
                ),
              ],
              onTap: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (_) =>
                    FeedbackDetailSheet(feedback: item, canEditStatus: false),
              ),
            );
          },
        );
      },
    );
  }
}
