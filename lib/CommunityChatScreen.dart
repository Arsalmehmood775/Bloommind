
import 'package:bloommind/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import 'chat_massages.dart';
import 'package:profanity_filter/profanity_filter.dart';

class CommunityChatScreen extends StatefulWidget {
  const CommunityChatScreen({Key? key}) : super(key: key);
  @override
  _CommunityChatScreenState createState() => _CommunityChatScreenState();
}
class _CommunityChatScreenState extends State<CommunityChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<ChatMessage> _messages = [];
  String _typingIndicator = "";
  int _selectedMessageIndex = -1;
  bool _isTyping = false;
  bool _isLoading = true;
  String? _stressLevel;
  ChatMessage? _replyingTo;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  void _initializeChat() async {
    await _fetchUserStressLevel(); // 👈 Ensures listener is initialized AFTER stressLevel is available
    _simulateMessageStatusUpdate();
  }


  String _getCommunityCollection() {
    switch (_stressLevel) {
      case 'Mild':
        return 'community_mild';
      case 'Moderate':
        return 'community_moderate';
      case 'Severe':
        return 'community_severe';
      default:
        return 'community_unknown';
    }
  }

  Future<void> _fetchUserStressLevel() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      setState(() {
        _stressLevel = doc.data()?['latestStressLevel'] ?? 'Unknown';
      });

      print("🔥 Stress Level Fetched: $_stressLevel"); // <--- ADD THIS

      if (_stressLevel != null) {
        FirebaseFirestore.instance
            .collection(_getCommunityCollection())
            .orderBy('timestamp', descending: false)
            .snapshots()
            .listen((snapshot) {
          print("📥 Received ${snapshot.docs.length} messages"); // <--- ADD THIS
          _loadMessagesWithProfiles(snapshot.docs);
        });
      }
    }
  }

  Future<void> _loadMessagesWithProfiles(List<QueryDocumentSnapshot> docs) async {
    List<ChatMessage> loadedMessages = [];
    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final senderId = data['senderId'];

      String senderName = data['senderName'] ?? '';

      // 🔁 Fallback: Fetch name from users collection if not already in message
      if (senderName.isEmpty) {
        try {
          final userDoc = await FirebaseFirestore.instance.collection('users').doc(senderId).get();
          final userData = userDoc.data();
          if (userData != null && userData.containsKey('name')) {
            senderName = userData['name'];
          }
        } catch (e) {
          print('Error loading senderName for $senderId: $e');
        }
      }

      final message = ChatMessage.fromMap({
        ...data,
        'senderName': senderName,  // ✅ Overwrite/fill-in sender name

      }, doc.id);

      loadedMessages.add(message);
    }

    setState(() {
      _messages = loadedMessages;
      _isLoading = false;
    });

    _scrollToBottom();
  }



  Future<void> _sendMessage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _messageController.text.trim().isEmpty || _stressLevel == null) return;

    final rawText = _messageController.text.trim();
    final timestamp = Timestamp.now();

    // 🔍 Profanity Filter Setup
    final filter = ProfanityFilter();
    final hasProfanity = filter.hasProfanity(rawText);
    final cleanedText = filter.censor(rawText);

    // 🔇 Check if muted
    final muteDoc = await FirebaseFirestore.instance
        .collection('muted_users')
        .doc(user.uid)
        .get();

    if (muteDoc.exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("You are muted due to inappropriate behavior."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // ⚠️ Profanity: Report & Mute
    if (hasProfanity) {
      await FirebaseFirestore.instance.collection('abuse_reports').add({
        'senderId': user.uid,
        'originalMessage': rawText,
        'cleanedMessage': cleanedText,
        'timestamp': timestamp,
      });

      await FirebaseFirestore.instance.collection('muted_users').doc(user.uid).set({
        'mutedAt': timestamp,
        'reason': 'Used profanity',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("You’ve been muted for using offensive language."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // ✏️ Edit existing message
    if (_selectedMessageIndex != -1) {
      final editedMessage = _messages[_selectedMessageIndex];
      final docSnapshot = await FirebaseFirestore.instance
          .collection(_getCommunityCollection())
          .where('timestamp', isEqualTo: editedMessage.timestamp)
          .where('senderId', isEqualTo: editedMessage.senderId)
          .limit(1)
          .get();

      if (docSnapshot.docs.isNotEmpty) {
        final docId = docSnapshot.docs.first.id;

        await FirebaseFirestore.instance
            .collection(_getCommunityCollection())
            .doc(docId)
            .update({
          'message': cleanedText,
          'edited': true,
        });

        // 🧾 Log edit
        await FirebaseFirestore.instance.collection('activity_logs').add({
          'type': 'edit',
          'userId': user.uid,
          'messageId': docId,
          'newMessage': cleanedText,
          'timestamp': timestamp,
        });
      }

      setState(() {
        _selectedMessageIndex = -1;
        _replyingTo = null;
        _typingIndicator = "";
      });
    }

    // ✉️ Send new message
    else {
      String senderName = 'User'; // Default fallback

      try {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          senderName = userDoc.data()?['name'] ?? 'User';
        } else {
          print("❗User doc does not exist in Firestore.");
        }
      } catch (e) {
        print("❌ Error fetching user name from Firestore: $e");
      }


      print("✅ SENDING AS NAME: $senderName"); // ✅ Debug: should print "Naveed" etc.


      final newMessage = ChatMessage(
        senderId: user.uid,
        senderName: senderName, // ✅ This must be user's real name
        message: cleanedText,
        timestamp: timestamp,
        status: "Sent",
        replyTo: _replyingTo?.toMap(),
        edited: false,
        id: '',
      );

      try {
        print("✅ Sending message:");
        print("UID: ${user.uid}");
        print("Sender Name: $senderName");
        print("Message: $cleanedText");
        print("Collection: ${_getCommunityCollection()}");



        final docRef = await FirebaseFirestore.instance
            .collection(_getCommunityCollection())
            .add(newMessage.toMap());



        // 🔍 Log activity (optional)
        await FirebaseFirestore.instance.collection('activity_logs').add({
          'type': 'send',
          'userId': user.uid,
          'messageId': docRef.id,
          'message': cleanedText,
          'timestamp': timestamp,
        });
      } catch (e) {
        print("❌ Failed to send message: $e");
      }
    }


    _messageController.clear();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _deleteMessage(int index) async {
    final message = _messages[index];

    try {
      // Find the exact Firestore doc using timestamp + senderId
      final snapshot = await FirebaseFirestore.instance
          .collection(_getCommunityCollection())
          .where('timestamp', isEqualTo: message.timestamp)
          .where('senderId', isEqualTo: message.senderId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection(_getCommunityCollection())
            .doc(snapshot.docs.first.id)
            .delete();
      }

      setState(() {
        _messages.removeAt(index);
      });
    } catch (e) {
      print("Failed to delete message: $e");
    }
  }

  void _editMessage(int index) {
    setState(() {
      _messageController.text = _messages[index].message;
      _selectedMessageIndex = index; // Track which message is being edited
    });
  }

  void _replyToMessage(int index) {
    setState(() {
      _replyingTo = _messages[index];
      _typingIndicator = "Replying to: ${_messages[index].message}";
    });
  }

  void _simulateMessageStatusUpdate() async {
    Future.delayed(const Duration(seconds: 2), () async {
      if (mounted) {
        for (var i = 0; i < _messages.length; i++) {
          final current = _messages[i];

          String? newStatus;
          if (current.status == "Sent") {
            newStatus = "Delivered";
          } else if (current.status == "Delivered" && Random().nextBool()) {
            newStatus = "Read";
          }

          if (newStatus != null) {
            // 🔥 Update in Firestore
            final snapshot = await FirebaseFirestore.instance
                .collection(_getCommunityCollection())
                .where('timestamp', isEqualTo: current.timestamp)
                .where('senderId', isEqualTo: current.senderId)
                .limit(1)
                .get();

            if (snapshot.docs.isNotEmpty) {
              await FirebaseFirestore.instance
                  .collection(_getCommunityCollection())
                  .doc(snapshot.docs.first.id)
                  .update({'status': newStatus});

              // Also update locally
              setState(() {
                _messages[i] = current.copyWith(status: newStatus!);
              });
            }
          }
        }
      }
    });
  }

  void _startTyping() {
    setState(() {
      _isTyping = true;
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isTyping = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!['Mild', 'Moderate', 'Severe'].contains(_stressLevel)) {
      return const Scaffold(
        body: Center(child: Text("Access denied: No valid stress level assigned.")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            color: Colors.teal
          ),
        ),
        centerTitle: true,
        title:  Text("$_stressLevel Stress Community", style: const TextStyle(color: Colors.white)),
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.white
        ),
        child: Column(
          children: [
            AnimatedOpacity(
              opacity: _isTyping ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  "User is typing...",
                  style: TextStyle(color: Colors.white70, fontStyle: FontStyle.italic),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(10),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  final currentUser = FirebaseAuth.instance.currentUser;
                  final isMe = message.senderId == currentUser?.uid;

                  return GestureDetector(
                      onLongPress: () {
                        showModalBottomSheet(
                          backgroundColor: Colors.teal,
                          context: context,
                          builder: (context) => Container(
                            padding: const EdgeInsets.all(10),
                            child: Wrap(
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.reply, color: Colors.white),
                                  title: const Text("Reply", style: TextStyle(color: Colors.white)),
                                  onTap: () {
                                    _replyToMessage(index);
                                    Navigator.pop(context);
                                  },
                                ),
                                if (isMe) ...[
                                  ListTile(
                                    leading: const Icon(Icons.edit, color: Colors.white),
                                    title: const Text("Edit", style: TextStyle(color: Colors.white)),
                                    onTap: () {
                                      _editMessage(index);
                                      Navigator.pop(context);
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.delete, color: Colors.red),
                                    title: const Text("Delete", style: TextStyle(color: Colors.white)),
                                    onTap: () {
                                      _deleteMessage(index);
                                      Navigator.pop(context);
                                    },
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },

                      key: null,
                    child: Row(
                      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Flexible(
                          child: Column(
                            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              // ✅ Only show name above other user's messages
                              if (!isMe)
                                Padding(
                                  padding: const EdgeInsets.only(left: 4.0, bottom: 2.0),
                                  child: Text(
                                    message.senderName,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),

                              // ✅ Chat bubble
                              IntrinsicWidth(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  margin: const EdgeInsets.symmetric(vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isMe ? Colors.teal : Colors.grey.shade800,
                                    borderRadius: BorderRadius.only(
                                      topLeft: const Radius.circular(12),
                                      topRight: const Radius.circular(12),
                                      bottomLeft: Radius.circular(isMe ? 12 : 0),
                                      bottomRight: Radius.circular(isMe ? 0 : 12),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // ✅ Show reply block (from any user)
                                      if (message.replyTo != null)
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          margin: const EdgeInsets.only(bottom: 6),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade700,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            "Replying to: ${message.replyTo!['message']}",
                                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                                          ),
                                        ),

                                      // ✅ Actual message
                                      Text(
                                        message.message,
                                        style: const TextStyle(color: Colors.white,fontSize: 16),
                                      ),

                                      const SizedBox(height: 2),

                                      // ✅ Timestamp + read status
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            DateFormat('hh:mm a').format(message.timestamp.toDate()),
                                            style: const TextStyle(color: Colors.white70, fontSize: 11),
                                          ),
                                          const SizedBox(width: 4),
                                          if (isMe)
                                            Icon(
                                              message.status == "Read"
                                                  ? Icons.done_all
                                                  : Icons.done,
                                              size: 16,
                                              color: message.status == "Read"
                                                  ? Colors.lightBlueAccent
                                                  : Colors.white70,
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),


            if (_replyingTo != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),

                margin: const EdgeInsets.only(bottom: 5),
                decoration: BoxDecoration(
                  color: Colors.teal.shade500,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        "Replying to: ${_replyingTo!.message}",
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70, size: 18),
                      onPressed: () {
                        setState(() {
                          _replyingTo = null;
                          _typingIndicator = "";
                        });
                      },
                    ),
                  ],
                ),
              ),
            Container(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Enter message",
                        hintStyle: const TextStyle(color: Colors.white),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25.0),
                        ),
                        filled: true,
                        fillColor: Colors.teal,
                      ),
                      onChanged: (value) {
                        if (value.isNotEmpty && !_isTyping) {
                          _startTyping();
                        }
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.teal),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}