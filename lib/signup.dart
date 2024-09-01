import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'home.dart';
import 'login.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Method to handle sign up and send verification email
  Future<void> _signUp() async {
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      User? user = userCredential.user;

      if (user != null) {
        String fullName = _nameController.text;

        // Write user data to Firestore
        try {
          await _firestore.collection('users').doc(user.uid).set({
            'avatar': null,
            'badge': "",
            'coins': 200, // Set initial coins to 200
            'createdAt': DateTime.now(),
            'email': user.email,
            'fullName': fullName,
            'lastClaimed': "",
            'lastLoginDate': FieldValue
                .serverTimestamp(), // Initialize with Firestore server timestamp
            'level': 1,
            'loginStreak': 0, // Initialize streak at 0
            'purchasedAvatars': [],
            'selectedTheme': "",
            'xp': 0
            // Daily login tracking fields
          });
          print('User data saved successfully.');
        } catch (e) {
          print('Failed to save user data: $e');
        }

        // Send email verification
        if (!user.emailVerified) {
          await user.sendEmailVerification();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Verification email sent. Please check your inbox.'),
            ),
          );

          // Navigate to LoginPage after verification email is sent
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const LoginPage(), // Navigate to LoginPage
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign-up failed: $e')),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Up Page'),
        backgroundColor: Colors.teal,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'android/assets/images/sign-up.png',
                  height: 200,
                  width: 350,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Create a new account',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                _buildTextField(_nameController, 'Full Name'),
                _buildTextField(_emailController, 'Email'),
                _buildTextField(_passwordController, 'Password',
                    obscureText: true),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _signUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                  ),
                  child: const Text('Sign Up'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String labelText,
      {bool obscureText = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: labelText,
          border: OutlineInputBorder(),
        ),
      ),
    );
  }
}
