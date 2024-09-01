import 'package:flutter/material.dart';
import 'top_chart.dart';

class LeaderBoardPage extends StatelessWidget {
  const LeaderBoardPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LeaderBoard'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch, // Full-width button
          children: [
            const SizedBox(),
            ElevatedButton(
              onPressed: () {
                // Navigate to the Top Chart page
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TopChartPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple, // Button color
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12), // Rounded corners
                ),
                elevation: 4, // Shadow effect
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.bar_chart, // Icon for the button
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Show Top Chart',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
