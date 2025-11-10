import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'user_info_screen.dart';
import 'mood_camera_screen.dart';
import 'quote_utils.dart';
import 'floating_quote_bubble.dart';

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
  bool _showMiniButton = false;
  late QuoteItem _todayQuote;

  @override
  void initState() {
    super.initState();
    _loadQuoteForSimulatedDate();
    _checkIfFirstAnalysisToday();
    _maybeShowQuote();
  }

  Future<void> _loadQuoteForSimulatedDate() async {
    final prefs = await SharedPreferences.getInstance();
    final simulatedDate = prefs.getString('current_app_date') ??
        DateTime.now().toIso8601String().substring(0, 10);
    final dayOfYear = DateTime.parse(simulatedDate).difference(DateTime(DateTime.now().year, 1, 1)).inDays;
    _todayQuote = getQuoteByIndex(dayOfYear);
  }

  Future<void> _checkIfFirstAnalysisToday() async {
    final prefs = await SharedPreferences.getInstance();
    final today = prefs.getString('current_app_date') ?? DateTime.now().toIso8601String().substring(0, 10);
    final shownDate = prefs.getString('start_card_shown_date');
    final analysisDone = prefs.getBool('mood_analysis_done_today') ?? false;

    if (analysisDone && shownDate != today) {
      await prefs.setString('start_card_shown_date', today);
    }

    setState(() {
      _showMiniButton = true;
    });
  }

  Future<void> _maybeShowQuote() async {
    if (widget.showQuoteOnEntry) {
      final prefs = await SharedPreferences.getInstance();
      final today = prefs.getString('current_app_date') ?? DateTime.now().toIso8601String().substring(0, 10);
      final lastShown = prefs.getString('quote_shown_date');

      if (lastShown != today) {
        await prefs.setString('quote_shown_date', today);
        await Future.delayed(const Duration(milliseconds: 100));
        _showQuoteDialog();
        setState(() => _showMiniButton = false);
      }
    }
  }

  Future<void> _showQuoteDialog() async {
    final imageBytes = await renderQuoteAsImage(context, _todayQuote);
    if (imageBytes == null) return;

    // ignore: use_build_context_synchronously
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.memory(
                  imageBytes,
                  width: 280, // ensures it fits within the dialog
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Close", style: TextStyle(color: Colors.teal)),
              ),
            ],
          ),
        ),
      ),
    );
  }


  void _expandCard() => _showQuoteDialog();

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
      body: Stack(
        children: [
          // ────────── Main UI ──────────
          Center(
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
                const SizedBox(height: 10),
                Text(_nextSlotMessage, style: const TextStyle(fontSize: 16, color: Colors.grey)),
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
                      MaterialPageRoute(builder: (_) => const MoodCameraScreen()),
                    );
                  },
                  child: const Text("Camera Detection"),
                ),
              ],
            ),
          ),

          // ────────── Floating Quote Bubble at TOP ──────────
          if (_showMiniButton)
            Positioned(
              top: 24,
              left: 0,
              right: 0,
              child: GestureDetector(
                onTap: _expandCard,
                child: FloatingQuoteBubble(item: _todayQuote),
              ),
            ),
        ],
      ),
    );
  }
}
