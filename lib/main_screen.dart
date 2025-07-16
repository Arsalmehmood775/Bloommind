import 'dart:convert';
import 'package:bloommind/CommunityChatScreen.dart';
import 'package:bloommind/DiaryScreen.dart';
import 'package:bloommind/meditation_screen.dart';
import 'package:bloommind/profile_screen.dart';
import 'package:bloommind/quote_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'admin_panel.dart';
import 'mood_booster.dart';
import 'therapist_selection_screen.dart';
import 'HelpScreen.dart';
import 'survey_screen.dart';



class MainScreen extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
  
}
class _HomePageState extends State<MainScreen> {
  bool showRetakeSurveyButton = false; // ✅ flag to show retake survey button
  String userName = "";
  String? profileImageBase64;
  bool _isAdmin = false; // ✅ check if current user is admin
  @override
  void initState() {
    super.initState();
    _listenToUserChanges();
    _checkAdminStatus();
    checkRetakeSurveyEligibility(); // ✅ fetch admin status
  }


Future<bool> canRetakeSurvey() async {
  final uid = FirebaseAuth.instance.currentUser?.uid;

  if (uid == null) return false;

  final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();

  if (!doc.exists || !doc.data()!.containsKey('lastsurveyDate')) {
    print('No survey date found for user ');
    return true;
  }

  final lastSurveyDate = (doc['lastsurveyDate'] as Timestamp).toDate();
  final now = DateTime.now();

  print('Last survey date: $lastSurveyDate, Current date: $now');
  print("today: $now");
  print("diffrence: ${now.difference(lastSurveyDate).inDays} days");

  return now.difference(lastSurveyDate).inDays >= 7;
}
void checkRetakeSurveyEligibility() async {
  final result = await canRetakeSurvey();
  setState(() {
    showRetakeSurveyButton = result;
  });
}
  void _listenToUserChanges() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots().listen((snapshot) {
        if (snapshot.exists) {
          final data = snapshot.data()!;
          setState(() {
            userName = data['name'] ?? '';
            profileImageBase64 = data['profileImage']; // We'll define this below
          });
        }
      });
    }
  }

  void _checkAdminStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (doc.exists && doc.data()?['isAdmin'] == true) {
      setState(() {
        _isAdmin = true;
      });
    }
  }



  Future<void> getUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc =
      await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      setState(() {
        userName = userDoc['name'] ?? '';
        profileImageBase64 = userDoc['profileImage'];
      });
    }
  }
  Future<void> _saveFeelingToFirestore(String feeling) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .update({'currentFeeling': feeling});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Saved feeling: $feeling')),
    );
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final List<Map<String, dynamic>> feelings = [
    {"emoji": "😁", "label": "HAPPY"},
    {"emoji": "😌", "label": "CALM"},
    {"emoji": "😔", "label": "SAD"},
    {"emoji": "😡", "label": "ANGRY"},
    {"emoji": "😐", "label": "BORED"},
  ];
  int selectedFeelingIndex = -1;
  int notificationCount = 3;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: NavigationDrawer(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: CircleAvatar(
              radius: 60,
              backgroundImage: profileImageBase64 != null
                  ? MemoryImage(base64Decode(profileImageBase64!.split(',').last))
                  : AssetImage('assets/default_profile.png') as ImageProvider,
              child: profileImageBase64 == null
                  ? Icon(Icons.person, size: 60, color: Colors.white)
                  : null,
            ),

          ),
          SizedBox(height: 10),
          ListTile(leading: Icon(Icons.person), title: Text('Profile'),
          onTap: (){
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ProfileScreen()),
            );
          },),
          Divider(),
                  ListTile(
          leading: Icon(Icons.help),
          title: Text('Help'),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HelpScreen()),
            );
          },
        ),


          if (_isAdmin)
            ListTile(
              leading: const Icon(Icons.admin_panel_settings, color: Colors.teal),
              title: const Text("Admin Panel"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AdminPanel()),
                );
              },
            ),


        ],
      ),
      endDrawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.teal ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Notifications',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(FirebaseAuth.instance.currentUser!.uid)
                    .collection('notifications')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }

                  final notifications = snapshot.data!.docs;

                  if (notifications.isEmpty) {
                    return Center(child: Text("No notifications"));
                  }

                  return ListView.builder(
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notif = notifications[index];
                      return ListTile(
                        title: Text(notif['title']),
                        subtitle: Text(notif['message']),
                        trailing: Text(
                          DateFormat('MM/dd HH:mm').format(
                              (notif['timestamp'] as Timestamp).toDate()),
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),

      backgroundColor: Color(0xFF009A94),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: Color(0xFF009A94),
              pinned: true,
              expandedHeight: 310.0,
              toolbarHeight: 0,
              flexibleSpace: FlexibleSpaceBar(
                background: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: _openProfileDrawer,
                            child: CircleAvatar(
                              radius: 25,
                              backgroundImage: profileImageBase64 != null
                                  ? MemoryImage(base64Decode(profileImageBase64!.split(',').last))
                                  : AssetImage('assets/default_profile.png') as ImageProvider,
                              child: profileImageBase64 == null
                                  ? Icon(Icons.person, color: Color(0xFF009A94))
                                  : null,
                            ),

                          ),
                          Spacer(),
                          GestureDetector(
                            onTap: _openRightDrawer,
                            child: Stack(
                              children: [
                                Icon(Icons.notifications,
                                    color: Colors.white, size: 30),
                                Positioned(
                                  right: 0,
                                  child: Container(
                                    padding: EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.orange,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      notificationCount.toString(),
                                      style: TextStyle(
                                          fontSize: 10, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello,',
                            style: TextStyle(color: Colors.white, fontSize: 20),
                          ),
                          Text(
                            userName,
                            style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Text('How are you feeling today?',
                          style: TextStyle(color: Colors.white70, fontSize: 22, fontWeight: FontWeight.bold )),

                      SizedBox(height: 15),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: feelings.asMap().entries.map((entry) {
                            int index = entry.key;
                            var f = entry.value;
                            bool isSelected = selectedFeelingIndex == index;
                            return GestureDetector(
                              onTap: () {
                                setState(() => selectedFeelingIndex = index);
                                _saveFeelingToFirestore(feelings[index]['label']);
                              },


                              child: AnimatedContainer(
                                duration: Duration(milliseconds: 200),
                                margin: EdgeInsets.symmetric(horizontal: 10),
                                padding: EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.white.withOpacity(0.2)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  children: [
                                    AnimatedScale(
                                      scale: isSelected ? 1.4 : 1.0,
                                      duration: Duration(milliseconds: 200),
                                      child: Text(f["emoji"], style: TextStyle(fontSize: 28)),
                                    ),
                                    SizedBox(height: 5),
                                    Text(f["label"],
                                        style: TextStyle(color: Colors.white, fontSize: 12))
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildListDelegate([
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                  ),
                  child: Column(
                    children: [
                      AnimatedMenuButton(
                        color: Color.fromARGB(176, 165, 17, 185),
                        icon: Icons.chat,
                        label: 'COMMUNITY',
                        iconAlignment: Alignment.centerRight,
                        onTap: (){
                          Navigator.push(
                              context,
                          MaterialPageRoute(builder: (context) => CommunityChatScreen()));
                        },
                      ),
                      SizedBox(height: 20),
                      AnimatedMenuButton(
                        color: Color.fromARGB(255, 86, 95, 221),
                        icon: Icons.rocket_launch,
                        label: 'MOOD BOOSTER',
                        iconAlignment: Alignment.centerRight, // Icon on the right side
                        onTap: (){
                          Navigator.push(
                            context,
                          MaterialPageRoute(builder: (context) => BloomMindMiniGamesApp()),
                          );
                        },
                      ),
                      SizedBox(height: 20),
                      AnimatedMenuButton(
                        color: Color.fromARGB(255, 39, 237, 241),
                        icon: Icons.self_improvement,
                        label: 'MEDITATION',
                        iconAlignment: Alignment.centerRight, // Icon on the right side
                        onTap: (){
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => MeditationScreen()),
                          );
                        },
                      ),
                      SizedBox(height: 20),
                      AnimatedMenuButton(
                        color: Color(0xFFEE5A4F),
                        icon: Icons.book,
                        label: 'JOURNAL',
                        iconAlignment: Alignment.centerRight, // Icon on the right side
                        onTap: (){
                          Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => DiaryScreen()));
                        },
                      ),
                      SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                        Expanded(
                            child: AnimatedMenuButton(
                              color: Colors.blue,
                              icon: Icons.person,
                              label: 'THERAPISTS',
                              iconAlignment: Alignment.centerRight,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => TherapistSelectionScreen()),
                                );
                              },
                            ),
                          )
                          ,
                          SizedBox(width: 20),
                          Expanded(
                            child: AnimatedMenuButton(
                              color: const Color.fromARGB(255, 165, 239, 80),
                              icon: Icons.format_quote,
                              label: 'QUOTE',
                              iconAlignment: Alignment.centerRight, // Icon on the right side
                              onTap: (){
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context)=> QuotePage()));

                                    
                              },
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      if (showRetakeSurveyButton)
  Padding(
    padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 0.0),
    child: ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.teal,
        minimumSize: const Size(double.infinity, 50),
      ),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SurveyScreen()),
        );
      },
      icon: const Icon(Icons.refresh, color: Colors.white),
      label: const Text(
        "Retake Mental Health Survey",
        style: TextStyle(color: Colors.white),
      ),
    ),
  ),
                    ],
                  ),
                )
              ]),
            ),
          ],
        ),
      ),
    );
  }
  void _openProfileDrawer() => _scaffoldKey.currentState?.openDrawer();
  void _openRightDrawer() => _scaffoldKey.currentState?.openEndDrawer();
}
class AnimatedMenuButton extends StatefulWidget {
  final Color color;
  final IconData icon;
  final String label;
  final Alignment iconAlignment; // Added property for icon alignment
  final VoidCallback? onTap;

  AnimatedMenuButton({
    required this.color,
    required this.icon,
    required this.label,
    this.iconAlignment = Alignment.centerLeft,
    this.onTap, // Default alignment is left
  });
  @override
  _AnimatedMenuButtonState createState() => _AnimatedMenuButtonState();
}
class _AnimatedMenuButtonState extends State<AnimatedMenuButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 150),
      lowerBound: 0.95,
      upperBound: 1.0,
      value: 1.0,
    );
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _controller.reverse(),
      onTapUp: (_) => _controller.forward(),
      onTapCancel: () => _controller.forward(),

      child: ScaleTransition(
        scale: _controller,
        child: Container(
          height: 130,
          width: double.infinity,
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              Positioned(bottom: -10, right: -10, child: _buildCircle(150, Colors.black12)),
              Positioned(top: 7, left: 110, child: _buildCircle(50, Colors.black12)),
              Positioned(bottom: -17, right: 90, child: _buildCircle(90, Colors.black12)),
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      if (widget.iconAlignment == Alignment.centerLeft) ...[
                        Icon(
                          widget.icon,
                          color: Colors.white,
                          size: (widget.label == "GOAL TRAINER" || widget.label == "QUOTE") ? 28 : 40,
                        ),
                        SizedBox(width: 15),
                      ],
                      Expanded(
                        child: Text(
                          widget.label,
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold), textAlign: widget.iconAlignment==Alignment.centerRight? TextAlign.left:TextAlign.right,
                          maxLines: 1,
                          overflow: TextOverflow.visible,
                        ),
                      ),
                      if (widget.iconAlignment == Alignment.centerRight) ...[
                        SizedBox(width: 15),
                        Icon(
                          widget.icon,
                          color: Colors.white,
                          size: (widget.label == "GOAL TRAINER" || widget.label == "QUOTE") ? 28 : 30,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildCircle(double size, Color color) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}