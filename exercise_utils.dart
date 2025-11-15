import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ───────────────────────── Exercise Model ─────────────────────────
class ExerciseItem {
  final String title;
  final String emoji;
  final String imageUrl; // Image URL/asset path
  final String youtubeUrl; // NEW: YouTube link for guidance
  final List<String> steps;

  const ExerciseItem({
    required this.title,
    required this.emoji,
    required this.imageUrl,
    required this.youtubeUrl, // Added to constructor
    required this.steps,
  });
}

// ───────────────────────── Exercise List (10 Items) ─────────────────────────
const List<ExerciseItem> _exercises = [
  ExerciseItem(
    title: "Seated Marching",
    emoji: "🚶",
    imageUrl: "https://pptandfitness.com/wp-content/uploads/2024/08/Seated-Marches-exercise-2.jpg",
    youtubeUrl: "https://youtu.be/xxf93bq9-vA?si=iBFcL1oganKIN8z6",
    steps: [
      "Sit upright in a chair with both feet flat on the floor.",
      "Gently lift your right knee towards your chest.",
      "Lower your right foot slowly back to the floor.",
      "Repeat with your left knee.",
      "Alternate sides for 30 seconds, maintaining a steady, comfortable pace.",
    ],
  ),
  ExerciseItem(
    title: "Ankle Circles",
    emoji: "🦶",
    imageUrl: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTWQniqOefgzkJIRqM8w5elAjpQsXiALmzI_g&s",
    youtubeUrl: "https://youtu.be/sYAGbGEQMGE?si=rHe1i1GOkUyoSXvY",
    steps: [
      "Sit comfortably and extend one leg slightly.",
      "Slowly rotate your ankle clockwise for 10 repetitions.",
      "Reverse direction and rotate counter-clockwise for 10 repetitions.",
      "Switch legs and repeat the entire sequence.",
      "This improves ankle flexibility and circulation.",
    ],
  ),
  ExerciseItem(
    title: "Shoulder Rolls",
    emoji: "🤸",
    imageUrl: "https://spotebi.com/wp-content/uploads/2015/03/shoulder-rolls-exercise-illustration.jpg",
    youtubeUrl: "https://youtu.be/EOsdkHH5QvI?si=tEE6zaPLWrl8EgTa",
    steps: [
      "Sit or stand tall, letting your arms hang loosely at your sides.",
      "Shrug your shoulders up toward your ears.",
      "Roll your shoulders backward in a large, slow circle.",
      "Perform 5 slow backward rolls.",
      "Reverse the motion, rolling your shoulders forward 5 times.",
    ],
  ),
  ExerciseItem(
    title: "Wall Push-Ups",
    emoji: "💪",
    imageUrl: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTTHtgZw_l8O-1nbCBReKKPlbEijwu2auxNEw&s",
    youtubeUrl: "https://youtube.com/shorts/YWw-3rGaoT0?si=xueI0QWhnbGJTq_7",
    steps: [
      "Stand facing a wall, about arm's length away.",
      "Place your hands flat on the wall, shoulder-width apart.",
      "Slowly bend your elbows, lowering your chest toward the wall.",
      "Keep your body straight and core engaged.",
      "Push back to the starting position. Repeat 10 times.",
    ],
  ),
  ExerciseItem(
    title: "Knee Extensions",
    emoji: "🦵",
    imageUrl: "https://www.marattmd.com/learn/images/rehab/SeatedKneeExtension2.jpg",
    youtubeUrl: "https://www.youtube.com/watch?v=VuJZ6dqMf8M",
    steps: [
      "Sit in a sturdy chair, feet flat on the floor.",
      "Slowly extend your right knee until your leg is straight.",
      "Hold the position for 3 seconds, feeling the thigh muscle contract.",
      "Lower your leg slowly back down.",
      "Repeat 8 times per leg.",
    ],
  ),
  ExerciseItem(
    title: "Gentle Head Turns",
    emoji: "💆",
    imageUrl: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTtlYiR77AuFVu_L9kEeNzO2Zb0VuvZfVIWCQ&s",
    youtubeUrl: "https://www.youtube.com/watch?v=2NOsE-VPpkE",
    steps: [
      "Sit tall with your shoulders relaxed.",
      "Slowly turn your head to look over your right shoulder.",
      "Hold the stretch for 5 seconds.",
      "Gently turn your head back to the center.",
      "Repeat the turn to the left shoulder. Perform 3 times per side.",
    ],
  ),
  ExerciseItem(
    title: "Finger Stretches",
    emoji: "🖐️",
    imageUrl: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTKkFpm5mvS-8F_L2g4haUY4EEzxsTdVYoz3w&s",
    youtubeUrl: "https://www.youtube.com/watch?v=05H0tjWx8UA",
    steps: [
      "Hold your arm straight out in front of you, palm up.",
      "Spread your fingers wide, holding for 5 seconds.",
      "Make a gentle fist, enclosing your thumb.",
      "Open your hand and repeat 10 times.",
      "This helps maintain dexterity and relieve stiffness.",
    ],
  ),
  ExerciseItem(
    title: "Heel Raises",
    emoji: "⬆️",
    imageUrl: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQmvIO3EXC3EleIyUb8H0nh1xGti5hV9grUrw&s",
    youtubeUrl: "https://www.youtube.com/watch?v=ohvR3shCV90",
    steps: [
      "Stand holding onto the back of a chair for balance.",
      "Slowly raise your heels, coming up onto the balls of your feet.",
      "Hold at the top for a count of one.",
      "Slowly lower your heels back to the floor.",
      "Repeat 10-12 times to strengthen calf muscles.",
    ],
  ),
  ExerciseItem(
    title: "Deep Breathing",
    emoji: "🌬️",
    imageUrl: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQJE_yuyRWTj_y2smMRtoFw4kTJSz1z-Tws3g&s",
    youtubeUrl: "https://www.youtube.com/watch?v=acUZdGd_3Dg",
    steps: [
      "Sit comfortably and close your eyes, placing one hand on your belly.",
      "Inhale slowly through your nose, feeling your belly rise.",
      "Count to four while holding the breath.",
      "Exhale slowly through pursed lips, counting to six.",
      "Repeat 5 times to promote relaxation and calm.",
    ],
  ),
  ExerciseItem(
    title: "Side Bends (Seated)",
    emoji: "📐",
    imageUrl: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSD5GHckeJvbD_jWFYs1BS9kBCdCHGjkV0igQ&s",
    youtubeUrl: "https://www.youtube.com/watch?v=dL9ZzqtQI5c",
    steps: [
      "Sit tall, keeping your hips flat on the chair.",
      "Raise your right arm up towards the ceiling.",
      "Lean gently to the left side, stretching the right side of your torso.",
      "Hold the stretch for 10 seconds.",
      "Return to center and repeat on the opposite side (3 times each).",
    ],
  ),
];

// ───────────────────────── Helpers ─────────────────────────
List<ExerciseItem> getAllExercises() => _exercises;

Future<ExerciseItem> getTodayExercise() async {
  final prefs = await SharedPreferences.getInstance();
  final simStr = prefs.getString('current_app_date');
  final date = simStr != null ? DateTime.tryParse(simStr) ?? DateTime.now() : DateTime.now();

  // Use dayOfYear to select a rotating exercise
  final dayIdx = date.difference(DateTime(date.year, 1, 1)).inDays;
  final index = dayIdx % _exercises.length;

  return _exercises[index];
}