import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal,
      appBar: AppBar(
        backgroundColor: Colors.teal,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text("Help", style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: const [
            Text(
              "Need Help Using BloomMind?",
              style: TextStyle(
                color: Colors.teal,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 15),
            Text(
              "• For any technical issues, try restarting the app.\n\n"
              "• To change your profile, tap on the profile picture.\n\n"
              "• Mood Tracker can be used daily for better insights.\n\n"
              "• In Community Chat, always be respectful and avoid triggering content.\n\n"
              "• If you're facing emotional distress, please contact a mental health professional.",
              style: TextStyle(color: Colors.teal, fontSize: 14),
            ),
            SizedBox(height: 30),
            Text(
              "Contact Support",
              style: TextStyle(
                color: Colors.teal,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              "support@bloommind.app",
              style: TextStyle(color: Colors.teal, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
