import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/feedback_model.dart';
import '../../services/firestore_service.dart';

class InsightsTab extends StatelessWidget {
  const InsightsTab({super.key});

  List<MapEntry<String, int>> _extractKeywords(List<FeedbackModel> list) {
    final stopWords = {
      'the',
      'a',
      'an',
      'is',
      'was',
      'were',
      'and',
      'or',
      'to',
      'of',
      'in',
      'on',
      'for',
      'it',
      'this',
      'that',
      'i',
      'we',
      'my',
      'our',
      'with',
      'be',
      'are',
      'but',
      'not',
      'very',
      'so',
      'as',
      'at',
      'has',
      'have',
    };
    final Map<String, int> freq = {};

    for (final feedback in list) {
      final words = feedback.comment
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z\s]'), '')
          .split(RegExp(r'\s+'));
      for (final word in words) {
        if (word.length > 3 && !stopWords.contains(word)) {
          freq[word] = (freq[word] ?? 0) + 1;
        }
      }
    }

    final sorted = freq.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(8).toList();
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return StreamBuilder<List<FeedbackModel>>(
      stream: firestoreService.getAllFeedback(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No data available yet.'));
        }

        final feedbackList = snapshot.data!;
        final averageRating =
            feedbackList
                .map((feedback) => feedback.rating)
                .reduce((sum, next) => sum + next) /
            feedbackList.length;

        final ratingCount = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
        for (final feedback in feedbackList) {
          final rounded = feedback.rating.round();
          if (rounded >= 1 && rounded <= 5) {
            ratingCount[rounded] = (ratingCount[rounded] ?? 0) + 1;
          }
        }

        final categoryCount = <String, int>{};
        for (final feedback in feedbackList) {
          categoryCount[feedback.category] =
              (categoryCount[feedback.category] ?? 0) + 1;
        }

        final positive = feedbackList.where((f) => f.rating >= 4).length;
        final neutral = feedbackList.where((f) => f.rating == 3).length;
        final negative = feedbackList.where((f) => f.rating <= 2).length;

        final newCount = feedbackList.where((f) => f.status == 'New').length;
        final reviewedCount = feedbackList
            .where((f) => f.status == 'Reviewed')
            .length;
        final resolvedCount = feedbackList
            .where((f) => f.status == 'Resolved')
            .length;

        final monthlyCount = <String, int>{};
        for (final feedback in feedbackList) {
          final key = DateFormat('MMM yyyy').format(feedback.timestamp);
          monthlyCount[key] = (monthlyCount[key] ?? 0) + 1;
        }

        final sortedMonths = monthlyCount.keys.toList()
          ..sort(
            (a, b) =>
                DateFormat('MMM yyyy')
                    .parse(a)
                    .compareTo(DateFormat('MMM yyyy').parse(b)),
          );

        final keywords = _extractKeywords(feedbackList);
        final maxKeywordCount = keywords.isEmpty ? 1 : keywords.first.value;

        final maxRatingCount = ratingCount.values.isEmpty
            ? 1
            : ratingCount.values.reduce((a, b) => a > b ? a : b);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                color: Colors.indigo.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Average Rating',
                        style: TextStyle(fontSize: 14),
                      ),
                      Text(
                        averageRating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                'Rating Distribution',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 220,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: maxRatingCount.toDouble() + 1,
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            return Text('${value.toInt()}★');
                          },
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
                    barGroups: [5, 4, 3, 2, 1].map((star) {
                      return BarChartGroupData(
                        x: star,
                        barRods: [
                          BarChartRodData(
                            toY: (ratingCount[star] ?? 0).toDouble(),
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
              const SizedBox(height: 28),

              const Text(
                'Feedback by Category',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 200,
                child: PieChart(
                  PieChartData(
                    sections: categoryCount.entries.map((entry) {
                      final colors = {
                        'Course': Colors.blue,
                        'Instructor': Colors.teal,
                        'Task': Colors.green,
                        'Internship': Colors.orange,
                        'Service': Colors.purple,
                        'Other': Colors.brown,
                        'General': Colors.grey,
                      };
                      return PieChartSectionData(
                        value: entry.value.toDouble(),
                        title: '${entry.key}\n(${entry.value})',
                        color: colors[entry.key] ?? Colors.blueGrey,
                        radius: 75,
                        titleStyle: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      );
                    }).toList(),
                    sectionsSpace: 2,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              const Text(
                'Positive vs Negative Feedback',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 200,
                child: PieChart(
                  PieChartData(
                    sections: [
                      if (positive > 0)
                        PieChartSectionData(
                          value: positive.toDouble(),
                          title: 'Positive\n($positive)',
                          color: Colors.green,
                          radius: 75,
                          titleStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      if (neutral > 0)
                        PieChartSectionData(
                          value: neutral.toDouble(),
                          title: 'Neutral\n($neutral)',
                          color: Colors.amber,
                          radius: 75,
                          titleStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      if (negative > 0)
                        PieChartSectionData(
                          value: negative.toDouble(),
                          title: 'Negative\n($negative)',
                          color: Colors.red,
                          radius: 75,
                          titleStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                    ],
                    sectionsSpace: 2,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              const Text(
                'Resolved vs Pending',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 200,
                child: PieChart(
                  PieChartData(
                    sections: [
                      if (newCount > 0)
                        PieChartSectionData(
                          value: newCount.toDouble(),
                          title: 'Pending\n($newCount)',
                          color: Colors.blue,
                          radius: 75,
                          titleStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      if (reviewedCount > 0)
                        PieChartSectionData(
                          value: reviewedCount.toDouble(),
                          title: 'Reviewed\n($reviewedCount)',
                          color: Colors.orange,
                          radius: 75,
                          titleStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      if (resolvedCount > 0)
                        PieChartSectionData(
                          value: resolvedCount.toDouble(),
                          title: 'Resolved\n($resolvedCount)',
                          color: Colors.green,
                          radius: 75,
                          titleStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                    ],
                    sectionsSpace: 2,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              const Text(
                'Monthly Feedback Trend',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 200,
                child: sortedMonths.length < 2
                    ? const Center(
                        child: Text(
                          'Trend dekhne ke liye kam se kam 2 different months ka data chahiye.',
                        ),
                      )
                    : LineChart(
                        LineChartData(
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  final index = value.toInt();
                                  if (index < 0 ||
                                      index >= sortedMonths.length) {
                                    return const SizedBox();
                                  }
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(
                                      sortedMonths[index],
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                  );
                                },
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
                          lineBarsData: [
                            LineChartBarData(
                              spots: List.generate(
                                sortedMonths.length,
                                (index) => FlSpot(
                                  index.toDouble(),
                                  (monthlyCount[sortedMonths[index]] ?? 0)
                                      .toDouble(),
                                ),
                              ),
                              isCurved: true,
                              color: Colors.indigo,
                              barWidth: 3,
                              dotData: const FlDotData(show: true),
                              belowBarData: BarAreaData(
                                show: true,
                                color: const Color(0x334B5CFF),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
              const SizedBox(height: 28),

              const Text(
                'What People Mention',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              if (keywords.isEmpty)
                const Text('Not enough comments yet.')
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: keywords.map((entry) {
                    final intensity = entry.value / maxKeywordCount;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.indigo.withValues(
                          alpha: 0.08 + (intensity * 0.25),
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${entry.key} (${entry.value})',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.indigo,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}
