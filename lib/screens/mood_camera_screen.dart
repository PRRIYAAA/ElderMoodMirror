import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MoodCameraScreen extends StatefulWidget {
  const MoodCameraScreen({super.key});

  @override
  State<MoodCameraScreen> createState() => _MoodCameraScreenState();
}

class _MoodCameraScreenState extends State<MoodCameraScreen> {
  late CameraController _controller;
  late FaceDetector _faceDetector;
  bool _isInitialized = false;
  bool _isDetecting = false;
  bool _isMoodCaptured = false;
  String _detectedMood = "Waiting for mood detection...";
  Timer? _scanTimer;

  @override
  void initState() {
    super.initState();
    _initializeFaceDetector();
    _initializeCamera();
  }

  void _initializeFaceDetector() {
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableClassification: true,
        performanceMode: FaceDetectorMode.fast,
      ),
    );
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final frontCamera = cameras.firstWhere(
          (cam) => cam.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _controller = CameraController(frontCamera, ResolutionPreset.high);
    await _controller.initialize();
    setState(() => _isInitialized = true);

    _startDetectionLoop();
  }

  void _startDetectionLoop() {
    _scanTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (!_controller.value.isInitialized || _isDetecting || _isMoodCaptured) return;

      _isDetecting = true;

      try {
        final file = await _controller.takePicture();
        final inputImage = InputImage.fromFile(File(file.path));
        final faces = await _faceDetector.processImage(inputImage);

        if (faces.isNotEmpty) {
          final face = faces.first;

          final mood = _inferMood(
            face.smilingProbability ?? 0.0,
            face.leftEyeOpenProbability ?? 0.0,
            face.rightEyeOpenProbability ?? 0.0,
          );

          await _saveMood(mood);
          setState(() {
            _detectedMood = "You seem $mood 😊";
            _isMoodCaptured = true;
          });
          _scanTimer?.cancel();
        }
      } catch (e) {
        print("❌ Error detecting mood: $e");
      }

      _isDetecting = false;
    });
  }

  String _inferMood(double smile, double leftEye, double rightEye) {
    if (smile < 0.1 && leftEye < 0.6 && rightEye < 0.6) return "Sad";
    if (smile > 0.6 && leftEye > 0.6 && rightEye > 0.6) return "Happy";
    return "Neutral";
  }

  Future<void> _saveMood(String mood) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final dateKey = now.toIso8601String().substring(0, 10);
    final timeKey = now.toIso8601String().substring(11, 19);

    final existing = prefs.getString('mood_history');
    Map<String, dynamic> moodHistory = existing != null ? jsonDecode(existing) : {};

    if (!moodHistory.containsKey(dateKey)) {
      moodHistory[dateKey] = [];
    }

    (moodHistory[dateKey] as List).add({
      'time': timeKey,
      'mood': mood,
    });

    await prefs.setString('mood_history', jsonEncode(moodHistory));
    print("📝 Mood saved: $mood at $timeKey on $dateKey");
    print("📦 Full mood history: ${jsonEncode(moodHistory)}");
  }

  @override
  void dispose() {
    _controller.dispose();
    _faceDetector.close();
    _scanTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("Mood Camera"),
        backgroundColor: Colors.teal.shade600,
        centerTitle: true,
      ),
      body: _isInitialized
          ? Column(
        children: [
          Container(
            height: MediaQuery.of(context).size.height * 0.6,
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: CameraPreview(_controller),
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, -2)),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _detectedMood,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.teal,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Hold steady and look at the camera.\nMood will be detected automatically.",
                    style: TextStyle(color: Colors.black54, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        ],
      )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
