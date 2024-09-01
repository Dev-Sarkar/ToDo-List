import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'level_notifier.dart';
import'fireworks.dart';
class LevelPurchase extends StatefulWidget {
  final String userId;
  final int initialCoins;

  const LevelPurchase({super.key, required this.userId, required this.initialCoins});

  @override
  _LevelPurchaseState createState() => _LevelPurchaseState();
}

class _LevelPurchaseState extends State<LevelPurchase> {
  int currentCoins = 0;
  int currentLevel = 0;
  bool showFireworks = false;
  String fireworksPath = 'android/assets/firework.json';

  // Define paths for milestones
  final Map<int, String> milestoneFireworks = {
    10: 'android/assets/fireworks1.json',
    20: 'android/assets/fireworks2.json',
  };
  @override
  void initState() {
    super.initState();
    currentCoins = widget.initialCoins;
    _loadLevelData();
  }

  Future<void> _loadLevelData() async {
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(
          widget.userId).get();
      if (userDoc.exists) {
        setState(() {
          currentCoins = userDoc.data()?['coins'] ?? 0;
          currentLevel = userDoc.data()?['level'] ?? 0;
        });
        levelNotifier.value = currentLevel;
      } else {
        await FirebaseFirestore.instance.collection('users')
            .doc(widget.userId)
            .set({
          'coins': currentCoins,
          'level': 0,
        });
      }
    } catch (e) {
      print('Failed to load level data: $e');
    }
  }

  int _getLevelCost(int level) {
    switch (level) {
      case 0:
        return 100;
      case 1:
        return 200;
      case 2:
        return 500;
      default:
        return 1000;
    }
  }

  Future<void> _purchaseLevel() async {
    final levelCost = _getLevelCost(currentLevel);
    if (currentCoins >= levelCost) {
      setState(() {
        currentCoins -= levelCost;
        currentLevel += 1;
      });
      levelNotifier.value = currentLevel;

      await FirebaseFirestore.instance.collection('users')
          .doc(widget.userId)
          .update({
        'coins': currentCoins,
        'level': currentLevel,
      });

      _checkForMilestone(currentLevel);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Level increased to $currentLevel!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Not enough coins to buy the next level.')),
      );
    }
  }

  void _checkForMilestone(int level) {
    const milestoneLevels = [10, 20, 40, 60, 80, 100];

    if (milestoneLevels.contains(level)) {
      final badge = _getBadgeForLevel(level);


      setState(() {
        fireworksPath = milestoneFireworks[level] ?? 'android/assets/firework.json';
        showFireworks = true;
      });


      _showCongratulationsPopup(level, badge);


      Future.delayed(Duration(seconds: 15), () {
        if (mounted) {
          setState(() {
            showFireworks = false;
          });
        }
      });
    }
  }

  String _getBadgeForLevel(int level) {
    if (level >= 100) return 'Ethereum';
    if (level >= 80) return 'Diamond';
    if (level >= 60) return 'Platinum';
    if (level >= 40) return 'Gold';
    if (level >= 20) return 'Silver';
    if (level >= 10) return 'Bronze';
    return '';
  }

  void _showCongratulationsPopup(int level, String badge) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Congratulations!"),
            content: Text(
                "You've reached Level $level and earned the $badge badge!"),
            actions: [
              TextButton(
                child: const Text("Awesome!"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main homepage UI
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Current Level: $currentLevel',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text('Coins: $currentCoins', style: TextStyle(fontSize: 16)),
            ElevatedButton(
              onPressed: _purchaseLevel,
              child: Text('Upgrade Level (Cost: ${_getLevelCost(currentLevel)})'),
            ),
          ],
        ),

        // Fireworks animation overlay
        if (showFireworks)
          FireworksAnimation(
            showFireworks: showFireworks,
            animationPath: fireworksPath,
          ),
      ],
    );
  }
}