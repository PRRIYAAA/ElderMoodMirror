import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Mood_log_screen.dart';


class MoodCameraScreen extends StatefulWidget {
  const MoodCameraScreen({super.key});

  @override
  State<MoodCameraScreen> createState() => _MoodCameraScreenState();
}
class _MoodCameraScreenState extends State<MoodCameraScreen> {
  late CameraController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final frontCamera = cameras.firstWhere(
          (cam) => cam.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _controller = CameraController(frontCamera, ResolutionPreset.medium);
    await _controller.initialize();
    setState(() => _isInitialized = true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> saveMood(String mood) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final key = now.toIso8601String(); // e.g., 2025-07-03T15:42:10.123Z
    await prefs.setString(key, mood);
    print("Mood logged: $mood at key: $key");
  }

  String inferMood(double? smileProb, double? leftEyeProb, double? rightEyeProb) {
    if ((smileProb ?? 0) > 0.7) return "Happy";
    if ((smileProb ?? 0) < 0.3 && (leftEyeProb ?? 0) < 0.4 && (rightEyeProb ?? 0) < 0.4) return "Sad or Tired";
    return "Neutral";
  }

  Future<void> captureAndDetectMood() async {
    if (!_controller.value.isInitialized || _controller.value.isTakingPicture) return;

    try {
      final XFile file = await _controller.takePicture();
      final inputImage = InputImage.fromFilePath(file.path);

      final faceDetector = FaceDetector(
        options: FaceDetectorOptions(
          enableClassification: true,
          performanceMode: FaceDetectorMode.accurate,
        ),
      );

      final List<Face> faces = await faceDetector.processImage(inputImage);

      if (faces.isNotEmpty) {
        final face = faces.first;
        final mood = inferMood(
          face.smilingProbability,
          face.leftEyeOpenProbability,
          face.rightEyeOpenProbability,
        );

        await saveMood(mood);

        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Mood Detected"),
            content: Text("You seem $mood"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              )
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No face detected.")),
        );
      }

      faceDetector.close();
    } catch (e) {
      print("Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mood Camera")),
      body: _isInitialized
          ? Column(
        children: [
          AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: CameraPreview(_controller),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: const Icon(Icons.camera),
            label: const Text("Capture Mood"),
            onPressed: captureAndDetectMood,
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.history),
            label: const Text("View Mood Logs"),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MoodLogScreen()),
              );
            },
          ),
        ],
      )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
