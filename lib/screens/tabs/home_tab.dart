import 'package:flutter/material.dart';

import '../../models/feedback_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/feedback_card.dart';
import '../feedback_detail_sheet.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final FirestoreService firestoreService = FirestoreService();

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: StreamBuilder<List<FeedbackModel>>(
        stream: firestoreService.getAllFeedback(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final feedbackList = snapshot.data ?? [];
          final total = feedbackList.length;

          final avgRating = total == 0
              ? 0.0
              : feedbackList.map((f) => f.rating).reduce((a, b) => a + b) /
                    total;

          final positiveCount = feedbackList.where((f) => f.rating >= 4).length;
          final positivePercent = total == 0
              ? 0
              : ((positiveCount / total) * 100).round();

          final now = DateTime.now();
          final weekAgo = now.subtract(const Duration(days: 7));
          final thisWeekCount = feedbackList
              .where((f) => f.timestamp.isAfter(weekAgo))
              .length;

          final pendingCount = feedbackList
              .where((f) => f.status == 'New')
              .length;
          final resolvedCount = feedbackList
              .where((f) => f.status == 'Resolved')
              .length;

          final recent = feedbackList.take(5).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: _GradientCard(
                      icon: Icons.add_circle_outline,
                      label: 'Sentiment Score',
                      value: '${avgRating.toStringAsFixed(1)}/5',
                      gradient: const [Color(0xFF1E3C72), Color(0xFF2A5298)],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _RingGradientCard(
                      label: 'Positive',
                      percent: positivePercent.toDouble(),
                      gradient: const [Color(0xFF11998E), Color(0xFF38EF7D)],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _GradientCard(
                      icon: Icons.folder_outlined,
                      label: 'Total Responses',
                      value: '$total',
                      gradient: const [Color(0xFFFFB347), Color(0xFFFFCC33)],
                      compact: true,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _GradientCard(
                      icon: Icons.calendar_today_outlined,
                      label: 'This Week',
                      value: '$thisWeekCount',
                      gradient: const [Color(0xFF9D50BB), Color(0xFF6E48AA)],
                      compact: true,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _GradientCard(
                      icon: Icons.access_time,
                      label: 'Pending Review',
                      value: '$pendingCount',
                      gradient: const [Color(0xFFEB3349), Color(0xFFF45C43)],
                      compact: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _GradientCard(
                      icon: Icons.check_circle_outline,
                      label: 'Resolved',
                      value: '$resolvedCount',
                      gradient: const [Color(0xFF56AB2F), Color(0xFFA8E063)],
                      compact: true,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: StreamBuilder<int>(
                      stream: firestoreService.getTotalUsersCount(),
                      builder: (context, usersSnapshot) {
                        final usersCount = usersSnapshot.data ?? 0;
                        return _GradientCard(
                          icon: Icons.people_outline,
                          label: 'Total Users',
                          value: '$usersCount',
                          gradient: const [
                            Color(0xFF2980B9),
                            Color(0xFF6DD5FA),
                          ],
                          compact: true,
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              const Text(
                'Recent Feedback',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              if (recent.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: Text('No feedback yet.')),
                )
              else
                ...recent.map(
                  (f) => FeedbackCard(
                    feedback: f,
                    onTap: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      builder: (_) => FeedbackDetailSheet(feedback: f),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _GradientCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final List<Color> gradient;
  final bool compact;

  const _GradientCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.gradient,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 14 : 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(icon, color: Colors.white70, size: 14),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
    );
  }
}

class _RingGradientCard extends StatelessWidget {
  final String label;
  final double percent;
  final List<Color> gradient;

  const _RingGradientCard({
    required this.label,
    required this.percent,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.check_circle_outline,
                color: Colors.white70,
                size: 14,
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 56,
            height: 56,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 56,
                  height: 56,
                  child: CircularProgressIndicator(
                    value: percent / 100,
                    strokeWidth: 5,
                    backgroundColor: Colors.white.withValues(alpha: 0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                  ),
                ),
                Text(
                  '${percent.toInt()}%',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
