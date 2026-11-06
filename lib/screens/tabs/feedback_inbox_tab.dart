import 'package:flutter/material.dart';

import '../../models/feedback_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/feedback_card.dart';
import '../feedback_detail_sheet.dart';

class FeedbackInboxTab extends StatefulWidget {
  const FeedbackInboxTab({super.key});

  @override
  State<FeedbackInboxTab> createState() => _FeedbackInboxTabState();
}

class _FeedbackInboxTabState extends State<FeedbackInboxTab> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();

  String _selectedStatus = 'All';
  String _selectedCategory = 'All';
  String _selectedRating = 'All';
  String _searchQuery = '';

  final List<String> _categories = [
    'All',
    'Course',
    'Instructor',
    'Task',
    'Internship',
    'Service',
    'Other',
    'General',
  ];
  final List<String> _ratings = ['All', '5', '4', '3', '2', '1'];

  void _openDetail(FeedbackModel feedback) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => FeedbackDetailSheet(feedback: feedback),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by topic, comment or name...',
              prefixIcon: const Icon(Icons.search, size: 20),
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
            ),
            onChanged: (value) =>
                setState(() => _searchQuery = value.toLowerCase()),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['All', 'New', 'Reviewed', 'Resolved'].map((filter) {
                final isSelected = _selectedStatus == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _selectedStatus = filter),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: _categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _selectedCategory = value!),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedRating,
                  decoration: const InputDecoration(
                    labelText: 'Rating',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: _ratings
                      .map(
                        (r) => DropdownMenuItem(
                          value: r,
                          child: Text(r == 'All' ? 'All' : '$r★'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _selectedRating = value!),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: StreamBuilder<List<FeedbackModel>>(
            stream: _firestoreService.getAllFeedback(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('No feedback yet.'));
              }

              var list = snapshot.data!;

              if (_selectedStatus != 'All') {
                list = list.where((f) => f.status == _selectedStatus).toList();
              }
              if (_selectedCategory != 'All') {
                list = list
                    .where((f) => f.category == _selectedCategory)
                    .toList();
              }
              if (_selectedRating != 'All') {
                list = list
                    .where(
                      (f) => f.rating.round() == int.parse(_selectedRating),
                    )
                    .toList();
              }
              if (_searchQuery.isNotEmpty) {
                list = list
                    .where(
                      (f) =>
                          f.taskOrCourse.toLowerCase().contains(_searchQuery) ||
                          f.comment.toLowerCase().contains(_searchQuery) ||
                          f.userName.toLowerCase().contains(_searchQuery),
                    )
                    .toList();
              }

              if (list.isEmpty) {
                return const Center(
                  child: Text('No feedback matches these filters.'),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.only(bottom: 80),
                itemCount: list.length,
                itemBuilder: (context, index) {
                  return FeedbackCard(
                    feedback: list[index],
                    onTap: () => _openDetail(list[index]),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
