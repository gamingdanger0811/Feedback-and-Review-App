import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../models/feedback_model.dart';
import '../../services/firestore_service.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: StreamBuilder<List<FeedbackModel>>(
        stream: firestoreService.getAllFeedback(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Unable to load analytics.'));
          }

          final feedbackList = snapshot.data;
          if (feedbackList == null || feedbackList.isEmpty) {
            return const Center(child: Text('No data available yet.'));
          }

          final categoryCount = <String, int>{};
          for (final feedback in feedbackList) {
            categoryCount.update(
              feedback.category,
              (count) => count + 1,
              ifAbsent: () => 1,
            );
          }

          final ratingCount = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
          for (final feedback in feedbackList) {
            final rating = feedback.rating.round();
            if (rating >= 1 && rating <= 5) {
              ratingCount.update(rating, (count) => count + 1);
            }
          }

          final averageRating =
              feedbackList
                  .map((feedback) => feedback.rating)
                  .reduce((total, rating) => total + rating) /
              feedbackList.length;
          final maxRatingCount = ratingCount.values.reduce(
            (maximum, count) => count > maximum ? count : maximum,
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        label: 'Total Feedback',
                        value: '${feedbackList.length}',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SummaryCard(
                        label: 'Average Rating',
                        value: averageRating.toStringAsFixed(1),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Rating Distribution',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 200,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: maxRatingCount.toDouble() + 1,
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) => SideTitleWidget(
                              meta: meta,
                              child: Text('${value.toInt()}★'),
                            ),
                          ),
                        ),
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: true),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: ratingCount.entries.map((entry) {
                        return BarChartGroupData(
                          x: entry.key,
                          barRods: [
                            BarChartRodData(
                              toY: entry.value.toDouble(),
                              color: Colors.amber,
                              width: 24,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Feedback by Category',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 220,
                  child: PieChart(
                    PieChartData(
                      sections: categoryCount.entries.map((entry) {
                        final colors = <String, Color>{
                          'Course': Colors.blue,
                          'Task': Colors.green,
                          'Service': Colors.orange,
                        };
                        return PieChartSectionData(
                          value: entry.value.toDouble(),
                          title: '${entry.key}\n(${entry.value})',
                          color: colors[entry.key] ?? Colors.grey,
                          radius: 80,
                          titleStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        );
                      }).toList(),
                      sectionsSpace: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
