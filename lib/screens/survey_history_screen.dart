import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'survey_history_screen.dart'; // <-- Add this


class SurveyHistoryScreen extends StatefulWidget {
  const SurveyHistoryScreen({Key? key}) : super(key: key);

  @override
  State<SurveyHistoryScreen> createState() => _SurveyHistoryScreenState();
}

class _SurveyHistoryScreenState extends State<SurveyHistoryScreen> {
  List<Map<String, String>> surveyHistory = [];

  @override
  void initState() {
    super.initState();
    loadSurveyHistory();
  }

  Future<void> loadSurveyHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('survey_history');
    if (data != null) {
      final decoded = jsonDecode(data) as List;
      setState(() {
        surveyHistory =
            decoded.map((item) => Map<String, String>.from(item)).toList();
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Past Survey Reports"),
        backgroundColor: Colors.teal,
      ),
      body: surveyHistory.isEmpty
          ? const Center(child: Text("No surveys found."))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: surveyHistory.length,
        itemBuilder: (context, index) {
          final entry = surveyHistory[index];
          return Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Day ${index + 1}",
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  ...entry.entries.map((e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("• ${e.key}: ",
                            style: const TextStyle(
                                fontWeight: FontWeight.bold)),
                        Expanded(child: Text(e.value)),
                      ],
                    ),
                  ))
                ],
              ),
            ),
          );

        },
      ),
    );
  }
}
