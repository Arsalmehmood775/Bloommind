import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class DiaryScreen extends StatefulWidget {
  const DiaryScreen({Key? key}) : super(key: key);

  @override
  _DiaryScreenState createState() => _DiaryScreenState();
}
class _DiaryScreenState extends State<DiaryScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _entryController = TextEditingController();
  final TextEditingController _todoController = TextEditingController();
  int? _editingIndex;
  final TextEditingController _paragraphController = TextEditingController();
  List<Map<String, String>> _entries = [];
  List<Map<String, dynamic>> _todoList = [];
  String _selectedMood = "Neutral";
  bool _isNotesSelected = true;
  DateTime? _selectedDateTime;

  void _showAddTodoDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF009A94),
          title: const Text("Add New Task", style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _todoController,
                style: const TextStyle(color:Colors.white),
                decoration: const InputDecoration(
                    hintText: "New Task",
                    hintStyle: TextStyle(color: Colors.white70)),
              ),
              const SizedBox(height: 15),
              ElevatedButton(
                onPressed: () => _selectDateTime(),
                child: const Text("Set Date and Time"),
              ),
              const SizedBox(height: 10),
              Text(
                  _selectedDateTime != null
                      ? DateFormat('yyyy-MM-dd – kk:mm')
                      .format(_selectedDateTime!)
                      : "No date and time set",
                  style: const TextStyle(color: Colors.white)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                _addTodo();
                Navigator.pop(context);
              },
              child: const Text("Save", style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Cancel", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
  void _startEditing(int index) {
    setState(() {
      _editingIndex = index;
      _titleController.text = _entries[index]["title"]!;
      _paragraphController.text = _entries[index]["paragraph"]!;
      _entryController.text = _entries[index]["text"]!;
    });
  }
  void _editNote(int index) {
    setState(() {
      _entries[index] = {
        "title": _titleController.text,
        "text": _entryController.text,
        "date": _entries[index]["date"]!,
        "mood": _entries[index]["mood"]!,
        "paragraph": _paragraphController.text,
      };
      _editingIndex = null;
      _titleController.clear();
      _entryController.clear();
      _paragraphController.clear();
    });
  }
  void _cancelEdit() {
    setState(() {
      _editingIndex = null;
      _titleController.clear();
      _entryController.clear();
      _paragraphController.clear();
    });
  }
  void _saveEntry() async {
    if (_titleController.text.isNotEmpty &&
        _entryController.text.isNotEmpty &&
        _paragraphController.text.isNotEmpty) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print("❌ User is null, not logged in.");
        return;
      }

      print("📤 Attempting to save diary entry...");

      final entryData = {
        'title': _titleController.text,
        'paragraph': _paragraphController.text,
        'text': _entryController.text,
        'mood': _selectedMood,
        'date': DateTime.now(),
        'timestamp': FieldValue.serverTimestamp(),
      };

      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('diary_entries')
            .add(entryData);

        print("✅ Diary entry saved successfully.");

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('notifications')
            .add({
          'title': 'New Diary Entry',
          'message': 'You added a new diary note: ${_titleController.text}',
          'timestamp': Timestamp.now(),
          'type': 'diary',
        });

        setState(() {
          _titleController.clear();
          _entryController.clear();
          _paragraphController.clear();
          _selectedMood = "Neutral";
        });
      } catch (e) {
        print("❌ Error saving diary entry: $e");
      }
    } else {
      print("⚠️ Title or text or paragraph is empty.");
    }
  }


  void _selectDateTime() async { // New function for date/time selection
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (pickedTime != null) {
        setState(() {
          _selectedDateTime = DateTime(pickedDate.year, pickedDate.month,
              pickedDate.day, pickedTime.hour, pickedTime.minute);
        });
      }
    }
  }
  void _deleteEntry(int index) {
    setState(() {
      _entries.removeAt(index);
    });
  }
  void _addTodo() async {
    if (_todoController.text.isNotEmpty && _selectedDateTime != null) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final todoData = {
        'task': _todoController.text,
        'done': false,
        'alert': DateFormat('yyyy-MM-dd – kk:mm').format(_selectedDateTime!),
        'createdAt': Timestamp.now(),
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('todos')
          .add(todoData);

      // Optional: Save notification when a task is added
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .add({
        'title': 'New To-Do Task',
        'message': 'Task added: ${todoData["task"]}',
        'timestamp': Timestamp.now(),
        'type': 'todo',
      });

      setState(() {
        _todoController.clear();
        _selectedDateTime = null;
      });
    }
  }

  void _toggleTodoStatus(int index) {
    setState(() {
      _todoList[index]["done"] = !_todoList[index]["done"];
    });
  }
  void _deleteTodo(int index) {
    setState(() {
      _todoList.removeAt(index);
    });
  }
  void _editTodoFirestore(QueryDocumentSnapshot todo) {
    _todoController.text = todo['task'];
    _selectedDateTime = todo['alert'] != ""
        ? DateFormat('yyyy-MM-dd – kk:mm').parse(todo['alert'])
        : null;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor:Colors.teal,
          title: const Text("Edit Task", style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _todoController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: "Task",
                  hintStyle: TextStyle(color: Colors.white70),
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => _selectDateTime(),
                child: const Text("Set Date and Time"),
              ),
              const SizedBox(height: 10),
              Text(
                _selectedDateTime != null
                    ? DateFormat('yyyy-MM-dd – kk:mm').format(_selectedDateTime!)
                    : "No date and time set",
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(FirebaseAuth.instance.currentUser!.uid)
                    .collection('todos')
                    .doc(todo.id)
                    .update({
                  'task': _todoController.text,
                  'alert': _selectedDateTime != null
                      ? DateFormat('yyyy-MM-dd – kk:mm').format(_selectedDateTime!)
                      : "",
                });

                _todoController.clear();
                _selectedDateTime = null;
                Navigator.pop(context);
              },
              child: const Text("Save", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
  void _setAlertFirestore(QueryDocumentSnapshot todo) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (pickedTime != null) {
        final alert = "${DateFormat('yyyy-MM-dd').format(pickedDate)} ${pickedTime.format(context)}";
        await FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .collection('todos')
            .doc(todo.id)
            .update({'alert': alert});
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add, color: Colors.white, size: 30),
        onPressed: () {
          _isNotesSelected ? _saveEntry() : _showAddTodoDialog();
        },
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFFdf6e3),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () => setState(() => _isNotesSelected = true),
                    child: Text("Notes",
                        style: TextStyle(
                            color: _isNotesSelected ? Colors.teal : Colors.teal.shade200,
                            fontSize: 18)),
                  ),
                  const SizedBox(width: 20),
                  TextButton(
                    onPressed: () => setState(() => _isNotesSelected = false),
                    child: Text("To-Do",
                        style: TextStyle(
                            color: !_isNotesSelected ? Colors.teal : Colors.teal.shade200,
                            fontSize: 18)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _isNotesSelected ? _buildNotesSection() : _buildTodoSection(),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildNotesSection() {
    return Expanded(
      child: Column(
        children: [
          TextField(
            controller: _titleController,
            style:GoogleFonts.zeyada(fontSize: 26, color: Colors.brown.shade900),
            decoration: const InputDecoration(
              hintText: "Title",
              hintStyle: TextStyle(color: Colors.teal),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _paragraphController,
            maxLines: 3,
            style:GoogleFonts.zeyada(fontSize: 26, color: Colors.brown.shade900),
            decoration: const InputDecoration(
              hintText: "Paragraph",
              hintStyle: TextStyle(color: Colors.teal),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _entryController,
            maxLines: 3,
            style:GoogleFonts.zeyada(fontSize: 26, color: Colors.brown.shade900),
            decoration: const InputDecoration(
              hintText: "Entry",
              hintStyle: TextStyle(color: Colors.teal),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(FirebaseAuth.instance.currentUser!.uid)
                  .collection('diary_entries')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                      child: CircularProgressIndicator(color: Colors.white));
                }
                final entries = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    final isEditing = _editingIndex == index;

                    return Card(
                      color: Colors.teal,
                      shape:RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: Colors.white,
                          width: 1,
                        ),
                      ),
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: ListTile(
                          title: isEditing
                              ? TextField(
                            controller: _titleController,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          )
                              : Text(
                            entry['title'] ?? '',
                            style: GoogleFonts.zeyada(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          subtitle: isEditing
                              ? Column(
                            children: [
                              TextField(
                                controller: _paragraphController,
                                maxLines: 3,
                                style:
                                const TextStyle(color: Colors.white),
                              ),
                              TextField(
                                controller: _entryController,
                                maxLines: 3,
                                style:
                                const TextStyle(color: Colors.white),
                              ),
                            ],
                          )
                              : Text(
                            "${entry['paragraph']}\n${entry['text']}\n${DateFormat('yyyy-MM-dd – kk:mm').format((entry['date'] as Timestamp).toDate())}",
                            style:GoogleFonts.zeyada(fontSize:20, color: Colors.white),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isEditing) ...[
                                IconButton(
                                  icon: const Icon(Icons.check,
                                      color: Colors.green),
                                  onPressed: () async {
                                    await FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(FirebaseAuth
                                        .instance.currentUser!.uid)
                                        .collection('diary_entries')
                                        .doc(entry.id)
                                        .update({
                                      'title': _titleController.text,
                                      'paragraph': _paragraphController.text,
                                      'text': _entryController.text,
                                      'editedAt': Timestamp.now(),
                                    });
                        
                                    setState(() {
                                      _editingIndex = null;
                                      _titleController.clear();
                                      _paragraphController.clear();
                                      _entryController.clear();
                                    });
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close,
                                      color: Colors.redAccent),
                                  onPressed: () {
                                    setState(() {
                                      _editingIndex = null;
                                      _titleController.clear();
                                      _paragraphController.clear();
                                      _entryController.clear();
                                    });
                                  },
                                ),
                              ] else ...[
                                IconButton(
                                  icon: const Icon(Icons.edit,
                                      color: Colors.white),
                                  onPressed: () {
                                    setState(() {
                                      _editingIndex = index;
                                      _titleController.text =
                                          entry['title'] ?? '';
                                      _paragraphController.text =
                                          entry['paragraph'] ?? '';
                                      _entryController.text =
                                          entry['text'] ?? '';
                                    });
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.white),
                                  onPressed: () async {
                                    await FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(FirebaseAuth
                                        .instance.currentUser!.uid)
                                        .collection('diary_entries')
                                        .doc(entry.id)
                                        .delete();
                                  },
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildTodoSection() {
    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .collection('todos')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }
          final todos = snapshot.data!.docs;

          return todos.isEmpty
              ? const Center(child: Text("No tasks yet.", style: TextStyle(color: Colors.teal)))
              : ListView.builder(
            itemCount: todos.length,
            itemBuilder: (context, index) {
              final todo = todos[index];
              return Card(
                color: Colors.teal,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: todo['done'],
                            onChanged: (bool? value) {
                              FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(FirebaseAuth.instance.currentUser!.uid)
                                  .collection('todos')
                                  .doc(todo.id)
                                  .update({'done': value});
                            },
                          ),
                          Expanded(
                            child: Text(
                              todo['task'],
                              style: TextStyle(
                                fontSize: 16,
                                color: todo['done'] ? Colors.grey : Colors.white,
                                decoration: todo['done']
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.white),
                            onPressed: () => _editTodoFirestore(todo),
                          ),
                          IconButton(
                            icon: const Icon(Icons.notifications, color: Colors.white),
                            onPressed: () => _setAlertFirestore(todo),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.white),
                            onPressed: () {
                              FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(FirebaseAuth.instance.currentUser!.uid)
                                  .collection('todos')
                                  .doc(todo.id)
                                  .delete();
                            },
                          ),
                        ],
                      ),
                      if (todo['alert'] != "")
                        Padding(
                          padding: const EdgeInsets.only(left: 50.0, top: 4),
                          child: Text(
                            "🕒 Alert: ${todo['alert']}",
                            style: const TextStyle(fontSize: 12, color: Colors.white70),
                          ),
                        ),
                    ],
                  ),
                ),
              );

            },
          );
        },
      ),
    );
  }}
