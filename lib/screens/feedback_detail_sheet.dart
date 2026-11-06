import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/feedback_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class FeedbackDetailSheet extends StatefulWidget {
  const FeedbackDetailSheet({
    super.key,
    required this.feedback,
    this.canEditStatus = true,
  });

  final FeedbackModel feedback;
  final bool canEditStatus;

  @override
  State<FeedbackDetailSheet> createState() => _FeedbackDetailSheetState();
}

class _FeedbackDetailSheetState extends State<FeedbackDetailSheet> {
  late final FirestoreService _firestoreService = FirestoreService();
  late final Future<String?> _userRoleFuture;
  late String _status;
  bool _updating = false;

  @override
  void initState() {
    super.initState();
    _status = widget.feedback.status;
    if (!widget.canEditStatus) {
      _userRoleFuture = Future<String?>.value(null);
    } else {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      _userRoleFuture = userId == null
          ? Future<String?>.value(null)
          : AuthService().getUserRole(userId);
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Reviewed':
        return Colors.orange;
      case 'Resolved':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    if (_updating || _status == newStatus) return;
    setState(() => _updating = true);

    try {
      await _firestoreService.updateFeedbackStatus(
        widget.feedback.id,
        newStatus,
      );
      if (!mounted) return;
      setState(() {
        _status = newStatus;
        _updating = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Status updated to $newStatus')));
    } catch (_) {
      if (!mounted) return;
      setState(() => _updating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to update feedback status.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final feedback = widget.feedback;

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
                  feedback.taskOrCourse,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  feedback.category,
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < feedback.rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 22,
                    );
                  }),
                ),
                const SizedBox(height: 16),
                Text(
                  feedback.comment.isEmpty
                      ? 'No comment provided.'
                      : feedback.comment,
                  style: const TextStyle(fontSize: 15),
                ),
                const SizedBox(height: 12),
                Text(
                  '${feedback.userName} • ${DateFormat('dd MMM yyyy, hh:mm a').format(feedback.timestamp)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),
                if (widget.canEditStatus)
                  FutureBuilder<String?>(
                    future: _userRoleFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasData && snapshot.data == 'admin') {
                        return _buildStatusControls();
                      }
                      return _buildReadOnlyStatus();
                    },
                  )
                else
                  _buildReadOnlyStatus(),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReadOnlyStatus() {
    final color = _statusColor(_status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        'Status: $_status',
        style: TextStyle(fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  Widget _buildStatusControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Update Status',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        if (_updating)
          const Center(child: CircularProgressIndicator())
        else
          Wrap(
            spacing: 8,
            children: ['New', 'Reviewed', 'Resolved'].map((status) {
              return ChoiceChip(
                label: Text(status),
                selected: _status == status,
                onSelected: (_) => _updateStatus(status),
              );
            }).toList(),
          ),
      ],
    );
  }
}
