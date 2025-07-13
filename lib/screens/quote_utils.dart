import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/rendering.dart';
import 'dart:io';

class QuoteItem {
  final String quote;
  final String affirmation;
  const QuoteItem(this.quote, this.affirmation);
}

const List<QuoteItem> _quotes = [
  QuoteItem("🌞 Each day is a new gift.", "You are a miracle in motion."),
  QuoteItem("🌼 You are stronger than you think.", "Courage flows through you."),
  QuoteItem("🌻 Let your smile change the world.", "Your joy is contagious."),
  QuoteItem("🕊️ Peace begins with a calm mind.", "Breathe and be still."),
  QuoteItem("😊 Happiness looks good on you.", "You light up every space."),
  QuoteItem("🌷 Take time to bloom today.", "You are unfolding beautifully."),
  QuoteItem("💪 You’ve overcome so much already.", "You are unstoppable."),
  QuoteItem("💖 Your kindness matters.", "The world needs your heart."),
  QuoteItem("🌈 Rain or shine, you still shine.", "Brightness is your nature."),
  QuoteItem("🌟 You are enough, just as you are.", "Your presence is powerful."),
  QuoteItem("🌅 Wake up with purpose.", "Today is your chance to shine."),
  QuoteItem("🍃 Be gentle with yourself.", "Healing happens every day."),
  QuoteItem("🌸 Progress is not always visible.", "Keep going, quietly."),
  QuoteItem("💫 Believe in small miracles.", "You’re surrounded by wonder."),
  QuoteItem("🎨 Life is your canvas.", "Paint it with hope and joy."),
  QuoteItem("🎶 Your story is a beautiful song.", "Sing it with pride."),
  QuoteItem("🌼 Let go and grow.", "You are rising every day."),
  QuoteItem("🧘‍♀️ Peace is power.", "Your calmness inspires."),
  QuoteItem("🚤 Every step is part of the journey.", "You are going forward."),
  QuoteItem("🎁 Your presence is a gift.", "Thank you for being here."),
  QuoteItem("📖 You’re writing a new page today.", "Make it count."),
  QuoteItem("🌙 Rest is also progress.", "You’ve done enough today."),
  QuoteItem("✨ You bring light to others.", "Let yourself shine."),
  QuoteItem("🌳 Rooted and rising.", "You’re growing with strength."),
  QuoteItem("🧡 Choose joy today.", "Your heart knows the way."),
  QuoteItem("🚶 Keep moving forward.", "Every step matters."),
  QuoteItem("🎈 You deserve to feel light.", "Release what weighs you."),
  QuoteItem("🧠 Your thoughts are powerful.", "Speak kindly to yourself."),
  QuoteItem("🔥 Your inner fire never left.", "It’s time to reignite."),
  QuoteItem("🌊 Flow with grace.", "You adapt beautifully."),
  QuoteItem("🌄 Rise like the sun.", "You are radiant."),
  QuoteItem("🎯 You’re on the right path.", "Trust your pace."),
  QuoteItem("🏡 Be at home in yourself.", "You are safe within."),
  QuoteItem("🍂 Every season has a reason.", "This too shall pass."),
  QuoteItem("💡 Shine even when unseen.", "You matter always."),
  QuoteItem("📅 Today is part of the story.", "Make it memorable."),
  QuoteItem("🎉 Celebrate small wins.", "You are doing great."),
  QuoteItem("🚪 Open to new beginnings.", "Hope is knocking."),
  QuoteItem("🪞 Be proud of who you are.", "You are evolving."),
  QuoteItem("🎓 You’ve learned so much.", "Keep growing."),
  QuoteItem("🏔️ You are capable of mountains.", "Keep climbing."),
  QuoteItem("🚀 You are going places.", "The sky is not the limit."),
  QuoteItem("🕰️ Be present, be now.", "This moment matters."),
  QuoteItem("🌿 You’re healing more each day.", "Your spirit is strong."),
  QuoteItem("🌠 Your dreams are valid.", "You deserve joy."),
  QuoteItem("💬 Speak your truth.", "Your voice matters."),
  QuoteItem("🎥 You are the star of your life.", "Own your scene."),
  QuoteItem("🔓 Release old fears.", "Freedom feels good."),
  QuoteItem("🌞 The sun is rooting for you.", "Shine today."),
  QuoteItem("🌺 You are blooming on time.", "Patience is powerful."),
];

QuoteItem getQuoteByIndex(int index) {
  return _quotes[index % _quotes.length];
}

Future<QuoteItem> getTodayQuote() async {
  final prefs = await SharedPreferences.getInstance();
  final simulatedDateStr = prefs.getString('current_app_date');

  final simulatedDate = simulatedDateStr != null
      ? DateTime.tryParse(simulatedDateStr)
      : DateTime.now();

  final day = simulatedDate?.difference(DateTime(simulatedDate.year, 1, 1)).inDays ?? DateTime.now().day;
  return _quotes[day % _quotes.length];
}

Future<bool> markAndShouldShowQuoteToday() async {
  final prefs = await SharedPreferences.getInstance();
  final today = DateTime.now().toIso8601String().substring(0, 10);
  final last = prefs.getString('quote_shown_date');
  if (last == today) return false;
  await prefs.setString('quote_shown_date', today);
  return true;
}

void showQuoteOverlay(BuildContext ctx, QuoteItem item, {VoidCallback? onClose}) {
  showGeneralDialog(
    context: ctx,
    barrierDismissible: true,
    barrierLabel: "QuoteDialog",
    transitionDuration: const Duration(milliseconds: 400),
    pageBuilder: (_, __, ___) => const SizedBox.shrink(),
    transitionBuilder: (ctx, anim1, __, ___) {
      return FadeTransition(
        opacity: anim1,
        child: Center(
          child: _QuoteCard(item: item, onClose: onClose),
        ),
      );
    },
  );
}

class _QuoteCard extends StatelessWidget {
  final QuoteItem item;
  final VoidCallback? onClose;

  const _QuoteCard({required this.item, this.onClose});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      elevation: 6,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        width: MediaQuery.of(context).size.width * 0.85,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("🌞 Morning Quote", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),
            const Icon(Icons.format_quote, color: Colors.orange, size: 32),
            Text(
              "\"${item.quote}\"",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 10),
            Text(
              item.affirmation,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.teal),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                if (onClose != null) onClose!();
              },
              icon: const Icon(Icons.check),
              label: const Text("Got it"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension _DayOfYear on DateTime {
  int get dayOfYear => difference(DateTime(year, 1, 1)).inDays;
}
