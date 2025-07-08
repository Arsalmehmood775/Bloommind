import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_page.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({Key? key}) : super(key: key);

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;

  Future<void> _signUp(BuildContext context) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final name = _nameController.text.trim();
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      // Create user in Firebase Auth
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = userCredential.user;
      if (user != null && !user.emailVerified){
        await user.sendEmailVerification();
        // Show a snackbar or dialog:
        //"A verification email has been sent to your email. Please verify before logging in."
      }

      // Save user data to Firestore (with stressLevel & community)
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'fullName': name,
        'email': email,
        'createdAt': Timestamp.now(),
        'stressLevel': 'Unassigned',
        'community': 'Unassigned',
      });

      // Show success dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Success'),
            content: const Text('Account created successfully.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  );
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    } on FirebaseAuthException catch (e) {
      String message = 'An error occurred.';
      if (e.code == 'email-already-in-use') {
        message = 'Email is already in use.';
      } else if (e.code == 'weak-password') {
        message = 'Password should be at least 6 characters.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Something went wrong.')),
      );
    }

    setState(() {
      _isLoading = false;
    });
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
          color: Colors.white,

        ),

        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Create Account',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(_nameController, 'Full Name', Icons.person ),
                  const SizedBox(height: 20),
                  _buildTextField(_emailController, 'Email', Icons.email ),
                  const SizedBox(height: 20),
                  _buildTextField(_passwordController, 'Password', Icons.lock, obscureText: true),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _isLoading ? null : () => _signUp(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 100, vertical: 15),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Sign Up', style: TextStyle(fontSize: 18,color: Colors.white, fontWeight: FontWeight.bold), ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Already have an account? ", style: TextStyle(color: Colors.red , fontFamily: 'Roboto')),
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginPage()),
                          );
                        },
                        child: const Text(
                          'Login',
                          style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold),
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

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {bool obscureText = false}) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        filled: true,
        fillColor: Color(0xffE7E7F2),
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.teal),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
