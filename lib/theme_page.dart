import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ThemePage extends StatefulWidget {
  final String userId;
  const ThemePage({Key? key, required this.userId}) : super(key: key);

  @override
  _ThemePageState createState() => _ThemePageState();
}

class _ThemePageState extends State<ThemePage> {
  final List<Map<String, dynamic>> themes = [
    {'name': 'Black & White', 'color': Colors.black},
    {'name': 'Neutral', 'color': Colors.brown},
    {'name': 'Neon', 'color': Colors.purpleAccent},
    {'name': 'Glitter', 'color': Colors.pinkAccent},
    {'name': 'Boho', 'color': Colors.orangeAccent},
    {'name': 'Gold', 'color': Colors.amber},
    {'name': 'Soft', 'color': Colors.grey},
    {'name': 'Pastel', 'color': Colors.lightGreenAccent},
    {'name': 'Cute', 'color': Colors.pink},
    {'name': 'Pink', 'color': Colors.pinkAccent},
    {'name': 'Purple', 'color': Colors.deepPurpleAccent},
    {'name': 'Blue', 'color': Colors.blueAccent},
  ];

  Future<void> _selectTheme(String themeName) async {
    try {
      // Save the selected theme to Firestore for the user
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({'selectedTheme': themeName});

      Navigator.pop(context, themeName); // Return the selected theme
    } catch (e) {
      print("Failed to save theme: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Aesthetics')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: themes.length,
          itemBuilder: (context, index) {
            final theme = themes[index];
            return GestureDetector(
              onTap: () => _selectTheme(theme['name']),
              child: Container(
                decoration: BoxDecoration(
                  color: theme['color'],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    theme['name'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
