import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'user_info_screen.dart';
import 'mood_camera_screen.dart';
import 'quote_utils.dart';
import 'exercise_utils.dart';
import 'ExerciseScreen.dart';

class StartScreen extends StatefulWidget {
  final Widget nextScreen;
  final bool showQuoteOnEntry;

  const StartScreen({super.key, required this.nextScreen, this.showQuoteOnEntry = false});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  String _nextSlotMessage = "";
  bool _hasInitialized = false;
  bool _showMiniButton = true;
  late QuoteItem _todayQuote;
  late ExerciseItem _todayExercise;
  String _userName = "User"; // Default user name
  String _greeting = "";
  String? _profilePicUrl; // Variable for profile picture URL/path

  // Placeholder state for demonstrating the dashboard look
  bool _isSurveyCompleted = false;
  bool _isCameraCheckCompleted = false;

  @override
  void initState() {
    super.initState();
    _loadDailyContent();
    _checkIfFirstAnalysisToday();
    _setGreetingAndLoadUser();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowQuote();
    });
  }

  // --- Initializers and Loaders ---

  String _getTimeOfDayGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good morning";
    if (hour < 17) return "Good afternoon";
    return "Good evening";
  }

  Future<void> _setGreetingAndLoadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('user_name') ?? "Elder";
    final picUrl = prefs.getString('user_profile_pic'); // Retrieve saved URL/path

    setState(() {
      _userName = name;
      _greeting = _getTimeOfDayGreeting();
      _profilePicUrl = picUrl;
    });
  }

  Future<void> _loadDailyContent() async {
    final prefs = await SharedPreferences.getInstance();
    final simulatedDate = prefs.getString('current_app_date') ??
        DateTime.now().toIso8601String().substring(0, 10);
    final dayOfYear = DateTime.parse(simulatedDate).difference(DateTime(DateTime.now().year, 1, 1)).inDays;

    _todayQuote = getQuoteByIndex(dayOfYear);
    _todayExercise = await getTodayExercise();

    // Placeholder check for completion status
    _isSurveyCompleted = prefs.getBool('mood_analysis_done_today') ?? false;
    _isCameraCheckCompleted = prefs.getBool('mood_camera_done_today') ?? false;

    setState(() {});
  }

  // --- Quote and Exercise Dialogs ---

  Future<void> _checkIfFirstAnalysisToday() async {
    final prefs = await SharedPreferences.getInstance();
    final today = prefs.getString('current_app_date') ?? DateTime.now().toIso8601String().substring(0, 10);
    final shownDate = prefs.getString('start_card_shown_date');
    final analysisDone = prefs.getBool('mood_analysis_done_today') ?? false;

    if (analysisDone && shownDate != today) {
      await prefs.setString('start_card_shown_date', today);
    }
    setState(() => _showMiniButton = true);
  }

  Future<void> _maybeShowQuote() async {
    if (!mounted) return;
    if (widget.showQuoteOnEntry) {
      final prefs = await SharedPreferences.getInstance();
      final today = prefs.getString('current_app_date') ?? DateTime.now().toIso8601String().substring(0, 10);
      final lastShown = prefs.getString('quote_shown_date');

      if (lastShown != today) {
        await prefs.setString('quote_shown_date', today);
        // We ensure content is loaded before showing dialog
        if (_todayQuote == null) {
          await _loadDailyContent();
        }
        await Future.delayed(const Duration(milliseconds: 100));
        _showQuoteDialog();
      }
    }
  }

  Future<void> _showQuoteDialog() async {
    if (!mounted) return;
    setState(() => _showMiniButton = false);

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildQuoteDialogContent(_todayQuote),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                style: TextButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10)
                ),
                child: const Text("Close", style: TextStyle(color: Colors.teal, fontSize: 16)),
              ),
            ],
          ),
        );
      },
    );
    setState(() => _showMiniButton = true);
  }

  Widget _buildQuoteDialogContent(QuoteItem item) {
    // Content inside the quote dialog
    return Container(
      width: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFDEFE1),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(blurRadius: 8, color: Colors.black38, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🌞 Daily Quote',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text(
            '"${item.quote}"',
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 18, fontStyle: FontStyle.italic, color: Colors.brown),
          ),
          const SizedBox(height: 10),
          Text(
            item.affirmation,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Colors.teal),
          ),
        ],
      ),
    );
  }

  void _expandQuoteCard() async {
    if (_todayQuote == null) {
      await _loadDailyContent();
    }
    _showQuoteDialog();
  }

  // ... (rest of the file remains the same)

  // --- NEW: Function to open YouTube link ---
  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      // You may want to show a Snackbar here if the launch fails
      print('Could not launch $url');
    }
  }


  Future<void> _showExerciseDialog() async {
    if (!mounted) return;
    setState(() => _showMiniButton = false);

    await showDialog(
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
                    _todayExercise.title,
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 15),

                  // --- Image and Video Icon Stack ---
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          _todayExercise.imageUrl,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            height: 200,
                            color: Colors.grey.shade300,
                            child: const Center(child: Text("Exercise Image Placeholder")),
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
                              // FIX: Added onPressed logic to launch the YouTube URL
                              onPressed: () => _launchUrl(_todayExercise.youtubeUrl),
                              tooltip: 'Watch guidance video',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  // --- End Stack ---

                  const SizedBox(height: 20),
                  const Text("Steps:",
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.brown)),
                  // Corrected .toList().asMap().entries usage
                  ..._todayExercise.steps.take(5).toList().asMap().entries.map((entry) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("${entry.key + 1}. ", style: const TextStyle(fontWeight: FontWeight.bold)),
                        Expanded(child: Text(entry.value)),
                      ],
                    ),
                  ))
                      .toList(),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text("Close",
                            style: TextStyle(color: Colors.red, fontSize: 16)),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ExerciseScreen()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                        ),
                        child: const Text("More Exercises", style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    setState(() => _showMiniButton = true);
  }
// ... (rest of the file)

  void _expandExerciseCard() async {
    if (_todayExercise == null) {
      await _loadDailyContent();
    }
    _showExerciseDialog();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitialized) {
      _calculateNextSlotMessage();
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
        _nextSlotMessage = "Next slot: $formattedTime (in ${hours}h ${minutes}m)";
      });
    } else {
      setState(() {
        _nextSlotMessage = "No more slots today. Try again tomorrow.";
      });
    }
  }



  // --- Dashboard Building Blocks ---
  Widget _buildGreetingHeader(BuildContext context) {
    void navigateToUserInfo() {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const UserInfoScreen(isEditing: true)),
      ).then((_) {
        _setGreetingAndLoadUser();
      });
    }

    // --- Profile Image/Icon Logic ---
    ImageProvider? profileImageProvider;
    bool usingPlaceholderIcon = false; // Flag to determine if we should show the icon

    // 1. Determine the Image Provider
    if (_profilePicUrl != null && _profilePicUrl!.isNotEmpty) {
      // Use FileImage for local storage path
      profileImageProvider = FileImage(File(_profilePicUrl!));
    } else {
      // If no path, use the default asset. If the path fails or is transparent,
      // the CircleAvatar will show its child/backgroundColor.
      try {
        profileImageProvider = const AssetImage('assets/images/default_avatar.png');
      } catch (e) {
        // Fallback if the asset path is completely wrong (pubspec issue)
        profileImageProvider = null;
        usingPlaceholderIcon = true;
      }
    }

    // Define the fallback icon
    Widget fallbackIcon = const Icon(Icons.person, size: 40, color: Colors.teal);

    // If using the default asset, we assume the asset *is* the image, so we suppress the icon.
    // The icon should only appear if NO image (local or asset) is expected to load.
    if (profileImageProvider == null) {
      usingPlaceholderIcon = true;
    } else if (_profilePicUrl == null || _profilePicUrl!.isEmpty) {
      // If we are using the default asset (and the asset is working), we still shouldn't
      // overlay the fallback icon. The asset IS the fallback.
      usingPlaceholderIcon = false;
    }


    return GestureDetector(
      onTap: navigateToUserInfo,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal.shade400, Colors.lightGreen.shade300],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "$_greeting, $_userName!",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "How are you feeling today?",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _nextSlotMessage,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
            ),

            // --- FINAL CORRECT AVATAR IMPLEMENTATION ---
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.white,
              backgroundImage: (_profilePicUrl != null && _profilePicUrl!.isNotEmpty)
                  ? FileImage(File(_profilePicUrl!))
                  : const AssetImage('assets/images/default_avatar.png') as ImageProvider,
              child: null, // IMPORTANT: never show the icon when using default image
            )
            ,
          ],
        ),
      ),
    );
  }

  Widget _buildActivityCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
    required bool isCompleted,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isCompleted ? BorderSide(color: Colors.lightGreen, width: 2) : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(icon, size: 30, color: iconColor),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 14, color: isCompleted ? Colors.lightGreen : Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              if (isCompleted)
                const Icon(Icons.check_circle, color: Colors.lightGreen),
              if (!isCompleted)
                const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  // Adjusted for overflow fix and integrated buttons
  Widget _buildDailyTipsSection() {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Quote Button (Left)
          Expanded(
            child: GestureDetector(
              onTap: _expandQuoteCard,
              child: Card(
                color: Colors.teal.shade50,
                elevation: 1,
                // Reduced horizontal margin to fix overflow
                margin: const EdgeInsets.only(right: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: Padding(
                  padding: const EdgeInsets.all(10), // Reduced vertical padding
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Using the new .emoji getter (assuming fix in quote_utils.dart)
                      Text(_todayQuote.emoji, style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 4), // Reduced spacing
                      const Flexible(
                        child: Text("Daily Quote", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.teal, fontSize: 13)), // Smaller font
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Exercise Button (Right)
          Expanded(
            child: GestureDetector(
              onTap: _expandExerciseCard,
              child: Card(
                color: Colors.lightGreen.shade50,
                elevation: 1,
                // Reduced horizontal margin to fix overflow
                margin: const EdgeInsets.only(left: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: Padding(
                  padding: const EdgeInsets.all(10), // Reduced vertical padding
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_todayExercise.emoji, style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 4), // Reduced spacing
                      const Flexible(
                        child: Text("Activity Tip", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.lightGreen, fontSize: 13)), // Smaller font
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasInitialized || _todayExercise == null || _todayQuote == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50, // Light background for dashboard feel
      appBar: AppBar(
        title: const Text("Elder Mood Mirror"),
        centerTitle: true,
        backgroundColor: Colors.teal,
        // Removed the pen icon action, as the greeting header is now the main entry point for editing user info.
        actions: const [],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Greeting Header (Now Clickable)
            _buildGreetingHeader(context),

            // 2. Daily Tips/Activities (Overflow Fixed and Integrated)
            _buildDailyTipsSection(),

            const SizedBox(height: 16),
            const Text("Daily Activities", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
            const Divider(),

            // 3. Survey Card (Main Action)
            _buildActivityCard(
              title: "Daily Mood Survey",
              // NOTE: Update subtitle formatting if needed, current time is hardcoded.
              subtitle: _isSurveyCompleted ? "Completed today at 10:30 AM" : "Start your self-check now.",
              icon: Icons.assignment,
              iconColor: Colors.teal,
              isCompleted: _isSurveyCompleted,
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => widget.nextScreen),
                );
              },
            ),

            // 4. Camera Check Card (Main Action)
            _buildActivityCard(
              title: "Camera Mood Check",
              subtitle: _isCameraCheckCompleted ? "Mood analyzed successfully." : "Capture your current expression.",
              icon: Icons.camera_alt,
              iconColor: Colors.green,
              isCompleted: _isCameraCheckCompleted,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MoodCameraScreen()),
                );
              },
            ),

            const SizedBox(height: 24),
            // Placeholder for "This Week Summary" based on your dashboard image
            const Text("This Week Summary", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
            const Divider(),
            Card(
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Recent Mood", style: TextStyle(fontSize: 16)),
                        Text("Good", style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Weekly Score", style: TextStyle(fontSize: 16)),
                        Text("85%", style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const LinearProgressIndicator(value: 0.85, color: Colors.green),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}