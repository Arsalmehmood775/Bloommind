// TODO Implement this library.
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> createUserProfile({
    required String userId,
    required String name,
    required String email,
    String profilePic = '',
    String stressLevel = 'low',
    String communityLevel = 'low',
  }) async {
    await _db.collection('users').doc(userId).set({
      'name': name,
      'email': email,
      'profilePic': profilePic,
      'stressLevel': stressLevel,
      'communityLevel': communityLevel,
    });
  }
}
