import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'start_screen.dart';
import 'survey_history_screen.dart';

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

  Future<String> _writeActiveInputsJson(Map<String, dynamic> data) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/active_inputs.json');
    await file.writeAsString(jsonEncode(data));
    return file.path;
  }

  Future<bool> sendToPythonServer({
    required List<Map<String, String>> dailyLogs,
    required List<Map<String, String>> cameraLogs,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final guardianEmail = prefs.getString('guardian_email') ?? '';
      final userName = prefs.getString('user_name') ?? '';
      final clinicEmail = prefs.getString('clinic_email') ?? '';

      final activeInputs = {
        'daily_logs': dailyLogs,
        'camera_moods': cameraLogs,
        'guardian_email': guardianEmail,
        'clinic_email': clinicEmail,
        'user_name': userName,
      };

      await prefs.setString('active_inputs', jsonEncode(activeInputs));
      await _writeActiveInputsJson(activeInputs);

      // Using a placeholder address, ensure this is correct
      final response = await http.post(
        Uri.parse("http://192.168.1.6:5000/analyze"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(activeInputs),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['status'] == 'success') {
          print("✅ Sent to Python server with active_inputs.json");
          print("Dominant Mood: ${result['dominant_mood']}");
          return true;
        } else {
          print("❌ Server error: ${result['message']}");
        }
      } else {
        print("❌ HTTP ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Exception sending to server: $e");
    }
    return false;
  }

  String get category {
    if (disability == 'Bedridden') return 'Bedridden';
    // Check for non-null and non-empty tabletName
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
      history = (jsonDecode(existingData) as List)
          .map((e) => Map<String, String>.from(e))
          .toList();
    }

    history.add(Map<String, String>.from(responses));

    if (history.length >= 7) {
      print("📬 7 days collected. Sending to server...");
      final activeJson = prefs.getString('active_inputs');
      final Map<String, dynamic> activeInputs =
      activeJson != null ? jsonDecode(activeJson) : {};

      final cameraMoodsRaw = activeInputs['camera_moods'];
      final List<Map<String, String>> cameraMoods = [];

      if (cameraMoodsRaw != null && cameraMoodsRaw is List) {
        for (var item in cameraMoodsRaw) {
          if (item is Map) {
            cameraMoods.add(
                item.map((k, v) => MapEntry(k.toString(), v.toString())));
          }
        }
      }

      if (cameraMoods.isNotEmpty && history.isNotEmpty) {
        bool sent = await sendToPythonServer(dailyLogs: history, cameraLogs: cameraMoods);

        if (sent) {
          // ✅ Only clear history if sending succeeded
          await prefs.remove('survey_history');
          await prefs.remove('mood_history');
          print("✅ Data sent successfully. Cleared survey and camera mood history.");
        } else {
          print("⚠ Data not sent — keeping local history for retry.");
        }
      }
      else {
        print("⛔ Cannot send to server. Missing one of the inputs.");
        if (cameraMoods.isEmpty) print("⚠ Camera moods missing.");
        if (history.isEmpty) print("⚠ Daily logs missing.");
      }
    } else {
      await prefs.setString('survey_history', jsonEncode(history));
      print("📝 Collected day ${history.length}/7. Waiting for full week.");
    }

    setState(() => responses.clear());

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Survey submitted!")),
    );

    // Navigate back to StartScreen after submission
    Future.delayed(const Duration(seconds: 1), () {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          // Navigating to StartScreen with nextScreen set to SurveyScreen itself 
          // allows the StartScreen's internal logic to determine the next action 
          // (or just show the main buttons).
          builder: (_) => const StartScreen(nextScreen: SurveyScreen(), showQuoteOnEntry: false),
        ),
            (route) => false,
      );
    });
  }

  // --- Widget for a single question with Card styling and new wording ---
  Widget _buildQuestion(String key, String question, List<String> options, String emoji) {
    if (!requiredKeys.contains(key)) requiredKeys.add(key);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 8, bottom: 4),
              child: Text(
                "$emoji $question",
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.teal
                ),
              ),
            ),
            ...options.map(
                  (opt) => RadioListTile<String>(
                dense: true,
                title: Text(opt, style: const TextStyle(fontSize: 15)),
                value: opt,
                groupValue: responses[key],
                activeColor: Colors.teal,
                onChanged: (val) => setState(() => responses[key] = val!),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> getQuestionWidgets() {
    requiredKeys.clear(); // Clear to rebuild the list accurately

    List<Widget> q = [];

    // Core Questions (Formalized)
    q.addAll([
      _buildQuestion("breakfast", "Did you consume breakfast?", ["Yes", "No"], "🍽"),
      _buildQuestion("lunch", "Did you consume lunch?", ["Yes", "No"], "🍱"),
      _buildQuestion("dinner", "Did you consume dinner?", ["Yes", "No"], "🍛"),
      _buildQuestion("exercise", "Did you engage in physical activity today?", ["Yes", "No"], "🏃"),
    ]);

    if (category == 'Normal') {
      q.addAll([
        _buildQuestion("medicine", "Did you require/take any medication today?", [
          "No medication required",
          "Yes, for minor symptoms/issues",
          "Yes, for severe issues (Doctor consulted)"
        ], "💊"),
        _buildQuestion("sleep", "How would you rate last night's sleep quality?",
            ["Good", "Average", "Poor"], "😴"),
        _buildQuestion("mood", "Which word best describes your mood today?",
            ["Happy", "Calm", "Anxious", "Sad"], "😊"),
        _buildQuestion("water", "Was your daily water intake sufficient?",
            ["Yes", "No"], "💧"),
        _buildQuestion("social", "Did you engage in social interaction today?",
            ["Yes", "No"], "👥"),
        _buildQuestion("energy", "How would you describe your energy level today?",
            ["High", "Average/Okay", "Low"], "💪"),
        _buildQuestion("pain", "Did you experience any pain today?",
            ["No pain", "Mild discomfort", "Moderate pain"], "💔"),
      ]);
    } else if (category == 'Normal & Medication') {
      q.addAll([
        _buildQuestion("medicine", "Did you take your prescribed medication?",
            ["Yes", "No"], "💊"),
        _buildQuestion("dose", "Was the medication taken at the correct time and dose?",
            ["Yes", "No"], "⏱"),
        _buildQuestion("sleep", "How would you rate last night's sleep quality?",
            ["Good", "Average", "Poor"], "😴"),
        _buildQuestion("mood", "Which word best describes your mood today?",
            ["Happy", "Calm", "Anxious", "Sad"], "😊"),
        _buildQuestion("water", "Was your daily water intake sufficient?",
            ["Yes", "No"], "💧"),
        _buildQuestion("social", "Did you engage in social interaction today?",
            ["Yes", "No"], "👥"),
        _buildQuestion("energy", "How would you describe your energy level today?",
            ["High", "Average/Okay", "Low"], "💪"),
        _buildQuestion("pain", "Did you experience any pain today?",
            ["No pain", "Mild discomfort", "Moderate pain"], "💔"),
      ]);
    } else if (category == 'Bedridden') {
      q.addAll([
        _buildQuestion("bed_comfort", "Are you comfortable in your current bed position?",
            ["Yes, comfortable", "Need positional support", "No, uncomfortable"], "🛌"),
        _buildQuestion("medicine",
            "Did you take your prescribed medication (while bedridden)?", ["Yes", "No"], "💊"),
        _buildQuestion("sleep", "How would you rate last night's sleep quality?",
            ["Good", "Average", "Poor"], "😴"),
        _buildQuestion("mood", "Which word best describes your mood today?",
            ["Happy", "Calm", "Anxious", "Sad"], "😊"),
        _buildQuestion("water", "Was your daily water intake sufficient?",
            ["Yes", "No"], "💧"),
        _buildQuestion("social", "Did you engage in social interaction today?",
            ["Yes", "No"], "👥"),
        _buildQuestion("energy", "How would you describe your energy level today?",
            ["High", "Average/Okay", "Low"], "💪"),
        _buildQuestion("pain", "Did you experience any pain today?",
            ["No pain", "Mild discomfort", "Moderate pain"], "💔"),
      ]);
    }
    return q;
  }

  @override
  Widget build(BuildContext context) {
    if (disability == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50, // Lighter background for professional look
      appBar: AppBar(
        backgroundColor: Colors.teal,
        title: const Text("Daily Well-being Check"), // More formal title
        centerTitle: true,
        // --- Added Back Button ---
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Navigate back to the StartScreen
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const StartScreen(nextScreen: SurveyScreen(), showQuoteOnEntry: false)),
                  (route) => false,
            );
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Informational header
            Padding(
              padding: const EdgeInsets.only(bottom: 20, top: 8),
              child: Text(
                "Please complete the following daily questionnaire:",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.teal.shade800,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            // --- Question Widgets ---
            ...getQuestionWidgets(),

            const SizedBox(height: 10),

            // --- Action Buttons ---
            ElevatedButton.icon(
              icon: const Icon(Icons.history, color: Colors.white),
              label: const Text("Review Past Submissions", style: TextStyle(color: Colors.white)),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SurveyHistoryScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal.shade700,
                padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                label: const Text("Submit Daily Report", style: TextStyle(fontSize: 18, color: Colors.white)),
                onPressed: _submitSurvey,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 5,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}