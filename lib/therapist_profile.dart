import 'package:flutter/material.dart';

class TherapistProfileScreen extends StatelessWidget {
  final Map<String, dynamic> therapist;

  const TherapistProfileScreen({required this.therapist, super.key});

  @override
  Widget build(BuildContext context) {
    final name = therapist['name'] ?? 'Unknown';
    final specialization = therapist['specialization'] ?? 'N/A';
    final id = therapist['id'] ?? 'N/A';
    final email = therapist['email'] ?? 'Not provided';
    final phone = therapist['phone'] ?? 'Not available'; // ✅ fixed key

    return Scaffold(
      appBar: AppBar(
        title: const Text("Therapist Profile", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.teal,
      ),
      body: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.teal
  
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Icon(Icons.person_pin, size: 200, color: Colors.white70),
            ),
            const SizedBox(height: 20),
            _infoTile("Name", name),
            _infoTile("Specialization", specialization),
            _infoTile("Therapist ID", id),
            _infoTile("Email", email),
            _infoTile("Contact No", phone), // ✅ use phone, not contact
          ],
        ),
      ),
    );
  }

  Widget _infoTile(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(
            "$title: ",
            style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold,fontSize: 20),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 20),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
