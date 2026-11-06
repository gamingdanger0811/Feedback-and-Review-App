import 'package:flutter/material.dart';

import '../../services/firestore_service.dart';
import 'user_detail_screen.dart';

class UsersTab extends StatelessWidget {
  const UsersTab({super.key});

  @override
  Widget build(BuildContext context) {
    final FirestoreService firestoreService = FirestoreService();

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: firestoreService.getAllUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Unable to load users: ${snapshot.error}'));
        }

        final users = snapshot.data ?? const <Map<String, dynamic>>[];
        if (users.isEmpty) {
          return const Center(child: Text('No users found.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.only(top: 12, bottom: 80),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            final name = (user['name'] ?? 'User').toString();
            final email = (user['email'] ?? '').toString();
            final role = (user['role'] ?? 'user').toString();

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: role == 'admin'
                      ? Colors.deepPurple.withValues(alpha: 0.18)
                      : Colors.blue.withValues(alpha: 0.18),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'U',
                    style: TextStyle(
                      color: role == 'admin' ? Colors.deepPurple : Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(name),
                subtitle: Text(email),
                trailing: Chip(
                  label: Text(role),
                  backgroundColor: role == 'admin'
                      ? Colors.deepPurple.withValues(alpha: 0.12)
                      : Colors.green.withValues(alpha: 0.12),
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => UserDetailScreen(user: user),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
