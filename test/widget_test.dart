// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: TestCounter()));

    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}

// 👇 This is just a local dummy widget for the test
class TestCounter extends StatefulWidget {
  @override
  _TestCounterState createState() => _TestCounterState();
}

class _TestCounterState extends State<TestCounter> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Counter Test')),
      body: Center(child: Text('$_count')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => setState(() => _count++),
        child: Icon(Icons.add),
      ),
    );
  }
}