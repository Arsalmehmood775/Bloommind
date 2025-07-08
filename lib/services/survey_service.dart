import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> saveSurveyResult({
  required int score,
  required String stressLevel,
  required bool wantsSpecialist,
}) async {
  final user = FirebaseAuth.instance.currentUser;

  if (user != null) {
    final resultData = {
      'score': score,
      'stress_level': stressLevel,
      'wants_specialist': wantsSpecialist,
      'timestamp': FieldValue.serverTimestamp(),
    };

    // ✅ Save to subcollection
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('survey_results')
        .add(resultData);

    // ✅ Also update the main user document with correct stress level
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .update({
      'latestStressLevel': stressLevel, // Must be 'Mild', 'Moderate', or 'Severe'
      'wantsSpecialist': wantsSpecialist,
    });
  }
}
