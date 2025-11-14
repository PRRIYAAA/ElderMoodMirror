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
  bool _showMiniButton = true; // Start true and manage with _maybeShowQuote
  late QuoteItem _todayQuote;

  // Use a unique key for the RepaintBoundary in the dialog
  final GlobalKey _quoteRepaintBoundaryKey = GlobalKey();


  @override
  void initState() {
    super.initState();
    _loadQuoteForSimulatedDate();
    _checkIfFirstAnalysisToday();
    // Schedule the quote pop-up to happen after the first frame build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowQuote();
    });
  }

  Future<void> _loadQuoteForSimulatedDate() async {
    final prefs = await SharedPreferences.getInstance();
    // Load simulated date or use today's date
    final simulatedDate = prefs.getString('current_app_date') ??
        DateTime.now().toIso8601String().substring(0, 10);
    // Calculate day of year
    final dayOfYear = DateTime.parse(simulatedDate).difference(DateTime(DateTime.now().year, 1, 1)).inDays;
    _todayQuote = getQuoteByIndex(dayOfYear);
    setState(() {}); // Rebuild to ensure _todayQuote is available
  }

  Future<void> _checkIfFirstAnalysisToday() async {
    final prefs = await SharedPreferences.getInstance();
    final today = prefs.getString('current_app_date') ?? DateTime.now().toIso8601String().substring(0, 10);
    final shownDate = prefs.getString('start_card_shown_date');
    final analysisDone = prefs.getBool('mood_analysis_done_today') ?? false;

    // This logic seems intended to control a different UI element, but
    // for the quote bubble we mainly manage with _maybeShowQuote logic.
    if (analysisDone && shownDate != today) {
      await prefs.setString('start_card_shown_date', today);
    }

    // The mini button should be shown unless the full quote dialog is shown
    setState(() {
      _showMiniButton = true;
    });
  }

  Future<void> _maybeShowQuote() async {
    if (!mounted) return;
    if (widget.showQuoteOnEntry) {
      final prefs = await SharedPreferences.getInstance();
      final today = prefs.getString('current_app_date') ?? DateTime.now().toIso8601String().substring(0, 10);
      final lastShown = prefs.getString('quote_shown_date');

      if (lastShown != today) {
        // Mark as shown immediately to prevent repeated pop-ups on hot reload/re-entry
        await prefs.setString('quote_shown_date', today);
        // Ensure _todayQuote is loaded before trying to show it
        if (_todayQuote == null) {
          await _loadQuoteForSimulatedDate();
        }

        // Show the dialog after a slight delay to ensure the UI is stable
        await Future.delayed(const Duration(milliseconds: 100));
        await _showQuoteDialog();

        // The dialog is modal, so we don't need to explicitly hide the mini button,
        // but we'll re-enable it when the dialog is dismissed.
      }
    }
  }

  Future<void> _showQuoteDialog() async {
    if (!mounted) return;

    // Temporarily disable the mini button while the full dialog is up
    setState(() => _showMiniButton = false);

    await showDialog(
      context: context,
      barrierDismissible: true, // Allows dismissing by tapping the barrier
      builder: (dialogContext) {
        // Use a StateSetter in the dialog's builder to ensure quote is loaded
        // This is safer than relying on async outside the builder.
        final quoteWidget = _buildQuoteWidget(_todayQuote, _quoteRepaintBoundaryKey);

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.transparent, // Use transparent background for the dialog
          // to let the inner container define the appearance
          elevation: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // The quote image widget
              quoteWidget,
              const SizedBox(height: 10),
              // Close button
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

    // Re-enable the mini button once the dialog is dismissed
    setState(() => _showMiniButton = true);
  }

  // Helper method to build the widget that will be rendered as an image
  Widget _buildQuoteWidget(QuoteItem item, GlobalKey key) {
    return RepaintBoundary(
      key: key,
      child: Container(
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
      ),
    );
  }


  void _expandCard() async {
    // Ensure quote is loaded
    if (_todayQuote == null) {
      await _loadQuoteForSimulatedDate();
    }
    // Show the dialog
    _showQuoteDialog();
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
                onTap: _expandCard, // Use the fixed expand method
                child: FloatingQuoteBubble(item: _todayQuote),
              ),
            ),
        ],
      ),
    );
  }
}