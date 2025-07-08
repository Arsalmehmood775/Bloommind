import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminPanel extends StatelessWidget {
  const AdminPanel({super.key});

  Future<void> _unmuteUser(String uid) async {
    await FirebaseFirestore.instance.collection('muted_users').doc(uid).delete();
  }

  Future<bool> _isMuted(String uid) async {
    final doc = await FirebaseFirestore.instance.collection('muted_users').doc(uid).get();
    return doc.exists;
  }

  Future<void> _toggleMute(String uid, bool currentlyMuted) async {
    final mutedRef = FirebaseFirestore.instance.collection('muted_users').doc(uid);
    if (currentlyMuted) {
      await mutedRef.delete();
    } else {
      await mutedRef.set({
        'reason': 'Manually muted by admin',
        'mutedAt': Timestamp.now(),
      });
    }
  }

  void _confirmDeleteUser(BuildContext context, String uid) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete User"),
        content: const Text("This will permanently delete the user and all associated data. Are you sure?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              await _deleteUserData(uid);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("User deleted.")));
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteUserData(String uid) async {
    final firestore = FirebaseFirestore.instance;
    await firestore.collection('users').doc(uid).delete();
    await firestore.collection('survey_results').doc(uid).delete();
    await firestore.collection('diary_entries').doc(uid).delete();
    await firestore.collection('muted_users').doc(uid).delete();
    // Optionally add: delete from `notifications`, `todo_tasks`, etc.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Panel"),
        backgroundColor: Colors.teal,
      ),
      body: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            const TabBar(
              labelColor: Colors.teal,
              unselectedLabelColor: Colors.grey,
              tabs: [
                Tab(text: "Muted Users"),
                Tab(text: "Abuse Reports"),
                Tab(text: "All Users"), // NEW TAB
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  // 🔇 Muted Users Tab
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('muted_users').snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                      final docs = snapshot.data!.docs;
                      if (docs.isEmpty) return const Center(child: Text("No muted users."));
                      return ListView.builder(
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final data = docs[index].data() as Map<String, dynamic>;
                          final uid = docs[index].id;
                          final reason = data['reason'] ?? 'Unknown';
                          final mutedAt = (data['mutedAt'] as Timestamp).toDate();

                          return ListTile(
                            leading: const Icon(Icons.block, color: Colors.red),
                            title: Text("User ID: $uid"),
                            subtitle: Text("Reason: $reason\nMuted At: $mutedAt"),
                            trailing: IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: Colors.green),
                              onPressed: () async {
                                await _unmuteUser(uid);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("User unmuted")),
                                );
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),

                  // ⚠️ Abuse Reports Tab
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('abuse_reports')
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                      final docs = snapshot.data!.docs;
                      if (docs.isEmpty) return const Center(child: Text("No abuse reports."));
                      return ListView.builder(
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final data = docs[index].data() as Map<String, dynamic>;
                          final uid = data['senderId'] ?? 'Unknown';
                          final original = data['originalMessage'] ?? '';
                          final cleaned = data['cleanedMessage'] ?? '';
                          final time = (data['timestamp'] as Timestamp).toDate();

                          return ListTile(
                            leading: const Icon(Icons.warning, color: Colors.orange),
                            title: Text("User ID: $uid"),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Original: $original"),
                                Text("Filtered: $cleaned"),
                                Text("At: $time"),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),

                  // 👥 All Users Tab (NEW)
                  // 👥 All Users Tab (Optimized, no per-user FutureBuilder)
                  FutureBuilder<QuerySnapshot>(
                    future: FirebaseFirestore.instance.collection('muted_users').get(),
                    builder: (context, mutedSnapshot) {
                      if (!mutedSnapshot.hasData) return const Center(child: CircularProgressIndicator());

                      // ✅ Step 1: Get all muted user IDs
                      final mutedUserIds = mutedSnapshot.data!.docs.map((doc) => doc.id).toSet();

                      return StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance.collection('users').snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                          final users = snapshot.data!.docs;
                          if (users.isEmpty) return const Center(child: Text("No users found."));

                          return ListView.builder(
                            itemCount: users.length,
                            itemBuilder: (context, index) {
                              final user = users[index];
                              final data = user.data() as Map<String, dynamic>;
                              final uid = user.id;
                              final name = data['name'] ?? 'No Name';
                              final email = data['email'] ?? 'No Email';
                              final level = data['stressLevel'] ?? 'Unknown';

                              // ✅ Step 2: Check if this user is in the muted set
                              final isMuted = mutedUserIds.contains(uid);

                              return ListTile(
                                leading: const Icon(Icons.person),
                                title: Text(name),
                                subtitle: Text("Email: $email\nStress Level: $level"),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        isMuted ? Icons.volume_off : Icons.volume_up,
                                        color: isMuted ? Colors.red : Colors.green,
                                      ),
                                      onPressed: () => _toggleMute(uid, isMuted),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.grey),
                                      onPressed: () => _confirmDeleteUser(context, uid),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  )

                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}