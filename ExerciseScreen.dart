import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // Import the url_launcher package
import 'exercise_utils.dart';

class ExerciseScreen extends StatelessWidget {
  const ExerciseScreen({Key? key}) : super(key: key);

  // --- NEW: Function to open YouTube link ---
  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  void _showExerciseDetails(BuildContext context, ExerciseItem item) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 15),

                  // --- Exercise Image and YouTube Icon ---
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Display exercise image
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          item.imageUrl,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            height: 200,
                            color: Colors.grey.shade300,
                            child: Center(
                                child: Text("Image Failed to Load: ${item.emoji}")),
                          ),
                        ),
                      ),

                      // YouTube Play Button Overlay
                      Positioned.fill(
                        child: Center(
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black54,
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.play_circle_filled, color: Colors.white, size: 50),
                              onPressed: () => _launchUrl(item.youtubeUrl),
                              tooltip: 'Watch guidance video',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // --- Steps ---
                  const SizedBox(height: 20),
                  const Text("Step-by-Step Guide:",
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.brown)),
                  ...item.steps
                      .asMap()
                      .entries
                      .map((entry) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("${entry.key + 1}. ",
                            style: const TextStyle(
                                fontWeight: FontWeight.bold)),
                        Expanded(child: Text(entry.value)),
                      ],
                    ),
                  ))
                      .toList(),
                  const SizedBox(height: 20),

                  // --- Close Button ---
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text("Close",
                        style: TextStyle(color: Colors.teal, fontSize: 16)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final exercises = getAllExercises();
    return Scaffold(
      appBar: AppBar(
        title: const Text("Daily Gentle Exercises"),
        backgroundColor: Colors.teal,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: exercises.length,
        itemBuilder: (context, index) {
          final item = exercises[index];
          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              leading: Text(item.emoji, style: const TextStyle(fontSize: 24)),
              title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(item.steps.first, maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // NEW: YouTube Icon Button
                  IconButton(
                    icon: const Icon(Icons.ondemand_video, size: 24, color: Colors.red),
                    onPressed: () => _launchUrl(item.youtubeUrl),
                    tooltip: 'Watch Video',
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.teal),
                ],
              ),
              onTap: () => _showExerciseDetails(context, item),
            ),
          );
        },
      ),
    );
  }
}