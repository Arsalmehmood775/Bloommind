import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';

void main() => runApp(const BloomMindMiniGamesApp());

class BloomMindMiniGamesApp extends StatelessWidget {
  const BloomMindMiniGamesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BloomMind Mini Games',
      debugShowCheckedModeBanner: false,
      home: const GameMenu(),
    );
  }
}

class GameMenu extends StatelessWidget {
  const GameMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE0F7FA), Color(0xFFB2EBF2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [

                      Text("Hello, 👋",
                          style: TextStyle(fontSize: 40, fontWeight: FontWeight.w600,color: Colors.teal)),
                      Text("Choose a game to relax",
                          style: TextStyle(fontSize: 20, color: Colors.teal)),
                    ],
                  )
                ],
              ),
              const SizedBox(height: 20),
              _buildButton(context, " Candy Calm Carve", const ShapeSelectionScreen(), Icons.cookie),
              _buildButton(context, " Ripple Zen", const RippleZenScreen(), Icons.waves),
              _buildButton(context, " Unlock Calm", const UnlockCalmGame(), Icons.lock_open),
              _buildButton(context, " Freeze the Panic", const FreezeThePanicGame(), Icons.ac_unit),
              _buildButton(context, " Mood Painter", const MoodPainterScreen(), Icons.brush),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButton(BuildContext context, String title, Widget screen, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: SizedBox(
        height: 110,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color.fromARGB(200, 245, 202, 29), Color.fromARGB(255, 250, 150, 10)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.all(Radius.circular(50)),
          ),
          child: ElevatedButton.icon(
            icon: Icon(icon, size: 20, color: Colors.white),
            label: Text(title),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              shadowColor: Colors.transparent,
              minimumSize: const Size(double.infinity, 60),
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
              elevation: 3,
            ),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => WillPopScope(
                  onWillPop: () async {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const GameMenu()),
                          (route) => false,
                    );
                    return false;
                  },
                  child: screen,
                ),
              ),
            ),
          ),
        ),
      )
    );
  }
}

// GAME 1
class CandyCalmCarveApp extends StatelessWidget {
  const CandyCalmCarveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Candy Calm Carve',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const ShapeSelectionScreen(),
    );
  }
}

class ShapeSelectionScreen extends StatelessWidget {
  const ShapeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final shapes = ['Circle', 'Star', 'Heart', 'Umbrella',];
    return Scaffold(
      appBar: AppBar(title: const Text('Candy Calm Carve')),
      backgroundColor: Colors.brown.shade100,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 30,
              crossAxisSpacing: 20,
              childAspectRatio: 1,
              shrinkWrap: true,
              children: List.generate(shapes.length, (index) {
                return ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    backgroundColor: Colors.orange.shade100,
                    foregroundColor: Colors.brown.shade800,
                    textStyle: const TextStyle(fontSize: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CarvingScreen(shape: shapes[index]),
                      ),
                    );
                  },
                  child: Text("Carve ${shapes[index]}"),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class CarvingScreen extends StatefulWidget {
  final String shape;
  const CarvingScreen({super.key, required this.shape});

  @override
  State<CarvingScreen> createState() => _CarvingScreenState();
}

class _CarvingScreenState extends State<CarvingScreen> {
  List<Offset> userPath = [];
  late Path targetPath;
  final AudioPlayer _player = AudioPlayer();

  @override
  void initState() {
    super.initState();
    targetPath = getShapePath(widget.shape);
    _player.setReleaseMode(ReleaseMode.loop);
    _player.play(AssetSource('sounds/ambience.mp3'));
  }

  Path getShapePath(String shape) {
    final Path path = Path();
    switch (shape) {
      case 'Circle':
        path.addOval(Rect.fromCircle(center: Offset(200, 300), radius: 100));
        break;
      case 'Star':
        const int points = 5;
        final double radius = 100;
        final double innerRadius = 50;
        final center = const Offset(200, 300);
        for (int i = 0; i < points * 2; i++) {
          double angle = i * pi / points;
          double r = i.isEven ? radius : innerRadius;
          double x = center.dx + r * cos(angle);
          double y = center.dy + r * sin(angle);
          if (i == 0) {
            path.moveTo(x, y);
          } else {
            path.lineTo(x, y);
          }
        }
        path.close();
        break;
      case 'Heart':
        path.moveTo(200, 300);
        path.cubicTo(200, 250, 150, 250, 150, 300);
        path.cubicTo(150, 350, 200, 375, 200, 400);
        path.cubicTo(200, 375, 250, 350, 250, 300);
        path.cubicTo(250, 250, 200, 250, 200, 300);
        path.close();
        break;
      case 'Umbrella':
        path.moveTo(120, 300);
        path.quadraticBezierTo(200, 200, 280, 300);
        path.lineTo(120, 300);
        path.moveTo(200, 300);
        path.lineTo(200, 400);
        break;
    }
    return path;
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      userPath.add(details.localPosition);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      userPath.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.brown.shade50,
      appBar: AppBar(
        title: Text("Carving: ${widget.shape}"),
        backgroundColor: Colors.brown,
      ),
      body: GestureDetector(
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        child: CustomPaint(
          painter: CarvePainter(userPath: userPath, target: targetPath),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class CarvePainter extends CustomPainter {
  final List<Offset> userPath;
  final Path target;

  CarvePainter({required this.userPath, required this.target});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.orange
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;

    final userPaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    canvas.drawPath(target, paint);

    final path = Path();
    if (userPath.isNotEmpty) {
      path.moveTo(userPath[0].dx, userPath[0].dy);
      for (var point in userPath) {
        path.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(path, userPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}



//GAME 2
class RippleZenApp extends StatelessWidget {
  const RippleZenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ripple Zen',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(),
      home: const RippleZenScreen(),
    );
  }
}

class RippleZenScreen extends StatefulWidget {
  const RippleZenScreen({super.key});

  @override
  State<RippleZenScreen> createState() => _RippleZenScreenState();
}

class _RippleZenScreenState extends State<RippleZenScreen>
    with SingleTickerProviderStateMixin {
  List<Ripple> ripples = [];

  void _addRipple(Offset position) {
    setState(() {
      ripples.add(Ripple(position));
    });
  }

  @override
  void initState() {
    super.initState();
    Timer.periodic(const Duration(milliseconds: 30), (timer) {
      setState(() {
        ripples.removeWhere((r) => r.radius > 150);
        for (var ripple in ripples) {
          ripple.update();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        title: const Text("Ripple Zen"),
        backgroundColor: Colors.blue.shade300,
      ),
      body: GestureDetector(
        onTapDown: (details) => _addRipple(details.localPosition),
        child: CustomPaint(
          painter: RipplePainter(ripples),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class Ripple {
  Offset center;
  double radius;
  double opacity;

  Ripple(this.center)
      : radius = 0,
        opacity = 1.0;

  void update() {
    radius += 3;
    opacity -= 0.02;
    if (opacity < 0) opacity = 0;
  }
}

class RipplePainter extends CustomPainter {
  final List<Ripple> ripples;

  RipplePainter(this.ripples);

  @override
  void paint(Canvas canvas, Size size) {
    for (var ripple in ripples) {
      final paint = Paint()
        ..color = Colors.blue.withOpacity(ripple.opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;

      canvas.drawCircle(ripple.center, ripple.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}



class BowlSelectionDialog extends StatelessWidget {
  final void Function(int index) onSelect;

  const BowlSelectionDialog({super.key, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Select Bowl"),
      content: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(3, (index) {
          return ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onSelect(index);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan.shade300),
            child: Text("Bowl ${index + 1}"),
          );
        }),
      ),
    );
  }
}





//GAME 3
class UnlockCalmGame extends StatefulWidget {
  const UnlockCalmGame({super.key});

  @override
  State<UnlockCalmGame> createState() => _UnlockCalmGameState();
}

class _UnlockCalmGameState extends State<UnlockCalmGame> {
  final List<int> _pattern = [];
  final List<int> _userInput = [];
  final int _gridSize = 3;
  int _level = 1;
  bool _showPattern = false;
  int _currentPatternIndex = 0;
  Timer? _patternTimer;
  String _message = "Tap Lock to Begin";

  @override
  void dispose() {
    _patternTimer?.cancel();
    super.dispose();
  }

  void _generatePattern() {
    _pattern.clear();
    final rand = Random();
    for (int i = 0; i < _level + 2; i++) {
      _pattern.add(rand.nextInt(_gridSize * _gridSize));
    }
  }

  void _showPatternSequence() {
    _userInput.clear();
    setState(() {
      _showPattern = true;
      _currentPatternIndex = 0;
      _message = "Watch the Pattern";
    });

    _patternTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_currentPatternIndex >= _pattern.length) {
        timer.cancel();
        setState(() {
          _showPattern = false;
          _message = "Repeat the Pattern";
        });
      } else {
        setState(() {
          _currentPatternIndex++;
        });
      }
    });
  }

  void _handleTap(int index) {
    if (_showPattern) return;

    _userInput.add(index);
    final correct = _pattern.take(_userInput.length).toList();

    if (_userInput.last != correct.last) {
      _message = "Oops! Try Again";
      _userInput.clear();
      return;
    }

    if (_userInput.length == _pattern.length) {
      setState(() {
        _level++;
        _message = "Unlocked! 🌟";
      });

      Future.delayed(const Duration(seconds: 2), () {
        _generatePattern();
        _showPatternSequence();
      });
    } else {
      setState(() {});
    }
  }

  Widget _buildGridTile(int index) {
    final isActive = _showPattern &&
        _currentPatternIndex > 0 &&
        index == _pattern[_currentPatternIndex - 1];

    return GestureDetector(
      onTap: () => _handleTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isActive
              ? Colors.lightBlueAccent
              : Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white54),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo.shade900,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Center(
              child: Text(
                "Unlock Calm",
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.white.withOpacity(0.9),
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _message,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                _generatePattern();
                _showPatternSequence();
              },
              child: Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.lightBlue,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white30,
                      blurRadius: 15,
                      spreadRadius: 5,
                    )
                  ],
                ),
                child: const Icon(Icons.lock_open, color: Colors.white),
              ),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(20),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: _gridSize,
                ),
                itemCount: _gridSize * _gridSize,
                itemBuilder: (_, index) => _buildGridTile(index),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Level: $_level",
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}






//GAME 4
class FreezeThePanicGame extends StatefulWidget {
  const FreezeThePanicGame({super.key});

  @override
  State<FreezeThePanicGame> createState() => _FreezeThePanicGameState();
}

class _FreezeThePanicGameState extends State<FreezeThePanicGame> {
  List<_PanicSpike> _spikes = [];
  late Timer _spawnTimer;
  late Timer _updateTimer;
  int _score = 0;
  bool _gameOver = false;

  @override
  void initState() {
    super.initState();
    _startGame();
  }

  void _startGame() {
    _spikes.clear();
    _score = 0;
    _gameOver = false;

    _spawnTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _spikes.add(_PanicSpike(
          x: Random().nextDouble() * 300,
          y: 600,
          id: UniqueKey(),
        ));
      });
    });

    _updateTimer = Timer.periodic(const Duration(milliseconds: 30), (_) {
      setState(() {
        for (final spike in _spikes) {
          spike.y -= 3;
        }

        // Check if any spike hit top
        if (_spikes.any((s) => s.y <= 50)) {
          _gameOver = true;
          _spawnTimer.cancel();
          _updateTimer.cancel();
        }

        _spikes.removeWhere((s) => s.frozen);
      });
    });
  }

  void _freezeSpike(Key id) {
    setState(() {
      final index = _spikes.indexWhere((s) => s.id == id);
      if (index != -1) {
        _spikes[index].frozen = true;
        _score++;
      }
    });
  }

  @override
  void dispose() {
    _spawnTimer.cancel();
    _updateTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _gameOver
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.warning_amber_rounded, size: 80, color: Colors.redAccent),
            const SizedBox(height: 20),
            const Text("You let panic rise too high!", style: TextStyle(color: Colors.white, fontSize: 18)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _startGame,
              child: const Text("Try Again"),
            ),
          ],
        ),
      )
          : Stack(
        children: [
          ..._spikes.map((spike) {
            return Positioned(
              left: spike.x,
              top: spike.y,
              child: GestureDetector(
                onTap: () => _freezeSpike(spike.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 25,
                  height: 40,
                  decoration: BoxDecoration(
                    color: spike.frozen ? Colors.blueAccent : Colors.redAccent,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: spike.frozen
                            ? Colors.lightBlueAccent.withOpacity(0.4)
                            : Colors.redAccent.withOpacity(0.4),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
          Positioned(
            top: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                "Freeze the Panic",
                style: TextStyle(fontSize: 22, color: Colors.white.withOpacity(0.9), letterSpacing: 2),
              ),
            ),
          ),
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: Text("Score: $_score", style: const TextStyle(color: Colors.white, fontSize: 20)),
            ),
          ),
        ],
      ),
    );
  }
}

class _PanicSpike {
  final double x;
  double y;
  bool frozen = false;
  final Key id;

  _PanicSpike({required this.x, required this.y, required this.id});
}






//GAME 5
class MoodPainterApp extends StatelessWidget {
  const MoodPainterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mood Painter',
      debugShowCheckedModeBanner: false,
      home: const MoodPainterScreen(),
    );
  }
}

class MoodPainterScreen extends StatefulWidget {
  const MoodPainterScreen({super.key});

  @override
  State<MoodPainterScreen> createState() => _MoodPainterScreenState();
}

class _MoodPainterScreenState extends State<MoodPainterScreen> {
  List<DrawnPoint> points = [];
  Color selectedColor = Colors.purple;
  double brushSize = 10;
  bool isEraser = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: isEraser ? Colors.grey : selectedColor,
        title: const Text('Mood Painter 🎨'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => points.clear());
            },
          ),
          IconButton(
            icon: Icon(isEraser ? Icons.brush : Icons.cleaning_services),
            onPressed: () {
              setState(() => isEraser = !isEraser);
            },
            tooltip: isEraser ? 'Switch to Brush' : 'Switch to Eraser',
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              GestureDetector(
                onPanUpdate: (details) {
                  RenderBox renderBox = context.findRenderObject() as RenderBox;
                  Offset localPosition = renderBox.globalToLocal(details.globalPosition);
                  setState(() {
                    points.add(
                      DrawnPoint(
                        localPosition.translate(0, -brushSize / 2), // correct offset alignment
                        isEraser ? Colors.grey.shade100 : selectedColor,
                        brushSize,
                      ),
                    );
                  });
                },
                onPanEnd: (_) => points.add(DrawnPoint(Offset.zero, Colors.transparent, 0)),
                child: CustomPaint(
                  painter: MoodPainter(points),
                  child: const SizedBox.expand(),
                ),
              ),
              Positioned(
                bottom: 20,
                left: 10,
                right: 10,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: _buildColorOptions(),
                    ),
                    const SizedBox(height: 10),
                    Slider(
                      value: brushSize,
                      min: 5,
                      max: 40,
                      activeColor: selectedColor,
                      onChanged: (value) {
                        setState(() => brushSize = value);
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildColorOptions() {
    List<Color> colors = [
      Colors.purple,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.red,
      Colors.pink,
      Colors.black,
    ];
    return colors.map((c) {
      return GestureDetector(
        onTap: () => setState(() {
          selectedColor = c;
          isEraser = false;
        }),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 6),
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: c,
            shape: BoxShape.circle,
            border: Border.all(
              color: selectedColor == c && !isEraser ? Colors.white : Colors.grey.shade300,
              width: 3,
            ),
          ),
        ),
      );
    }).toList();
  }
}

class DrawnPoint {
  final Offset point;
  final Color color;
  final double size;

  DrawnPoint(this.point, this.color, this.size);
}

class MoodPainter extends CustomPainter {
  final List<DrawnPoint> points;

  MoodPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i].color == Colors.transparent || points[i + 1].color == Colors.transparent) continue;
      final paint = Paint()
        ..color = points[i].color.withOpacity(0.5)
        ..strokeCap = StrokeCap.round
        ..strokeWidth = points[i].size;
      canvas.drawLine(points[i].point, points[i + 1].point, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
