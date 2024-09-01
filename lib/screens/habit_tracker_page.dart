import 'package:flutter/material.dart';
import '../firebase/firebase_service.dart';
import '../model/habit.dart';
import '../services/firebase_service.dart';
import 'habit_datails_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HabitTrackerPage extends StatefulWidget {
  final String userId;
  final String? theme;

  const HabitTrackerPage({Key? key, required this.userId, required this.theme})
      : super(key: key);

  @override
  State<HabitTrackerPage> createState() => _HabitTrackerPageState();
}

class _HabitTrackerPageState extends State<HabitTrackerPage> {
  final TextEditingController _habitController = TextEditingController();
  final FirebaseService _firebaseService = FirebaseService();
  List<Habit> _habits = [];

  @override
  void initState() {
    super.initState();
    _loadHabits();
  }

  @override
  void dispose() {
    _habitController.dispose();
    super.dispose();
  }

  Future<void> _loadHabits() async {
    try {
      final habits = await _firebaseService.getHabits(widget.userId);
      setState(() {
        _habits = habits;
      });
    } catch (e) {
      _showErrorSnackbar('Failed to load habits');
    }
  }

  Future<void> _addHabit() async {
    final habitName = _habitController.text.trim();
    if (habitName.isEmpty) return;

    final habit = Habit(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: habitName,
      createdAt: DateTime.now(),
    );

    try {
      await _firebaseService.createOrUpdateHabit(widget.userId, habit);
      _habitController.clear();
      await _loadHabits();
    } catch (e) {
      _showErrorSnackbar('Failed to add habit');
    }
  }

  Future<void> _toggleCompletion(Habit habit) async {
    final today = DateTime.now();
    final todayWithoutTime = DateTime(today.year, today.month, today.day);

    try {
      final completedDates =
          await _firebaseService.getCompletedDates(widget.userId, habit.id);
      final alreadyCompletedToday = completedDates.any((date) =>
          date.year == todayWithoutTime.year &&
          date.month == todayWithoutTime.month &&
          date.day == todayWithoutTime.day);

      if (alreadyCompletedToday) {
        _showInfoSnackbar('Habit already completed today!');
      } else {
        // todo xp integration
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .get();

        int currentXp = userDoc.get('xp') ?? 0;
        int currentLevel = userDoc.get('level') ?? 1;
        int xpForNextLevel = 100 + (currentLevel - 1) * 50;

        int xpGain = 50;
        currentXp += xpGain;

        if (currentXp >= xpForNextLevel) {
          currentLevel++;
        }

        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .update({
          'level': currentLevel,
          'xp': currentXp,
        });

        setState(() {});
        // todo xpintegration
        await _firebaseService.addCompletedDate(
            widget.userId, habit.id, todayWithoutTime);
        await _loadHabits();
      }
    } catch (e) {
      _showErrorSnackbar('$e ${widget.userId}');
    }
  }

  void _navigateToHabitDetails(Habit habit) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HabitDetailsPage(
          userId: widget.userId,
          habit: habit,
          theme: widget.theme,
        ),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _showInfoSnackbar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    //todo themes
    String? theme = widget.theme;

    final String backgroundImage;
    if (theme == 'Black & White') {
      backgroundImage = 'android/assets/images/white.jpg';
    } else if (theme == 'Neon') {
      backgroundImage = 'android/assets/images/The last.jpg';
    } else if (theme == 'Gold') {
      backgroundImage = 'android/assets/images/abstract.png';
    } else if (theme == 'Boho') {
      backgroundImage = 'android/assets/images/boho.jpg';
    } else if (theme == 'Glitter') {
      backgroundImage = 'android/assets/images/Cowboy.jpg';
    } else if (theme == 'Soft') {
      backgroundImage = 'android/assets/images/soft1.jpg';
    } else if (theme == 'Neutral') {
      backgroundImage = 'android/assets/images/nuetral.jpg';
    } else {
      backgroundImage = 'android/assets/images/pintrest.png'; // Fallback image
    }

    // Determine the app bar color based on selected theme
    final Color appBarColor;
    if (theme == 'Black & White') {
      appBarColor = Colors.black;
    } else if (theme == 'Neon') {
      appBarColor = Colors.purpleAccent;
    } else if (theme == 'Neutral') {
      appBarColor = Colors.brown;
    } else if (theme == 'Glitter') {
      appBarColor = Colors.redAccent;
    } else if (theme == 'Gold') {
      appBarColor = Colors.orange;
    } else if (theme == 'Soft') {
      appBarColor = Colors.grey;
    } else if (theme == 'Pastel') {
      appBarColor = Colors.lightGreenAccent;
    } else if (theme == 'Cute') {
      appBarColor = Colors.deepOrange;
    } else if (theme == 'Pink') {
      appBarColor = Colors.pink;
    } else {
      appBarColor = Colors.blueAccent; // Default app bar color
    }
    // todo themes
    return Scaffold(
      appBar: AppBar(
        title: const Text('Habit Tracker'),
        backgroundColor: appBarColor,
      ),
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              backgroundImage, // Provide the correct path to your image
              fit: BoxFit.cover,
            ),
          ),
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _habitController,
                  decoration: const InputDecoration(
                    labelText: 'New Habit',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: _addHabit,
                child: const Text('Add Habit'),
              ),
              Expanded(
                child: _habits.isEmpty
                    ? const Center(child: Text('No habits yet!'))
                    : ListView.builder(
                        itemCount: _habits.length,
                        itemBuilder: (context, index) {
                          final habit = _habits[index];
                          return ListTile(
                            title: Text(habit.name),
                            subtitle:
                                Text('Created on ${habit.createdAt.toLocal()}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.check),
                              onPressed: () => _toggleCompletion(habit),
                            ),
                            onTap: () => _navigateToHabitDetails(habit),
                          );
                        },
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
