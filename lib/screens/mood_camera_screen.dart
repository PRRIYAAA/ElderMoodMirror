// mood_camera_screen.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

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

      if (dailyLogs.isEmpty || cameraLogs.isEmpty) {
        debugPrint('⛔ Cannot send: one of the inputs is empty');
        return false;
      }

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

          final result = await _saveMood(mood);
          setState(() {
            _detectedMood = "You seem ${result['mood']} 😊 at ${result['time']}";
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

  Future<Map<String, String>> _saveMood(String mood) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString('mood_history');
    Map<String, dynamic> moodHistory = existing != null ? jsonDecode(existing) : {};

    int totalEntries = moodHistory.values
        .fold(0, (sum, dayList) => sum + (dayList as List).length);

    DateTime baseDate = DateTime.now();
    int dayOffset = totalEntries ~/ 3;
    DateTime simulatedDate = baseDate.add(Duration(days: dayOffset));
    final dateKey = simulatedDate.toIso8601String().substring(0, 10);
    final timeKey = DateTime.now().toIso8601String().substring(11, 19);

    moodHistory.putIfAbsent(dateKey, () => []);
    (moodHistory[dateKey] as List).add({'time': timeKey, 'mood': mood});

    await prefs.setString('mood_history', jsonEncode(moodHistory));

    print("📝 Mood saved: $mood at $timeKey on $dateKey");
    print("📦 Full mood history: ${jsonEncode(moodHistory)}");

    if (totalEntries + 1 >= 21) {
      print("📬 21 entries collected. Sending to server...");
      List<Map<String, String>> flatList = [];
      moodHistory.forEach((date, entries) {
        for (var entry in entries) {
          flatList.add({
            'date': date,
            'time': entry['time'],
            'mood': entry['mood'],
          });
        }
      });

      final activeJson = prefs.getString('active_inputs');
      final Map<String, dynamic> activeInputs = activeJson != null ? jsonDecode(activeJson) : {};
      final dailyLogsRaw = activeInputs['daily_logs'];
      final List<Map<String, String>> dailyLogs = [];
      if (dailyLogsRaw != null && dailyLogsRaw is List) {
        for (var item in dailyLogsRaw) {
          if (item is Map) {
            dailyLogs.add(item.map((k, v) => MapEntry(k.toString(), v.toString())));
          }
        }
      }

      bool sent = await sendToPythonServer(
        dailyLogs: dailyLogs,
        cameraLogs: flatList,
      );

      if (sent) {
        await prefs.remove('mood_history');
        print("✅ Cleared mood history.");
      }
    } else {
      print("🕓 Collected ${totalEntries + 1}/21 entries. Keep going...");
    }

    return {'mood': mood, 'time': timeKey};
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
              padding:
              const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: const [
                  BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: Offset(0, -2)),
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
