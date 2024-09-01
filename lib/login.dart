import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'signup.dart';
import 'forgot_password.dart';
import 'home.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _auth = FirebaseAuth.instance;

  // Login with email and password
  Future<void> _login() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showErrorSnackBar('Please enter both email and password.');
      return;
    }

    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;

      if (user != null && user.emailVerified) {
        // Fetch user data from Firestore
        DocumentSnapshot<Map<String, dynamic>> userData = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        String fullName = userData.data()?['fullName'] ?? 'No Name';
        int initialCoins = userData.data()?['coins'] ?? 0;  // Fetch the coins
        Timestamp? lastLoginTimestamp = userData.data()?['lastLoginDate'];
        int loginStreak = userData.data()?['loginStreak'] ?? 0;

        // Calculate streak and update daily rewards
        loginStreak = _handleDailyLogin(user.uid, lastLoginTimestamp, loginStreak);

        _navigateToHomePage(fullName, user.uid, initialCoins);  // Pass fullName, userId, and initialCoins
      } else {
        await _auth.signOut();
        _showErrorSnackBar('Email not verified. Please check your inbox and verify your email.');
      }
    } catch (e) {
      _showErrorSnackBar('Login failed: ${e.toString()}');
    }
  }

  // Handle Google Sign-In
  Future<void> _signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        UserCredential userCredential = await _auth.signInWithCredential(credential);

        final user = userCredential.user;
        if (user != null) {
          DocumentSnapshot<Map<String, dynamic>> userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

          if (!userDoc.exists) {
            // Initialize user data for new Google users
            final userData = {
              'email': user.email,
              'fullName': user.displayName,
              'createdAt': FieldValue.serverTimestamp(),
              'coins': 200,
              'purchasedAvatars': [],
              'avatar': null,
              'lastLoginDate': FieldValue.serverTimestamp(),
              'loginStreak': 0
            };
            await FirebaseFirestore.instance.collection('users').doc(user.uid).set(userData);
          }

          int initialCoins = userDoc.data()?['coins'] ?? 200;
          Timestamp? lastLoginTimestamp = userDoc.data()?['lastLoginDate'];
          int loginStreak = userDoc.data()?['loginStreak'] ?? 0;

          // Handle daily login rewards for Google users
          loginStreak = _handleDailyLogin(user.uid, lastLoginTimestamp, loginStreak);

          _navigateToHomePage(user.displayName ?? 'No Name', user.uid, initialCoins);
        }
      }
    } catch (e) {
      _showErrorSnackBar('Google Sign-In failed: ${e.toString()}');
    }
  }

  // Calculate and handle daily login
  int _handleDailyLogin(String userId, Timestamp? lastLoginTimestamp, int currentStreak) {
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);

    if (lastLoginTimestamp != null) {
      DateTime lastLoginDate = lastLoginTimestamp.toDate();
      DateTime lastLoginDay = DateTime(lastLoginDate.year, lastLoginDate.month, lastLoginDate.day);

      // If the last login was yesterday, continue the streak
      if (today.difference(lastLoginDay).inDays == 1) {
        currentStreak += 1;
      }
      // If the last login was today, do nothing
      else if (today.difference(lastLoginDay).inDays == 0) {
        return currentStreak;
      }
      // If the last login was more than a day ago, reset the streak
      else {
        currentStreak = 1;
      }
    } else {
      // If no previous login date, start the streak
      currentStreak = 1;
    }

    // Update Firestore with new login date and streak
    FirebaseFirestore.instance.collection('users').doc(userId).update({
      'lastLoginDate': now,
      'loginStreak': currentStreak,
    });

    // You can also reward the user here, for example:
    // FirebaseFirestore.instance.collection('users').doc(userId).update({
    //   'coins': FieldValue.increment(10),  // Reward with coins
    // });

    return currentStreak;
  }

  // Navigate to home page with fullName, userId, and initialCoins
  void _navigateToHomePage(String fullName, String userId, int initialCoins) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => HomePage(fullName: fullName, userId: userId, initialCoins: initialCoins),  // Pass fullName, userId, and initialCoins
      ),
    );
  }

  // Display error snack bar
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login Page'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('android/assets/images/login.png', height: 200, width: 350),
            const SizedBox(height: 20),
            const Text('Welcome to the Login Page!', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            _buildTextField(controller: _emailController, labelText: 'Email'),
            const SizedBox(height: 16),
            _buildTextField(controller: _passwordController, labelText: 'Password', obscureText: true),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _login,
              child: const Text('Login'),
            ),
            _buildTextButton(
              text: "Don't have an account? Sign up",
              onPressed: () => _navigateTo(const SignUpPage()),
            ),
            _buildTextButton(
              text: 'Forgot Password?',
              onPressed: () => _navigateTo(const ForgotPasswordPage()),
              color: Colors.blue,
            ),
            const SizedBox(height: 20),
            const Text('Or sign in with:', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _signInWithGoogle,
              child: Image.asset('android/assets/images/google_icon.png', height: 50, width: 50),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateTo(Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    bool obscureText = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: labelText,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _buildTextButton({
    required String text,
    required VoidCallback onPressed,
    Color color = Colors.black,
  }) {
    return TextButton(
      onPressed: onPressed,
      child: Text(text, style: TextStyle(color: color)),
    );
  }
}
