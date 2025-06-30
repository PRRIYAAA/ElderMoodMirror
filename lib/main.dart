import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Screens
import 'screens/user_info_screen.dart';
import 'screens/start_screen.dart';
import 'screens/survey_screen.dart';
import 'screens/chat_screen.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const ElderMoodMirrorApp());
}

class ElderMoodMirrorApp extends StatelessWidget {
  const ElderMoodMirrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Elder Mood Mirror',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: Colors.blueGrey[50],
        textTheme: const TextTheme(
          bodyMedium: TextStyle(fontSize: 18),
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: const EntryPoint(),
    );
  }
}

class EntryPoint extends StatefulWidget {
  const EntryPoint({super.key});

  @override
  State<EntryPoint> createState() => _EntryPointState();
}

class _EntryPointState extends State<EntryPoint> {
  bool _loading = true;
  bool _firstTime = true;

  @override
  void initState() {
    super.initState();
    _checkFirstTime();
  }

  Future<void> _checkFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    bool? isFirst = prefs.getBool('isFirstTime');
    setState(() {
      _firstTime = isFirst ?? true;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Show user info screen only on first launch
    if (_firstTime) {
      return const UserInfoScreen();
    }

    // Show StartScreen first, then survey screen
    return StartScreen(nextScreen: const SurveyScreen());
  }
}
