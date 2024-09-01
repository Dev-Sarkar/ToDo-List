import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TopChartPage extends StatelessWidget {
  const TopChartPage({Key? key}) : super(key: key);

  // Fetch all user data sorted by level and XP in descending order
  Future<List<Map<String, dynamic>>> _fetchAllUsers() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .orderBy('level', descending: true)
          .orderBy('xp', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => {
                'fullName': doc['fullName'] ?? 'Unknown',
                'level': doc['level'] ?? 0,
                'xp': doc['xp'] ?? 0,
              })
          .toList();
    } catch (e) {
      print('Error fetching users: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Leaderboard')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchAllUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError ||
              snapshot.data == null ||
              snapshot.data!.isEmpty) {
            return const Center(child: Text('No users found.'));
          }

          final users = snapshot.data!;

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];

              if (index == 0) {
                // Highlight top user
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: ListTile(
                    leading: CircleAvatar(
                      radius: 40,
                      child: const Text(
                        'Top',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    title: Text(
                      user['fullName'],
                      style: const TextStyle(
                        fontSize: 24, // Larger font for name
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      'Level: ${user['level']} | XP: ${user['xp']}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                );
              } else {
                return ListTile(
                  leading: CircleAvatar(
                    child: Text('${index + 1}'), // Display rank
                  ),
                  title: Text(user['fullName']),
                  subtitle: Text('Level: ${user['level']} | XP: ${user['xp']}'),
                );
              }
            },
          );
        },
      ),
    );
  }
}
