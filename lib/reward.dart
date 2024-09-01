import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DailyRewardPopup extends StatefulWidget {
  final String userId;
  final VoidCallback onRewardClaimed;

  const DailyRewardPopup({
    Key? key,
    required this.userId,
    required this.onRewardClaimed,
  }) : super(key: key);

  @override
  _DailyRewardPopupState createState() => _DailyRewardPopupState();
}

class _DailyRewardPopupState extends State<DailyRewardPopup> {
  int currentStreak = 0;
  bool showPopup = true;

  List<Map<String, dynamic>> rewards = [
    {'day': 1, 'reward': '10 Coins', 'coins': 10},
    {'day': 2, 'reward': '30 Coins', 'coins': 30},
    {'day': 3, 'reward': '50 Coins', 'coins': 50},
    {'day': 4, 'reward': '100 Coins', 'coins': 100},
    {'day': 5, 'reward': '200 Coins', 'coins': 200},
    {'day': 6, 'reward': 'Avatar Reward', 'isAvatar': true},
    {'day': 7, 'reward': 'Theme Reward', 'darkTheme': true},
  ];

  @override
  void initState() {
    super.initState();
    _fetchDailyReward();
  }

  Future<void> _fetchDailyReward() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (userDoc.exists) {
        int streak = userDoc.data()?['loginStreak'] ?? 0;
        DateTime? lastClaimed =
            (userDoc.data()?['lastClaimed'] as Timestamp?)?.toDate();

        // Calculate time if 24 hours have passed
        bool canClaim = lastClaimed == null ||
            DateTime.now().difference(lastClaimed) >= Duration(hours: 24);

        setState(() {
          currentStreak = streak;
          showPopup = canClaim;
        });
      }
    } catch (e) {
      print('Failed to fetch daily reward: $e');
    }
  }

  Future<void> _claimReward() async {
    final isWeek = currentStreak >= 7;

    final rewardCoins = isWeek
        ? 100 // 100 coins for 8th day and beyond
        : (rewards[currentStreak]['coins'] ?? 0);

    // Prepare Firestore updates
    final updates = <String, dynamic>{
      'coins': FieldValue.increment(rewardCoins),
      'lastLoginDate': FieldValue.serverTimestamp(),
      'loginStreak': FieldValue.increment(1),
      'lastClaimed': FieldValue.serverTimestamp(),
    };

    if (!isWeek) {
      // Handle special rewards for the first 7 days
      if (rewards[currentStreak]['isAvatar'] == true) {
        updates['purchasedAvatars'] =
            FieldValue.arrayUnion(['android/assets/images/mafia.jpg']);
      }
      if (rewards[currentStreak]['darkTheme'] == true) {
        updates['selectedTheme'] = 'darkTheme'; // Assign darkTheme
      }
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update(updates);

      widget.onRewardClaimed();
    } catch (e) {
      print('Failed to claim reward: $e');
      return;
    }

    setState(() {
      showPopup = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(isWeek
          ? 'Reward claimed: 100 Coins'
          : 'Reward claimed: ${rewards[currentStreak]['reward']}'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (!showPopup) return const SizedBox.shrink();

    // Check if dark theme should be applied for Day 7
    bool isDarkTheme =
        currentStreak < 7 && (rewards[currentStreak]['darkTheme'] ?? false);

    return AlertDialog(
      backgroundColor: isDarkTheme ? Colors.black : Colors.deepPurple[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      title: const Text(
        "Daily Reward",
        style: TextStyle(
          color: Colors.yellow,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Claim your daily reward!",
            style: TextStyle(color: Colors.white70, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.purple[700],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  "Today's Reward",
                  style: TextStyle(
                    color: Colors.yellow,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                currentStreak < 7 && rewards[currentStreak]['isAvatar'] == true
                    ? CircleAvatar(
                        radius: 30,
                        backgroundImage:
                            AssetImage('android/assets/images/mafia.jpg'),
                      )
                    : Text(
                        currentStreak < 7
                            ? rewards[currentStreak]['reward']
                            : '100 Coins',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _claimReward,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.yellow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text(
              "CLAIM",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.close, color: Colors.red),
          onPressed: () {
            setState(() {
              showPopup = false;
            });
          },
        ),
      ],
    );
  }
}
