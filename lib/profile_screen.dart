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
    _checkNotificationPermission();
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

  Future<void> _checkNotificationPermission() async {
    final status = await Permission.notification.status;
    setState(() {
      _notificationsEnabled = status.isGranted;
    });
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

      // Save to Firestore
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

  Future<void> _toggleNotifications(bool value) async {
    if (value) {
      final status = await Permission.notification.request();
      if (status.isGranted) {
        setState(() {
          _notificationsEnabled = true;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Notification permission is required.")),
        );
      }
    } else {
      setState(() {
        _notificationsEnabled = false;
      });
      // Optionally: You might want to disable notifications in your backend here
    }
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
        elevation: 0,
        backgroundColor: Colors.teal,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            color: Colors.teal
          ),
        ),
        title: const Text("Profile", style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Colors.white,
        ),
        child: ListView(
          padding: const EdgeInsets.all(20.0),
          children: [
            GestureDetector(
              onTap: _requestStorageAndCameraPermissions,
              child: Center(
                child: CircleAvatar(
                  radius: 60,
                  backgroundImage: imageWidget as ImageProvider?,
                  child: imageWidget == null
                      ? Icon(Icons.person, size: 60, color: Colors.white,)
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(_username, style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal)),
            ),
            Center(
              child: Text(_email, style: GoogleFonts.poppins(fontSize: 16, color: Colors.white,)),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _editProfile,
              icon: const Icon(Icons.edit,color: Colors.white,),
              label: Text("Edit Profile", style: TextStyle(color: Colors.white,)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 24),
            SwitchListTile(
              title: Text("Notifications", style: TextStyle(color: Colors.teal)),
              value: _notificationsEnabled,
              onChanged: _toggleNotifications,  // Fixed: Now using the correct function
            ),
            ListTile(
              leading: const Icon(Icons.lock_outline, color: Colors.teal),
              title: const Text("Privacy & Security", style: TextStyle(color: Colors.teal)),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacySecurityScreen()));
              },
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.description_outlined, color: Colors.teal),
              title: const Text("View Terms & Privacy Policy", style: TextStyle(color: Colors.teal)),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsAndPrivacyScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text("Logout", style: TextStyle(color: Colors.red)),
              onTap: _logout,
            ),
          ],
        ),
      ),
    );
  }
}

class PrivacySecurityScreen extends StatelessWidget {
  const PrivacySecurityScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy & Security'),
        backgroundColor: Colors.teal,
      ),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text(
          'Here are the Privacy & Security details...',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}

class TermsAndPrivacyScreen extends StatelessWidget {
  const TermsAndPrivacyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms & Privacy Policy'),
        backgroundColor: Colors.teal,
      ),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text(
          'Here are the Terms and Privacy Policy details...',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}

// Dummy EditProfileScreen implementation to resolve the error.
// Replace this with your actual EditProfileScreen implementation if you have one.
class EditProfileScreen extends StatefulWidget {
  final String initialUsername;
  final String initialEmail;

  const EditProfileScreen({
    Key? key,
    required this.initialUsername,
    required this.initialEmail,
  }) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
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
    Navigator.pop(context, {
      'username': _usernameController.text,
      'email': _emailController.text,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile"),
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