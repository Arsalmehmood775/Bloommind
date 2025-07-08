import 'package:flutter/material.dart';
import 'dart:math';

class QuotePage extends StatefulWidget {
  const QuotePage({super.key});

  @override
  State<QuotePage> createState() => _QuotePageState();
}

class _QuotePageState extends State<QuotePage> {
  final List<String> _quotes = [
    "Believe in yourself and all that you are.",
    "You are stronger than you think.",
    "Every day is a second chance.",
    "Push yourself, because no one else is going to do it for you.",
    "Difficult roads often lead to beautiful destinations.",
    "Take a deep breath and keep moving forward.",
    "Start where you are. Use what you have. Do what you can.",
    "Your only limit is your mind.",
    "One small positive thought in the morning can change your whole day.",
  ];

  late String _currentQuote;

  @override
  void initState() {
    super.initState();
    _currentQuote = _getRandomQuote();
  }

  String _getRandomQuote() {
    return _quotes[Random().nextInt(_quotes.length)];
  }

  void _refreshQuote() {
    setState(() {
      _currentQuote = _getRandomQuote();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF009A94),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Daily Motivation',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 30),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 12,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.format_quote_rounded, size: 40, color: Color(0xFF009A94)),
                      const SizedBox(height: 20),
                      Text(
                        _currentQuote,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20,
                          fontStyle: FontStyle.italic,
                          color: Colors.black87,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                ElevatedButton.icon(
                  onPressed: _refreshQuote,
                  icon: const Icon(Icons.refresh),
                  label: const Text("New Quote"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF009A94),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 5,
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
