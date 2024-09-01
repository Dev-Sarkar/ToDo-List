import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login.dart';
import 'home.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Initialize Firebase
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vagabond To-do List',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const AuthCheck(), // Show AuthCheck to decide initial screen
    );
  }
}

class AuthCheck extends StatelessWidget {
  const AuthCheck({super.key});

  Future<Map<String, dynamic>> _getUserData(User user) async {
    try {
      // Fetch user data from Firestore
      DocumentSnapshot<Map<String, dynamic>> userData = await FirebaseFirestore
          .instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userData.exists) {
        return userData.data() ?? {};
      } else {
        print("No user data found for ${user.uid}.");
        return {};
      }
    } catch (e) {
      print("Error fetching user data: $e");
      return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      return FutureBuilder<Map<String, dynamic>>(
        future: _getUserData(
            user), // Fetch the user data including fullName and initialCoins
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child:
                    CircularProgressIndicator()); // Show loading while fetching user data
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Error loading user data.'));
          }

          if (snapshot.hasData) {
            String fullName = snapshot.data?['fullName'] ??
                'No Name'; // Get the fullName from Firestore
            int initialCoins = snapshot.data?['coins'] ??
                0; // Get the coins from Firestore (default to 0)
            return HomePage(
                fullName: fullName,
                userId: user.uid,
                initialCoins:
                    initialCoins); // Pass fullName, userId, and initialCoins to HomePage
          }

          return const Center(child: Text('No user data found.'));
        },
      );
    } else {
      return const LoginPage();
    }
  }
}
