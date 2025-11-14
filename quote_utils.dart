import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

// ───────────────────────── Quote Model ─────────────────────────
class QuoteItem {
  final String quote;
  final String affirmation;
  const QuoteItem(this.quote, this.affirmation);
}

// ───────────────────────── Quote List ─────────────────────────
const List<QuoteItem> _quotes = [
  // ... (Your full _quotes list remains here)
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

// ───────────────────────── Helpers ─────────────────────────
QuoteItem getQuoteByIndex(int index) => _quotes[index % _quotes.length];

Future<QuoteItem> getTodayQuote() async {
  final prefs = await SharedPreferences.getInstance();
  final simStr = prefs.getString('current_app_date');
  final date = simStr != null ? DateTime.tryParse(simStr) ?? DateTime.now() : DateTime.now();
  final dayIdx = date.difference(DateTime(date.year, 1, 1)).inDays;
  return getQuoteByIndex(dayIdx);
}

Future<bool> markAndShouldShowQuoteToday() async {
  final prefs = await SharedPreferences.getInstance();
  final today = prefs.getString('current_app_date') ?? DateTime.now().toIso8601String().substring(0, 10);
  final last = prefs.getString('quote_shown_date');
  if (last == today) return false;
  await prefs.setString('quote_shown_date', today);
  return true;
}

// ───────────────────────── Image Renderer with Background ─────────────────────────
Future<Uint8List?> renderQuoteAsImage(QuoteItem item) async {
  final key = GlobalKey();

  // 1. Create the widget to render (300 wide)
  final widgetToRender = RepaintBoundary(
    key: key,
    child: Container(
      width: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFDEFE1),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(blurRadius: 6, color: Colors.black26, offset: Offset(2, 2)),
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

  // 2. Set up the off-screen rendering environment
  final RenderRepaintBoundary boundary = RenderRepaintBoundary();
  final PipelineOwner pipelineOwner = PipelineOwner();
  final BuildOwner buildOwner = BuildOwner(focusManager: FocusManager());

  // Get the first view
  final ui.FlutterView? firstView = ui.PlatformDispatcher.instance.views.firstOrNull;
  if (firstView == null) return null;

  final double devicePixelRatio = firstView.devicePixelRatio;

  // Set a fixed logical size for the rendering environment
  const Size logicalSize = Size(300, 300);

  final RenderView renderView = RenderView(
    view: firstView,
    child: RenderPositionedBox(alignment: Alignment.center, child: boundary),
    // FINAL FIX: Initializing ViewConfiguration with ZERO arguments
    // to strictly comply with the "0 expected" error message.
    configuration: const ViewConfiguration(),
  );

  pipelineOwner.rootNode = renderView;
  renderView.attach(pipelineOwner);
  // Layout using physical size constraints
  renderView.layout(BoxConstraints.tight(logicalSize * devicePixelRatio));

  // 3. Attach the widget tree to the Render tree
  RenderObjectToWidgetElement<RenderBox>? element;
  try {
    element = RenderObjectToWidgetAdapter<RenderBox>(
      container: boundary,
      child: widgetToRender,
    ).attachToRenderTree(buildOwner, element);

    buildOwner.finalizeTree();
    pipelineOwner.flushLayout();
    pipelineOwner.flushPaint();

    // 4. Convert to image bytes
    final image = await boundary.toImage(pixelRatio: devicePixelRatio);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  } catch (e) {
    debugPrint('renderQuoteAsImage error: $e');
    return null;
  } finally {
    // 5. Clean up the off-screen resources
    element?.detachRenderObject();
    buildOwner.finalizeTree();
  }
}

// ───────────────────────── Day‑of‑Year Extension ─────────────────────────
extension _DayOfYear on DateTime {
  int get dayOfYear => difference(DateTime(year, 1, 1)).inDays;
}