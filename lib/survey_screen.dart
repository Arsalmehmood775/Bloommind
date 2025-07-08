import 'package:bloommind/services/survey_service.dart';
import 'package:bloommind/therapist_selection_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'survey_question_widget.dart';
import 'survey_result.dart';
import 'therapist_profile.dart';


class SurveyScreen extends StatefulWidget {
  const SurveyScreen({super.key});

  @override
  State<SurveyScreen> createState() => _SurveyScreenState();
}

class _SurveyScreenState extends State<SurveyScreen> {
  final List<String> questions = [
    // Emotional & Mood
    "I feel overwhelmed by small tasks or daily routines.",
    "I struggle to find motivation for things I used to enjoy.",
    "I feel anxious or worried without a clear reason.",
    "My mood changes quickly without warning.",
    "I feel hopeless about the future.",
    // Thought Patterns
    "I find it hard to focus or concentrate on tasks.",
    "My thoughts are racing, and I can’t slow them down.",
    "I often question my self-worth or feel like a failure.",
    "I overthink simple things more than usual.",
    "I feel emotionally numb or disconnected from my surroundings.",
      // Behavior
      "I avoid social interactions or prefer staying alone.",
      "I feel unusually tired, even after resting.",
      "I find it hard to start or complete tasks.",
      "I feel restless or agitated without a reason.",
      "I get irritated or angry more easily than before.",
      // Sleep & Health
      "I have trouble falling or staying asleep.",
      "I wake up feeling unrefreshed or exhausted.",
      "I experience unexplained physical aches or pains.",
      "My appetite has changed (eating too much or too little).",
      "I feel like I’m just “surviving,” not really living.",
  ];

  List<int> responses = List.generate(20, (_) => -1);
  int currentQuestion = 0;
  bool wantsSpecialist = false;

  void nextQuestion() {
    if (currentQuestion < questions.length - 1) {
      setState(() {
        currentQuestion++;
      });
    } else {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: Colors.white,
          title: Text("One last question", style: GoogleFonts.poppins(color: Colors.black), ),
          content: Text("Would you like to speak to a specialist if needed?",
              style: GoogleFonts.poppins(color: Colors.black)),
          actions: [
            TextButton(
              onPressed: () {
                wantsSpecialist = false;
                Navigator.pop(context);
                finishSurvey(); // go directly
              },
              child: Text("No", style: GoogleFonts.poppins(color: Colors.black)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () async {
                wantsSpecialist = true;

                Navigator.pop(context); // Close the dialog first

                // Wait a short delay before pushing to allow dialog to fully close
                await Future.delayed(const Duration(milliseconds: 300));

                // Navigate to therapist profile screen
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TherapistSelectionScreen(), // new screen below
                  ),
                );

                // After they return from therapist screen, submit survey
                finishSurvey();
              },

              child: Text("Yes", style: GoogleFonts.poppins(color: Colors.white)),
            ),
          ],
        ),
      );

    }
  }

  String getStressLevel() {
    int totalScore = responses.fold(0, (sum, value) => sum + (value >= 0 ? value : 0));
    if (totalScore <= 20) return "Mild";
    if (totalScore <= 40) return "Moderate";
    return "Severe";
  }



  void finishSurvey() async {
    int totalScore = responses.fold(0, (sum, value) => sum + (value >= 0 ? value : 0));

    String stressLevel;
    if (totalScore <= 20) {
      stressLevel = "Mild";
    } else if (totalScore <= 40) {
      stressLevel = "Moderate";
    } else {
      stressLevel = "Severe";
    }

    // Save to Firestore
    await saveSurveyResult(
      score: totalScore,
      stressLevel: stressLevel,
      wantsSpecialist: wantsSpecialist,
    );

    // Navigate to result screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SurveyResult(score: totalScore, wantsSpecialist: wantsSpecialist),
      ),
    );
  }




  void onOptionSelected(int value) {
    setState(() {
      responses[currentQuestion] = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isLast = currentQuestion == questions.length - 1;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  "Mental Health Survey",
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              LinearProgressIndicator(
                value: (currentQuestion + 1) / questions.length,
                backgroundColor: Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.teal),
                minHeight: 8,
              ),
              const SizedBox(height: 20),
              Text(
                "Question ${currentQuestion + 1}/${questions.length}",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 30),
              Expanded(
                child: SingleChildScrollView(
                  child: SurveyQuestionWidget(
                    question: questions[currentQuestion],
                    selectedOption: responses[currentQuestion],
                    onOptionSelected: onOptionSelected,
                    isLast: isLast,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: responses[currentQuestion] != -1 ? nextQuestion : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    isLast ? "Submit Survey" : "Next Question",
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