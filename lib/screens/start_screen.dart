import 'package:flutter/material.dart';
import 'user_info_screen.dart'; // Ensure this import points to your actual UserInfoScreen file

class StartScreen extends StatelessWidget {
  final Widget nextScreen;
  const StartScreen({super.key, required this.nextScreen});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Elder Mood Mirror"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: "Update Info",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UserInfoScreen(isEditing: true)),
              );
            },
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.face_retouching_natural, size: 80, color: Colors.teal),
            const SizedBox(height: 20),
            const Text(
              "Hello 👋\nHow are you feeling today?",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => nextScreen),
                );
              },
              child: const Text("Start Mood Check"),
            ),
          ],
        ),
      ),
    );
  }
}
