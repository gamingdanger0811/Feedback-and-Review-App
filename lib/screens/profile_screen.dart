import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('No user logged in.')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: FutureBuilder<String?>(
        future: AuthService().getUserRole(user.uid),
        builder: (context, snapshot) {
          final role = snapshot.data ?? 'user';
          final initials = (user.displayName ?? user.email ?? 'U')
              .trim()
              .split(RegExp(r'\s+'))
              .take(2)
              .map((part) => part.isNotEmpty ? part[0].toUpperCase() : '')
              .join();

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 12),
                CircleAvatar(
                  radius: 46,
                  backgroundColor: Theme.of(context).primaryColor,
                  child: Text(
                    initials.isEmpty ? 'U' : initials,
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  user.displayName ?? 'User',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  user.email ?? 'No email',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 12),
                Chip(
                  label: Text(role.toUpperCase()),
                  backgroundColor: role == 'admin'
                      ? Colors.deepPurple.withValues(alpha: 0.12)
                      : Colors.blue.withValues(alpha: 0.12),
                  labelStyle: TextStyle(
                    color: role == 'admin' ? Colors.deepPurple : Colors.blue,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 24),
                _ProfileTile(
                  icon: Icons.email_outlined,
                  title: 'Email',
                  value: user.email ?? 'Not available',
                ),
                _ProfileTile(
                  icon: Icons.verified_user_outlined,
                  title: 'Role',
                  value: role,
                ),
                _ProfileTile(
                  icon: Icons.calendar_today_outlined,
                  title: 'Member since',
                  value: user.metadata.creationTime != null
                      ? '${user.metadata.creationTime!.day}/${user.metadata.creationTime!.month}/${user.metadata.creationTime!.year}'
                      : 'N/A',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
