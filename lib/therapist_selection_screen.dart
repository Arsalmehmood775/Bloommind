import 'package:bloommind/therapist_profile.dart';
import 'package:bloommind/survey_result.dart'; // Import the survey result screen
import 'package:flutter/material.dart';

class TherapistSelectionScreen extends StatelessWidget {
  final List<Map<String, String>> therapists = [
    {
      'name': 'Dr. Sarah Khan',
      'specialization': 'Clinical Psychologist',
      'email': 'sarah.khan@bloommind.app',
      'phone': '+92 300 1234567',
      'id': 'T001'
    },
    {
      'name': 'Dr. Ali Raza',
      'specialization': 'Cognitive Behavioral Therapist',
      'email': 'ali.raza@bloommind.app',
      'phone': '+92 345 6543210',
      'id': 'T002'
    },
    {
      'name': 'Dr. Ayesha Malik',
      'specialization': 'Child Psychologist',
      'email': 'ayesha.malik@bloommind.app',
      'phone': '+92 312 9988776',
      'id': 'T003'
    },
  ];

  final int score;
  final bool wantsSpecialist;

  TherapistSelectionScreen({
    Key? key,
    this.score = 0,
    this.wantsSpecialist = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.4),
      body: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 80),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Colors.black45,
                offset: Offset(0, 10),
                blurRadius: 25,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Available Therapists",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.teal),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 240,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: therapists.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 16),
                  itemBuilder: (context, index) {
                    final therapist = therapists[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TherapistProfileScreen(therapist: therapist),
                          ),
                        );
                      },
                      child: Container(
                        width: 220,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.teal,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black38,
                              offset: Offset(0, 6),
                              blurRadius: 10,
                            )
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.person, size: 50, color: Colors.white70),
                            const SizedBox(height: 10),
                            _infoText("Name", therapist['name']!),
                            _infoText("Specialization", therapist['specialization']!),
                            _infoText("Email", therapist['email']!),
                            _infoText("Phone", therapist['phone']!),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              // 🔘 New Finish Survey Button
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SurveyResult(score: score, wantsSpecialist: wantsSpecialist),
                    ),
                  );
                },
                child: const Text("Finish Survey"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // 🔘 Original Close Button (no changes)
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Close", style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoText(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        "$title: $value",
        style: const TextStyle(color: Colors.white, fontSize: 14),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}