import 'package:bloommind/survey_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'sign_up_page.dart';
import 'forget_password_page.dart';
import 'main_screen.dart';
import 'package:google_fonts/google_fonts.dart'; // MainScreen

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);
  @override
  State<LoginPage> createState() => _LoginPageState();
}
class _LoginPageState extends State<LoginPage> {
  bool _obscurePassword = true;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  void _login() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) {
      _showErrorDialog('Please enter both email and password.');
      return;
    }
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null && !user.emailVerified) {
        await FirebaseAuth.instance.signOut();
        // Show alert/snackbar:
        // "Please verify your email before logging in."
        return; // prevent navigation to home
      }
      if (user != null) {
        // 🔥 Read Firestore user data after login
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (userDoc.exists) {
          // Optionally read fields
          final fullName = userDoc['fullName'] ?? 'No Name';
          final stressLevel = userDoc['stressLevel'] ?? 'Unknown';
          final community = userDoc['community'] ?? 'None';
          print('User Firestore Data:');
          print('Full Name: $fullName');
          print('Stress Level: $stressLevel');
          print('Community: $community');
        } else {
          print('No Firestore data found for this user.');
        }
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 16,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.teal,
                  shape: BoxShape.rectangle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white, size: 60),
                    const SizedBox(height: 20),
                    const Text(
                      'Success!',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'You have successfully logged in.',
                      style: TextStyle(fontSize: 16, color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>  SurveyScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 50, vertical: 15),
                      ),
                      child: const Text('OK', style: TextStyle(fontSize: 18,color: Colors.teal)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }
    } on FirebaseAuthException catch (e) {
      _showErrorDialog(e.message ?? 'Login failed. Please try again.');
    } catch (e) {
      _showErrorDialog('An unexpected error occurred: $e');
    }
  }
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Login Error"),
        content: Text(message),
        actions: [
          TextButton(
            child: const Text("OK"),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.teal,
        elevation: 20,
        centerTitle: true,
        title: const Text("BloomMind",
        style :TextStyle(color: Colors.white,fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.teal),
        
      ),
      body: Container(
        decoration: const BoxDecoration(color: Colors.white),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Welcome Back!',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xffE7E7F2),
                      hintText: 'Email',
                      prefixIcon: const Icon(Icons.alternate_email_outlined, color: Colors.teal),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xffE7E7F2),
                      hintText: 'Password',
                      prefixIcon: const Icon(Icons.lock, color: Colors.teal),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: Colors.teal,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 100, vertical: 15),
                    ),
                    child: const Text(
                      'Login',
                      style: TextStyle(fontSize: 18 , color: Colors.white , fontWeight: FontWeight.bold )
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ForgetPasswordPage()),
                      );
                    },
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Don't have an account? ",
                        style: TextStyle(color: Colors.black),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const SignUpPage()),
                          );
                        },
                        child: const Text(
                          'Sign Up',
                          style: TextStyle(
                            color: Colors.teal,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}