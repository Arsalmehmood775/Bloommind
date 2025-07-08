import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main_screen.dart';

class SurveyResult extends StatefulWidget {
  final int score;
  final bool wantsSpecialist;

  const SurveyResult({
    super.key,
    required this.score,
    required this.wantsSpecialist,
  });

  @override
  State<SurveyResult> createState() => _SurveyResultState();
}

class _SurveyResultState extends State<SurveyResult> {
  String getResultLevel(int score) {
    if (score <= 20) return "Mild";
    if (score <= 40) return "Moderate";
    return "Severe";
  }

  @override
  void initState() {
    super.initState();
    _saveSurveyData();
  }

  Future<void> _saveSurveyData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final stressLevel = getResultLevel(widget.score);

    // ✅ Step 1: Save to surveyResults collection
    await FirebaseFirestore.instance.collection('surveyResults').add({
      'userId': user.uid,
      'score': widget.score,
      'stressLevel': stressLevel,
      'wantsSpecialist': widget.wantsSpecialist,
      'timestamp': Timestamp.now(),
    });

    // ✅ Step 2: Update the user's document in users collection
    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'latestStressLevel': stressLevel,
      'wantsSpecialist': widget.wantsSpecialist,
      'lastUpdated': Timestamp.now(),


    });
  }

  @override
  Widget build(BuildContext context) {
    final resultLevel = getResultLevel(widget.score);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "Survey Results",
                style: GoogleFonts.poppins(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
              ),
              const SizedBox(height: 70),
              Container(
                height: 300,
                child: Card(
                  color: Colors.teal,
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Text(
                          "Your Score: ${widget.score}",
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 30),
                        Text(
                          "Level: $resultLevel",
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 70),
                        Text(
                          widget.wantsSpecialist
                              ? "You requested to speak with a specialist."
                              : "You can reach out to a specialist anytime.",
                          style: GoogleFonts.poppins(fontSize: 16,color: Colors.white),
                          
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => MainScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    "Next",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
