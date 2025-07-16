// All imports same as before

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

// ----------------------- PROFILE SCREEN -----------------------

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  File? _profileImage;
  String? _base64Image;
  bool _notificationsEnabled = true;
  String _username = "Loading...";
  String _email = "Loading...";

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _username = data['name'] ?? 'N/A';
          _email = data['email'] ?? 'N/A';
          _base64Image = data['profileImage'];
        });
      }
    }
  }

  Future<void> _changeProfilePicture() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await File(pickedFile.path).readAsBytes();
      final base64 = base64Encode(bytes);
      final base64String = 'data:image/png;base64,$base64';

      setState(() {
        _profileImage = File(pickedFile.path);
        _base64Image = base64String;
      });

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'profileImage': base64String,
        });
      }
    }
  }

  Future<void> _requestStorageAndCameraPermissions() async {
    final statuses = await [Permission.storage, Permission.camera].request();
    if (statuses[Permission.storage]!.isGranted && statuses[Permission.camera]!.isGranted) {
      _changeProfilePicture();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Camera & Storage permissions are required.")),
      );
    }
  }

  void _toggleNotifications() {
    setState(() {
      _notificationsEnabled = !_notificationsEnabled;
    });
  }

  void _editProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(
          initialUsername: _username,
          initialEmail: _email,
        ),
      ),
    );

    if (result != null && result is Map<String, String>) {
      setState(() {
        _username = result['username']!;
        _email = result['email']!;
      });

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'name': _username,
          'email': _email,
        });
      }
    }
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageWidget = _profileImage != null
        ? FileImage(_profileImage!)
        : (_base64Image != null
            ? MemoryImage(base64Decode(_base64Image!.split(',').last))
            : null);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal,
        title: const Text("Profile", style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      backgroundColor: Colors.white,
      body: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          GestureDetector(
            onTap: _requestStorageAndCameraPermissions,
            child: Center(
              child: CircleAvatar(
                radius: 60,
                backgroundImage: imageWidget as ImageProvider?,
                child: imageWidget == null
                    ? const Icon(Icons.person, size: 60, color: Colors.white)
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(_username,
                style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold)),
          ),
          Center(
            child: Text(_email,
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.black54)),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _editProfile,
            icon: const Icon(Icons.edit, color: Colors.white),
            label: const Text("Edit Profile", style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          const SizedBox(height: 24),
          SwitchListTile(
            title: const Text("Notifications"),
            value: _notificationsEnabled,
            onChanged: (_) => _toggleNotifications(),
          ),
          ListTile(
            leading: const Icon(Icons.lock_outline, color: Colors.black),
            title: const Text("Privacy & Security"),
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const PrivacySecurityScreen()));
            },
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.description_outlined, color: Colors.black),
            title: const Text("View Terms & Privacy Policy"),
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const TermsAndPrivacyScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text("Logout", style: TextStyle(color: Colors.red)),
            onTap: _logout,
          ),
        ],
      ),
    );
  }
}

// ----------------------- TERMS SCREEN -----------------------

class TermsAndPrivacyScreen extends StatelessWidget {
  const TermsAndPrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Terms & Privacy Policy", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListView(
          children: const [
            Text("BloomMind - Terms of Use",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
            SizedBox(height: 10),
            Text(
              "By using BloomMind, you agree not to misuse any part of the app, including diary, surveys, and community chats. "
              "You must be at least 18 years old to use this app. We reserve the right to suspend accounts violating these terms.",
              style: TextStyle(color: Colors.teal),
            ),
            SizedBox(height: 20),
            Text("Privacy Policy",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
            SizedBox(height: 10),
            Text(
              "BloomMind values your privacy. We collect minimal data — including your mood surveys, diary entries, and chat messages — solely to improve your well-being experience. "
              "None of your personal data is shared with third parties. You may request data deletion at any time.",
              style: TextStyle(color: Colors.teal),
            ),
            SizedBox(height: 20),
            Text("Contact",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
            SizedBox(height: 10),
            Text("For any concerns, contact support@bloommind.app",
                style: TextStyle(color: Colors.teal)),
          ],
        ),
      ),
    );
  }
}

// ----------------------- PRIVACY SCREEN -----------------------

class PrivacySecurityScreen extends StatelessWidget {
  const PrivacySecurityScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Privacy & Security", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.teal,
      ),
      body: Container(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.lock_reset, color: Colors.teal),
              title: const Text("Change Password"),
              onTap: () => _showPasswordResetDialog(context),
            ),
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text("Delete My Account"),
              onTap: () => _confirmDeleteAccount(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showPasswordResetDialog(BuildContext context) {
    final TextEditingController emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Reset Password"),
        content: TextField(
          controller: emailController,
          decoration: const InputDecoration(labelText: "Enter your email"),
        ),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: const Text("Send Reset Link"),
            onPressed: () async {
              final email = emailController.text.trim();
              try {
                await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Reset link sent to your email.")),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Error: ${e.toString()}")),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Account"),
        content: const Text("Are you sure you want to permanently delete your account and all data?"),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete"),
            onPressed: () => _deleteAccount(context),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final uid = user.uid;
      final firestore = FirebaseFirestore.instance;

      await firestore.collection('users').doc(uid).delete();
      await firestore.collection('survey_results').doc(uid).delete();
      await user.delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Account deleted successfully.")),
      );
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error deleting account: $e")),
      );
    }
  }
}

// ----------------------- EDIT PROFILE SCREEN -----------------------

class EditProfileScreen extends StatefulWidget {
  final String initialUsername;
  final String initialEmail;

  const EditProfileScreen({
    required this.initialUsername,
    required this.initialEmail,
  });

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _usernameController;
  late TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.initialUsername);
    _emailController = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _saveChanges() {
    String updatedUsername = _usernameController.text;
    String updatedEmail = _emailController.text;

    Navigator.pop(
      context,
      {'username': updatedUsername, 'email': updatedEmail},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: "Username"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saveChanges,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              child: const Text("Save Changes", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}