import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgetPasswordPage extends StatefulWidget {
  const ForgetPasswordPage({Key? key}) : super(key: key);

  @override
  _ForgetPasswordPageState createState() => _ForgetPasswordPageState();
}

class _ForgetPasswordPageState extends State<ForgetPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = false;

  Future<void> _resetPassword() async {
    setState(() {
      _isLoading = true;
    });

    final email = _emailController.text.trim();

    try {
      await _auth.sendPasswordResetEmail(email: email);

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Email Sent'),
          content: const Text('Password reset instructions have been sent to your email.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } on FirebaseAuthException catch (e) {
      String message = 'An error occurred.';
      if (e.code == 'user-not-found') {
        message = 'No user found for that email.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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
        decoration: const BoxDecoration(
          color: Colors.white
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Reset Password',
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
                      fillColor: Color(0xffE7E7F2),
                      hintText: 'Enter your email',
                      prefixIcon: const Icon(Icons.email, color: Colors.teal),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _resetPassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 15),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Send Reset Email', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
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
