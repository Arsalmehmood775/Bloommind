import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:math';
import 'dart:async';

class MeditationScreen extends StatefulWidget {
  const MeditationScreen({Key? key}) : super(key: key);

  @override
  State<MeditationScreen> createState() => _MeditationScreenState();
}

class _MeditationScreenState extends State<MeditationScreen> with SingleTickerProviderStateMixin {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool isPlaying = false;
  String currentAudio = "";
  Duration duration = Duration.zero;
  Duration position = Duration.zero;

  int selectedTabIndex = 0;
  bool taskCompleted = false;

  final List<String> mindfulnessTasks = [
    "Take 10 deep breaths",
    "Sit still for 2 minutes",
    "Focus on the sounds around you",
    "Gently close your eyes and relax your shoulders",
    "Count backwards from 50 slowly",
  ];

  late String todayTask;

  final List<String> categories = ["Guided", "Music", "Sleep", "Breath"];

  final Map<String, List<Map<String, String>>> categorizedSessions = {
    "Guided": [
      {"title": "Morning Mindfulness", "audio": "sounds/guided/morning.mp3", "duration": "8 mins"},
      {"title": "Letting Go", "audio": "sounds/guided/letting_go.mp3", "duration": "10 mins"},
    ],
    "Music": [
      {"title": "Relaxing Waves", "audio": "sounds/music/waves.mp3", "duration": "10 mins"},
      {"title": "Peaceful Piano", "audio": "sounds/music/piano.mp3", "duration": "6 mins"},
    ],
    "Sleep": [
      {"title": "Deep Sleep", "audio": "sounds/sleep/deep_sleep.mp3", "duration": "20 mins"},
      {"title": "Night Calm", "audio": "sounds/sleep/night.mp3", "duration": "15 mins"},
    ],
    "Breath": [
      {"title": "Box Breathing", "audio": "sounds/breath/box.mp3", "duration": "5 mins"},
      {"title": "4-7-8 Breathing", "audio": "sounds/breath/478.mp3", "duration": "4 mins"},
    ],
  };

  @override
  void initState() {
    super.initState();

    // Random task each day based on day number
    final today = DateTime.now().day;
    todayTask = mindfulnessTasks[today % mindfulnessTasks.length];

    _audioPlayer.onDurationChanged.listen((d) => setState(() => duration = d));
    _audioPlayer.onPositionChanged.listen((p) => setState(() => position = p));
    _audioPlayer.onPlayerComplete.listen((_) {
      setState(() {
        isPlaying = false;
        position = Duration.zero;
      });
    });
  }

  void _playAudio(String path) async {
    if (currentAudio != path) {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource(path));
      setState(() {
        currentAudio = path;
        isPlaying = true;
      });
    } else {
      if (isPlaying) {
        await _audioPlayer.pause();
        setState(() => isPlaying = false);
      } else {
        await _audioPlayer.resume();
        setState(() => isPlaying = true);
      }
    }
  }

  void _seekAudio(Duration newPosition) async {
    await _audioPlayer.seek(newPosition);
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good morning 🌅";
    if (hour < 18) return "Good afternoon ☀️";
    return "Good evening 🌙";
  }

  @override
  Widget build(BuildContext context) {
    final currentCategory = categories[selectedTabIndex];
    final sessions = categorizedSessions[currentCategory]!;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Meditation for Mindfulness", style: TextStyle(color:Colors.white),),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.teal,
      ),
      body: Container(
        decoration: const BoxDecoration(
            color: Colors.white
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Text(_getGreeting(), style: TextStyle(fontSize: 18, color: Colors.teal,fontWeight: FontWeight.bold)),
            _buildDailyTaskCard(),
            _buildTabBar(),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: sessions.length,
                itemBuilder: (context, index) {
                  final session = sessions[index];
                  return _buildSessionTile(session["title"]!, session["audio"]!, session["duration"]!);
                },
              ),
            ),
            _buildAudioPlayerUI(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyTaskCard() {
    return Card(
      color: Colors.teal,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      child: ListTile(
        leading: Icon(Icons.today, color: Colors.white),
        title: Text("Today's Task", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text(todayTask, style: TextStyle(color: Colors.white70)),
        trailing: IconButton(
          icon: Icon(
            taskCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
            color: taskCompleted ? Colors.greenAccent : Colors.white54,
          ),
          onPressed: () => setState(() => taskCompleted = !taskCompleted),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(categories.length, (index) {
          return GestureDetector(
            onTap: () => setState(() => selectedTabIndex = index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: selectedTabIndex == index ? Colors.teal : Colors.white12,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                categories[index],
                style: TextStyle(
                  color: selectedTabIndex == index ? Colors.white : Colors.teal,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSessionTile(String title, String audioPath, String duration) {
    return Card(
      color: Colors.teal,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Icon(Icons.self_improvement, color: Colors.white),
        title: Text(title, style: TextStyle(color: Colors.white, fontSize: 18)),
        subtitle: Text(duration, style: TextStyle(color: Colors.white70)),
        trailing: IconButton(
          icon: Icon(
            isPlaying && currentAudio == audioPath ? Icons.pause_circle_filled : Icons.play_circle_filled,
            color: Colors.white,
            size: 30,
          ),
          onPressed: () => _playAudio(audioPath),
        ),
      ),
    );
  }

  Widget _buildAudioPlayerUI() {
    return currentAudio.isNotEmpty
        ? Column(
      children: [
        const SizedBox(height: 10),
        Text("Now Playing", style: TextStyle(color: Colors.teal)),
        Slider(
          value: position.inSeconds.toDouble(),
          min: 0,
          max: duration.inSeconds.toDouble(),
          onChanged: (value) => _seekAudio(Duration(seconds: value.toInt())),
          activeColor: Colors.teal,
          inactiveColor: Colors.teal,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_formatTime(position), style: TextStyle(color: Colors.white54)),
              Text(_formatTime(duration), style: TextStyle(color: Colors.white54)),
            ],
          ),
        ),
      ],
    )
        : const SizedBox.shrink();
  }

  String _formatTime(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }
}
