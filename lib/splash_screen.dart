import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bloommind/survey_screen.dart';
import 'package:bloommind/main_screen.dart';
import 'login_page.dart'; 

Future<bool> shouldShowSurvey() async {
  final uid = FirebaseAuth.instance.currentUser?.uid;

  if (uid == null) return true; // no user? show survey

  final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();

  if (!doc.exists || !doc.data()!.containsKey('lastsurveyDate')) {
    return true; // new user or missing survey date
  }

  final lastSurveyDate = (doc['lastsurveyDate'] as Timestamp).toDate();
  final now = DateTime.now();

  return now.difference(lastSurveyDate).inDays >= 7;
} // Importing LoginPage for navigation

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
void initState() {
  super.initState();
  checkSurveyAndNavigate();
}

void checkSurveyAndNavigate() async {
  final showSurvey = await shouldShowSurvey();

  if (showSurvey) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => SurveyScreen()),
    );
  } else {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => MainScreen()), // your app's main screen
    );
  }
}

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.teal
 
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text(
                  'BloomMind',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Nurturing Mental Wellness',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
