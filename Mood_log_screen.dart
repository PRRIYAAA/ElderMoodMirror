import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MoodLogScreen extends StatefulWidget {
  const MoodLogScreen({super.key});

  @override
  State<MoodLogScreen> createState() => _MoodLogScreenState();
}

class _MoodLogScreenState extends State<MoodLogScreen> {
  List<MapEntry<String, String>> moodLogs = [];

  @override
  void initState() {
    super.initState();
    loadMoodLogs();
    // ⏳ Navigate back to StartScreen after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      Navigator.pushReplacementNamed(context, '/start_screen');
    });
  }

  Future<void> loadMoodLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) {
      // Include only ISO-like timestamp keys (basic filter)
      return RegExp(r'^\d{4}-\d{2}-\d{2}T').hasMatch(k);
    }).toList();

    keys.sort();

    final List<MapEntry<String, String>> logs = [];
    for (final key in keys) {
      final value = prefs.getString(key);
      if (value != null) {
        logs.add(MapEntry(key, value));
      }
    }

    // ✅ Print all logs to console
    print("📋 Mood Logs:");
    for (final log in logs) {
      print(log);
    }

    setState(() => moodLogs = logs);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mood Logs"),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: "Clear Logs",
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              final keysToRemove = prefs.getKeys().where((k) => RegExp(r'^\d{4}-\d{2}-\d{2}T').hasMatch(k)).toList();
              for (final key in keysToRemove) {
                await prefs.remove(key);
              }
              setState(() => moodLogs.clear());
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Mood logs cleared")),
              );
            },
          ),
        ],

      ),
      body: moodLogs.isEmpty
          ? const Center(child: Text("No mood logs found."))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: moodLogs.length,
        itemBuilder: (context, index) {
          final entry = moodLogs[index];
          final dt = DateTime.tryParse(entry.key);
          final formattedTime = dt != null
              ? "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} "
              "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}"
              : entry.key;

          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.only(bottom: 16),
            child: ListTile(
              leading: const Icon(Icons.mood),
              title: Text(entry.value),
              subtitle: Text(formattedTime),
            ),
          );
        },
      ),
    );
  }
}