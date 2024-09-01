// habit_details_page.dart
import 'package:flutter/material.dart';
import '/firebase/firebase_service.dart';
import '../model/habit.dart';
import 'package:intl/intl.dart';

class HabitDetailsPage extends StatelessWidget {
  final String userId;
  final Habit habit;
  final FirebaseService _firebaseService = FirebaseService();
  final String? theme;

  HabitDetailsPage(
      {required this.userId, required this.habit, required this.theme});

  Future<List<DateTime>> _getCompletionDates() async {
    return await _firebaseService.getCompletedDates(userId, habit.id);
  }

  Future<List<String>> convertFutureDateTimeToStrings(
      Future<List<DateTime>> futureDateTimes) async {
    // Wait for the Future<List<DateTime>> to resolve
    List<DateTime> dateTimes = await futureDateTimes;

    // Convert each DateTime to a String
    List<String> stringDates = dateTimes.map((date) {
      return DateFormat('yyyy-MM-dd HH:mm')
          .format(date); // Customize format as needed
    }).toList();

    return stringDates;
  }

  @override
  Widget build(BuildContext context) {
    //todo themes
    String? theme = this.theme;

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
          title: Text('${habit.name} Details'),
          backgroundColor: appBarColor,
        ),
        body: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                backgroundImage, // Provide the correct path to your image
                fit: BoxFit.cover,
              ),
            ),
            FutureBuilder<List<String>>(
              future: convertFutureDateTimeToStrings(_getCompletionDates()),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error loading dates'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No completion dates yet'));
                } else {
                  final dates = snapshot.data!;
                  return ListView.builder(
                    itemCount: dates.length,
                    itemBuilder: (context, index) {
                      final date = dates[index];
                      return ListTile(
                        title: Text(date.toString()),
                      );
                    },
                  );
                }
              },
            ),
          ],
        ));
  }
}
