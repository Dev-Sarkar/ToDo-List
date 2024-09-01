import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:todolist/pong.dart';
import 'package:todolist/screens/habit_tracker_page.dart';
import 'login.dart';
import 'reward.dart';
import 'theme_page.dart';
import 'level.dart';
import 'level_notifier.dart';
import 'models/profile.dart';

//todo import the necessary files
import 'ui/task_screen.dart';
import 'flappy.dart';
import 'leaderBoard.dart';

int? lastKnownLevel;

class HomePage extends StatefulWidget {
  final String fullName;
  final String userId;
  final int initialCoins;

  const HomePage({
    super.key,
    required this.fullName,
    required this.userId,
    required this.initialCoins,
  });

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  //todo tabcontroller
  late Profile profile;
  late TabController _tabController;
  String? selectedAvatar;
  List<String> purchasedAvatars = [];
  int currentCoins = 0;
  int currentLevel = 0;
  int currentXP = 0;
  int xpForNextLevel = 100;
  late String fullName;
  String? selectedTheme;

  @override
  void initState() {
    super.initState();
    fullName = widget.fullName; // Initialize fullName from widget
    currentCoins = widget.initialCoins; // Set initial coins when the page loads
    _loadUserData();
    _tabController = TabController(length: 3, vsync: this);
    profile = Profile(id: widget.userId, name: widget.fullName);
  }

  //todo disposing widget
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (!userDoc.exists) {
        // If user is new, set initial coins to 200
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .set({
          'coins': 200,
          'level': 0,
          'xp': 0,
          'purchasedAvatars': [],
          'avatar': null,
          'fullName': widget.fullName,
          'selectedTheme': null, // Initialize selectedTheme
        });

        // After writing to Firestore, update the state
        setState(() {
          currentCoins = 200;
          currentLevel = 0;
          currentXP = 0;
          purchasedAvatars = [];
          selectedTheme = null; // Initialize selectedTheme state
          profile = Profile(id: widget.userId, name: fullName);
        });
        levelNotifier.value = 0;
      } else {
        // If user exists, load data
        int newLevel = userDoc.data()?['level'] ?? 0;
        setState(() {
          currentCoins =
              userDoc.data()?['coins'] ?? 0; // Load coins from Firestore
          currentLevel = newLevel;
          currentXP = userDoc.data()?['xp'] ?? 0;
          purchasedAvatars =
              List<String>.from(userDoc.data()?['purchasedAvatars'] ?? []);
          selectedAvatar = userDoc.data()?['avatar'];
          fullName = userDoc.data()?['fullName'] ?? fullName;
          selectedTheme = userDoc
              .data()?['selectedTheme']; // Load selectedTheme from Firestore
        });
        levelNotifier.value = newLevel;
        if (lastKnownLevel != null && newLevel > lastKnownLevel!) {
          _checkForMilestone(newLevel);
        }

        lastKnownLevel = newLevel; // Update last known level
      }
    } catch (e) {
      print('Failed to load user data: $e');
    }
  }

  void _onDailyCheckIn() async {
    int xpGain = 20; // XP gained on daily check-in
    setState(() {
      currentXP += xpGain;
      if (currentXP >= xpForNextLevel) {
        currentLevel++;
        currentXP = currentXP - xpForNextLevel;
        xpForNextLevel += 50; // Increase XP needed for the next level
      }
    });

    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .update({
      'level': currentLevel,
      'xp': currentXP,
    });
  }

  // Function to check for milestone levels
  void _checkForMilestone(int level) {
    List<int> milestones = [10, 20, 40, 60, 80, 100]; // Define milestone levels
    if (milestones.contains(level)) {
      _showCongratulatoryPopup(level);
    }
  }

// Function to get the badge name based on level
  String _getBadgeName(int level) {
    if (level >= 100) {
      return "Ethereum";
    } else if (level >= 80) {
      return "Diamond";
    } else if (level >= 60) {
      return "Platinum";
    } else if (level >= 40) {
      return "Gold";
    } else if (level >= 20) {
      return "Silver";
    } else if (level >= 10) {
      return "Bronze";
    }
    return "";
  }

// Show congratulatory popup function
  void _showCongratulatoryPopup(int level) {
    String badge = _getBadgeName(level);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Congratulations!'),
        content:
            Text("You've reached Level $level and earned the $badge badge!"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveUserAvatar(String avatarPath) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({'avatar': avatarPath});
      setState(() {
        selectedAvatar = avatarPath;
      });
    } catch (e) {
      print('Failed to save avatar: $e');
    }
  }

  void _selectAvatar(String newAvatar) {
    _saveUserAvatar(newAvatar);
  }

  //todo navigate to leaderboard
  void _leaderBoard(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LeaderBoardPage()),
    );
  }

  Future<void> _logout(BuildContext context) async {
    try {
      await GoogleSignIn().signOut();
      await FirebaseAuth.instance.signOut();

      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const LoginPage()));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Logout failed: $e')));
    }
  }

  Future<void> _changeName(BuildContext context) async {
    TextEditingController nameController =
        TextEditingController(text: fullName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Name'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Enter new name'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              setState(() {
                fullName = nameController.text; // Update local fullName state
              });

              // Update Firestore with new name
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(widget.userId)
                  .update({'fullName': fullName});

              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showAvatarSelection(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Avatar'),
        content: SizedBox(
          height: 200,
          width: 300,
          child: GridView.count(
            crossAxisCount: 3,
            crossAxisSpacing: 10.0,
            mainAxisSpacing: 10.0,
            children: [
              _buildAvatarOption('android/assets/images/male1.png'),
              _buildAvatarOption('android/assets/images/male2.png'),
              _buildAvatarOption('android/assets/images/female.jpg'),
              ...purchasedAvatars.map((avatar) => _buildAvatarOption(avatar)),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _buildAvatarOption(String avatarPath) {
    return GestureDetector(
      onTap: () {
        _selectAvatar(avatarPath);
        Navigator.pop(context);
      },
      child: CircleAvatar(radius: 30, backgroundImage: AssetImage(avatarPath)),
    );
  }

  void _openAvatarStore(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Container(
          height: 400,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Text('Store',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text('You have $currentCoins coins.'),
              // Display user's current coins
              const SizedBox(height: 10),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: 4,
                  itemBuilder: (context, index) {
                    final avatars = [
                      'android/assets/images/amusing.png',
                      'android/assets/images/avatar.png',
                      'android/assets/images/woman.jpg',
                      'android/assets/images/spider.jpg',
                    ];
                    return _buildStoreAvatarOption(avatars[index]);
                  },
                ),
              ),
              LevelPurchase(
                userId: widget.userId,
                initialCoins: currentCoins,
              ),
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStoreAvatarOption(String avatarPath) {
    bool isPurchased = purchasedAvatars.contains(avatarPath);
    return GestureDetector(
      onTap: () {
        if (!isPurchased) {
          if (currentCoins >= 50) {
            // Check if user has enough coins
            _purchaseAvatar(avatarPath);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Not enough coins')));
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('You already own this avatar')));
        }
      },
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          CircleAvatar(radius: 30, backgroundImage: AssetImage(avatarPath)),
          if (!isPurchased)
            Container(
              color: Colors.black54,
              padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
              child: const Text('Buy for 50',
                  style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
    );
  }

  Future<void> _purchaseAvatar(String avatarPath) async {
    if (currentCoins >= 50) {
      try {
        purchasedAvatars.add(avatarPath);
        setState(() {
          currentCoins -= 50; // Deduct 50 coins for the purchase
        });
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .update({
          'purchasedAvatars': purchasedAvatars,
          'coins': currentCoins, // Update Firestore with new coin balance
        });

        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Avatar purchased successfully!')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to purchase avatar: $e')));
      }
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Not enough coins')));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine the background image based on selected theme
    final String backgroundImage;
    if (selectedTheme == 'Black & White') {
      backgroundImage = 'android/assets/images/white.jpg';
    } else if (selectedTheme == 'Neon') {
      backgroundImage = 'android/assets/images/The last.jpg';
    } else if (selectedTheme == 'Gold') {
      backgroundImage = 'android/assets/images/abstract.png';
    } else if (selectedTheme == 'Boho') {
      backgroundImage = 'android/assets/images/boho.jpg';
    } else if (selectedTheme == 'Glitter') {
      backgroundImage = 'android/assets/images/Cowboy.jpg';
    } else if (selectedTheme == 'Soft') {
      backgroundImage = 'android/assets/images/soft1.jpg';
    } else if (selectedTheme == 'Neutral') {
      backgroundImage = 'android/assets/images/nuetral.jpg';
    } else {
      backgroundImage = 'android/assets/images/pintrest.png'; // Fallback image
    }

    // Determine the app bar color based on selected theme
    final Color appBarColor;
    if (selectedTheme == 'Black & White') {
      appBarColor = Colors.black;
    } else if (selectedTheme == 'Neon') {
      appBarColor = Colors.purpleAccent;
    } else if (selectedTheme == 'Neutral') {
      appBarColor = Colors.brown;
    } else if (selectedTheme == 'Glitter') {
      appBarColor = Colors.redAccent;
    } else if (selectedTheme == 'Gold') {
      appBarColor = Colors.orange;
    } else if (selectedTheme == 'Soft') {
      appBarColor = Colors.grey;
    } else if (selectedTheme == 'Pastel') {
      appBarColor = Colors.lightGreenAccent;
    } else if (selectedTheme == 'Cute') {
      appBarColor = Colors.deepOrange;
    } else if (selectedTheme == 'Pink') {
      appBarColor = Colors.pink;
    } else {
      appBarColor = Colors.blueAccent; // Default app bar color
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: appBarColor,
        title: Row(
          children: [
            GestureDetector(
              onTap: () => _showAvatarSelection(context),
              child: CircleAvatar(
                radius: 20,
                backgroundImage: selectedAvatar != null
                    ? AssetImage(selectedAvatar!)
                    : const AssetImage(
                        'android/assets/images/avatar_placeholder.png'),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () => _changeName(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fullName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Text(
                    'Welcome To Vagabond To-Do List!',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      //todo new update level code
                      StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(widget
                                .userId) // Reference the specific document
                            .snapshots(), // Use snapshots to listen for updates
                        builder: (context, snapshot) {
                          int level = snapshot.data?.get('level') ?? 1;
                          return Text(
                            'Level: $level',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 4),
                      if (currentLevel >= 10)
                        Padding(
                          padding: const EdgeInsets.only(top: 2.0),
                          child: _getBadgeIcon(currentLevel),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.palette),
            onPressed: () async {
              final selectedTheme = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ThemePage(userId: widget.userId),
                ),
              );
              if (selectedTheme != null) {
                setState(() {
                  this.selectedTheme = selectedTheme;
                });
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.store),
            onPressed: () => _openAvatarStore(context),
          ),
          PopupMenuButton<String>(
            //onSelected: (value) => value == 'Logout' ? _logout(context) : null,
            onSelected: (value) {
              if (value == 'Logout') {
                _logout(context); // Call the logout method
              } else if (value == 'Leaderboard') {
                _leaderBoard(context); // Navigate to settings
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                  value: 'Leaderboard', child: Text('Leaderboard')),
              const PopupMenuItem(value: 'Logout', child: Text('Logout')),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.checklist), text: "Tasks"),
            Tab(icon: Icon(Icons.calendar_month), text: "Habits"),
            Tab(icon: Icon(Icons.videogame_asset), text: "Games"),
          ],
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              backgroundImage,
              fit: BoxFit.cover, // Ensures full coverage
            ),
          ),
          TabBarView(
            controller: _tabController,
            children: [
              Center(child: TaskScreen(profile: profile, theme: selectedTheme)),
              Center(
                  child: HabitTrackerPage(
                      userId: widget.userId, theme: selectedTheme)),
              Center(child: Flappy(userId: widget.userId)),
              // todo fix pong collision
              //Center(child: PongGame()),
            ],
          ),
          DailyRewardPopup(
            userId: widget.userId,
            onRewardClaimed: () => _loadUserData(),
          ),
        ],
      ),
    );
  }
}

Widget _getBadgeIcon(int level) {
  String badgeAsset;

  if (level >= 100) {
    badgeAsset = 'android/assets/images/etherium.png';
  } else if (level >= 80) {
    badgeAsset = 'android/assets/images/dimond.png';
  } else if (level >= 60) {
    badgeAsset = 'android/assets/images/platinum.png';
  } else if (level >= 40) {
    badgeAsset = 'android/assets/images/gold.png';
  } else if (level >= 20) {
    badgeAsset = 'android/assets/images/silver.png';
  } else if (level >= 10) {
    badgeAsset = 'android/assets/images/bronze.png';
  } else {
    return SizedBox.shrink(); // No badge if below level 10
  }

  return Image.asset(
    badgeAsset,
    width: 20,
    height: 20,
  );
}
