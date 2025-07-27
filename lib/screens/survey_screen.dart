import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'start_screen.dart';
import 'survey_history_screen.dart';
import 'package:http/http.dart' as http; // Add this at the top if not already
class SurveyScreen extends StatefulWidget {
  const SurveyScreen({Key? key}) : super(key: key);

  @override
  State<SurveyScreen> createState() => _SurveyScreenState();
}

class _SurveyScreenState extends State<SurveyScreen> {
  final Map<String, String> responses = {};
  final List<String> requiredKeys = [];
  String? disability;
  String? tabletName;
  String? recordedAudioPath;

  @override
  void initState() {
    super.initState();
    loadUserCategory();
  }

  Future<void> loadUserCategory() async {
    final prefs = await SharedPreferences.getInstance();
    disability = prefs.getString('user_disability') ?? 'None';
    tabletName = prefs.getString('tablet_name') ?? '';
    setState(() {});
  }

  String get category {
    if (disability == 'Bedridden') return 'Bedridden';
    if (tabletName != null && tabletName!.isNotEmpty && disability == 'None') {
      return 'Normal & Medication';
    }
    return 'Normal';
  }

  void _goToVoiceRecordingPage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VoiceRecordingScreen(),
      ),
    );

    if (result != null && result is String) {
      setState(() {
        recordedAudioPath = result;
      });


      _submitSurvey(); // ✅ Now submit with voice_mood, voice_text, voice_score
    }
  }
  void _submitSurvey() async {
    for (String key in requiredKeys) {
      if (!responses.containsKey(key) || responses[key]!.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please answer all questions")),
        );
        return;
      }
    }

    final prefs = await SharedPreferences.getInstance();
    String? existingData = prefs.getString('survey_history');
    List<Map<String, String>> history = [];

    if (existingData != null) {
      List<dynamic> decoded = jsonDecode(existingData);
      history = decoded.map((e) => Map<String, String>.from(e)).toList();
    }

    Map<String, String> fullResponse = Map.from(responses);
    if (recordedAudioPath != null) {
      fullResponse['voice_clip'] = recordedAudioPath!;
    }

    history.add(fullResponse);
    if (history.length > 7) {
      history = history.sublist(history.length - 7);
    }

    await prefs.setString('survey_history', jsonEncode(history));

    print("📋 Survey Submitted. 7-Day History:");
    for (int i = 0; i < history.length; i++) {
      print("Day ${i + 1}: ${history[i]}");
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Survey with voice submitted!")),
    );

    Future.delayed(const Duration(seconds: 1), () {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => StartScreen(nextScreen: const SurveyScreen())),
            (route) => false,
      );
    });
  }

  Widget _buildQuestion(String key, String question, List<String> options) {
    if (!requiredKeys.contains(key)) requiredKeys.add(key);

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(question, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ...options.map((opt) => RadioListTile<String>(
            title: Text(opt),
            value: opt,
            groupValue: responses[key],
            onChanged: (val) => setState(() => responses[key] = val!),
          )),
        ],
      ),
    );
  }

  List<Widget> getQuestionWidgets() {
    List<Widget> questions = [];

    questions.addAll([
      _buildQuestion("breakfast", "🍽 Did you eat breakfast?", ["Yes", "No"]),
      _buildQuestion("lunch", "🍱 Did you eat lunch?", ["Yes", "No"]),
      _buildQuestion("dinner", "🍛 Did you eat dinner?", ["Yes", "No"]),
      _buildQuestion("exercise", "🏃 Did you do any exercise today?", ["Yes", "No"]),
    ]);

    if (category == 'Normal') {
      questions.addAll([
        _buildQuestion("medicine", "💊 Did you take any medicine today?", [
          "No medicine",
          "Yes, few health issues today",
          "Severe checked with doctor"
        ]),
        _buildQuestion("sleep", "😴 Did you sleep well last night?", ["Good", "Average", "Poor"]),
        _buildQuestion("mood", "😊 How is your mood today?", ["Happy", "Calm", "Anxious", "Sad"]),
        _buildQuestion("water", "💧 Did you drink enough water today?", ["Yes", "No"]),
        _buildQuestion("social", "👥 Did you speak to someone today?", ["Yes", "No"]),
        _buildQuestion("energy", "💪 How was your energy today?", ["High", "Okay", "Low"]),
        _buildQuestion("pain", "❤ Any pain today?", ["No pain", "Mild", "Moderate"]),
      ]);
    } else if (category == 'Normal & Medication') {
      questions.addAll([
        _buildQuestion("medicine", "💊 Did you take your tablets today?", ["Yes", "No"]),
        _buildQuestion("dose", "⏱ Was it the correct time and dose?", ["Yes", "No"]),
        _buildQuestion("sleep", "😴 Did you sleep well last night?", ["Good", "Average", "Poor"]),
        _buildQuestion("mood", "😊 How is your mood today?", ["Happy", "Calm", "Anxious", "Sad"]),
        _buildQuestion("water", "💧 Did you drink enough water today?", ["Yes", "No"]),
        _buildQuestion("social", "👥 Did you speak to someone today?", ["Yes", "No"]),
        _buildQuestion("energy", "💪 How was your energy today?", ["High", "Okay", "Low"]),
        _buildQuestion("pain", "❤ Any pain today?", ["No pain", "Mild", "Moderate"]),
      ]);
    } else if (category == 'Bedridden') {
      questions.addAll([
        _buildQuestion("bed_comfort", "🛌 Are you comfortable in bed?", ["Yes", "Need support", "No"]),
        _buildQuestion("medicine", "💊 Did you take your tablets today (in bed)?", ["Yes", "No"]),
        _buildQuestion("sleep", "😴 Did you sleep well last night?", ["Good", "Average", "Poor"]),
        _buildQuestion("mood", "😊 How is your mood today?", ["Happy", "Calm", "Anxious", "Sad"]),
        _buildQuestion("water", "💧 Did you drink enough water today?", ["Yes", "No"]),
        _buildQuestion("social", "👥 Did you speak to someone today?", ["Yes", "No"]),
        _buildQuestion("energy", "💪 How was your energy today?", ["High", "Okay", "Low"]),
        _buildQuestion("pain", "❤ Any pain today?", ["No pain", "Mild", "Moderate"]),
      ]);
    }

    return questions;
  }

  @override
  Widget build(BuildContext context) {
    if (disability == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.teal.shade50,
      appBar: AppBar(
        backgroundColor: Colors.teal,
        title: const Text("Daily Mood Survey"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...getQuestionWidgets(),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.history),
              label: const Text("View Past Reports"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SurveyHistoryScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal.shade700,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.mic),
                label: const Text("Record Voice & Submit", style: TextStyle(fontSize: 18)),
                onPressed: _goToVoiceRecordingPage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

// --------------- Voice Recording Screen ---------------
class VoiceRecordingScreen extends StatefulWidget {
  const VoiceRecordingScreen({Key? key}) : super(key: key);

  @override
  State<VoiceRecordingScreen> createState() => _VoiceRecordingScreenState();
}

class _VoiceRecordingScreenState extends State<VoiceRecordingScreen> {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  String? _path;
  bool isRecording = false;
  Timer? _timer;
  int _secondsLeft = 60;

  @override
  void initState() {
    super.initState();
    initRecorder();
  }

  Future<void> initRecorder() async {
    await Permission.microphone.request();
    await _recorder.openRecorder();
    Directory tempDir = await getTemporaryDirectory();
    _path = '${tempDir.path}/voice_clip.aac';
    setState(() {});
  }

  void startRecording() async {
    await _recorder.startRecorder(toFile: _path);
    setState(() => isRecording = true);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _secondsLeft--);
      if (_secondsLeft == 0) stopRecording();
    });
  }

  void stopRecording() async {
    await _recorder.stopRecorder();
    _timer?.cancel();
    Navigator.pop(context, _path);
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("🎤 Record Your Voice")),
      body: Center(
        child: isRecording
            ? Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Recording..."),
            const SizedBox(height: 20),
            Text("⏱ $_secondsLeft seconds left", style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.stop),
              label: const Text("Stop Now"),
              onPressed: stopRecording,
            )
          ],
        )
            : ElevatedButton.icon(
          icon: const Icon(Icons.mic),
          label: const Text("Start Recording"),
          onPressed: startRecording,
        ),
      ),
    );
  }
}