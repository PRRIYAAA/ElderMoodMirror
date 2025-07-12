import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'start_screen.dart';
import 'survey_history_screen.dart';
import 'package:http/http.dart' as http;

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

  Future<bool> sendToPythonServer(List<Map<String, String>> history) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final guardianEmail = prefs.getString('guardian_email') ?? '';
      final userName = prefs.getString('user_name') ?? '';
      final clinicEmail = prefs.getString('clinic_email') ?? '';

      final response = await http.post(
        Uri.parse("http://192.168.1.6:5000/analyze"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'daily_logs': history,
          'guardian_email': guardianEmail,
          'clinic_email': clinicEmail,
          'user_name': userName,
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['status'] == 'success') {
          print("✅ Sent to Python server");
          print("Dominant Mood: ${result['dominant_mood']}");
          print("Suggestions:");
          for (var s in result['suggestions']) {
            print("- $s");
          }
          return true; // Success
        } else {
          print("❌ Server error: ${result['message']}");
        }
      } else {
        print("❌ Server responded with: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Exception sending to server: $e");
    }
    return false; // Failed
  }


  String get category {
    if (disability == 'Bedridden') return 'Bedridden';
    if (tabletName != null && tabletName!.isNotEmpty && disability == 'None') {
      return 'Normal & Medication';
    }
    return 'Normal';
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

    history.add(Map<String, String>.from(responses));

    if (history.length >= 7) {
      print("📬 7 days of data collected. Sending to Python server...");
      await sendToPythonServer(history);
      await prefs.remove('survey_history'); // Reset after sending
      print("✅ Cleared 7-day survey history after sending.");
    } else {
      await prefs.setString('survey_history', jsonEncode(history));
      print("📝 Collected day ${history.length}/7. Waiting for full week.");
    }

    // Reset all selected answers
    setState(() {
      responses.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Survey submitted!")),
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
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.send),
                label: const Text("Submit", style: TextStyle(fontSize: 18)),
                onPressed: _submitSurvey,
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
