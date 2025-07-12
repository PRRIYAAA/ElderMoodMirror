import 'package:flutter/material.dart';
import 'user_info_screen.dart';
import 'mood_camera_screen.dart';

class StartScreen extends StatefulWidget {
  final Widget nextScreen;
  const StartScreen({super.key, required this.nextScreen});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  String _nextSlotMessage = "";
  bool _hasInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitialized) {
      _calculateNextSlotMessage(); // safe to use context here
      _hasInitialized = true;
    }
  }

  void _calculateNextSlotMessage() {
    final now = DateTime.now();

    final morning = DateTime(now.year, now.month, now.day, 6);
    final afternoon = DateTime(now.year, now.month, now.day, 12);
    final evening = DateTime(now.year, now.month, now.day, 18);

    DateTime? nextSlot;

    if (now.isBefore(morning)) {
      nextSlot = morning;
    } else if (now.isBefore(afternoon)) {
      nextSlot = afternoon;
    } else if (now.isBefore(evening)) {
      nextSlot = evening;
    }

    if (nextSlot != null) {
      final diff = nextSlot.difference(now);
      final hours = diff.inHours;
      final minutes = diff.inMinutes % 60;
      final formattedTime = TimeOfDay.fromDateTime(nextSlot).format(context);

      setState(() {
        _nextSlotMessage =
        "Next slot: $formattedTime (in ${hours}h ${minutes}m)";
      });
    } else {
      setState(() {
        _nextSlotMessage = "No more slots today. Try again tomorrow.";
      });
    }
  }

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
                MaterialPageRoute(
                    builder: (_) => const UserInfoScreen(isEditing: true)),
              );
            },
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.face_retouching_natural,
                size: 80, color: Colors.teal),
            const SizedBox(height: 20),
            const Text(
              "Hello 👋\nHow are you feeling today?",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22),
            ),
            const SizedBox(height: 10),
            Text(
              _nextSlotMessage,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => widget.nextScreen),
                );
              },
              child: const Text("Start Mood Check"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const MoodCameraScreen()),
                );
              },
              child: const Text("Camera Detection"),
            ),
          ],
        ),
      ),
    );
  }
}
