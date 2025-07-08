import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class SurveyHistoryScreen extends StatelessWidget {
  const SurveyHistoryScreen({super.key});

  Future<List<Map<String, dynamic>>> fetchSurveyHistory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final snapshot = await FirebaseFirestore.instance
        .collection('survey_results')
        .where('userId', isEqualTo: user.uid)
        .orderBy('timestamp', descending: true)
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Survey History", style: GoogleFonts.poppins()),
        backgroundColor: Colors.black,
      ),
      body: FutureBuilder(
        future: fetchSurveyHistory(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || (snapshot.data as List).isEmpty) {
            return Center(
              child: Text("No survey history found.", style: GoogleFonts.poppins()),
            );
          }

          final history = snapshot.data as List<Map<String, dynamic>>;

          return ListView.builder(
            itemCount: history.length,
            itemBuilder: (context, index) {
              final entry = history[index];
              final timestamp = (entry['timestamp'] as Timestamp).toDate();
              return Card(
                margin: const EdgeInsets.all(10),
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  title: Text("Score: ${entry['score']} | Level: ${entry['stressLevel']}",
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    "Date: ${timestamp.toLocal()} \nSpecialist: ${entry['wantsSpecialist'] ? "Yes" : "No"}",
                    style: GoogleFonts.poppins(fontSize: 14),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
