import 'package:flutter/material.dart';
import 'quote_utils.dart';

class FloatingQuoteBubble extends StatelessWidget {
  final QuoteItem item;

  const FloatingQuoteBubble({super.key, required this.item});

  // The logic for onTap and showing the popup is moved to StartScreen
  // This widget is now just a visual representation of the mini-quote button.

  @override
  Widget build(BuildContext context) {
    // We only show the quote's emoji and affirmation text in the mini bubble
    final String emoji = item.quote.split(' ').first;
    final String shortAffirmation = item.affirmation;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      margin: const EdgeInsets.symmetric(horizontal: 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(blurRadius: 6, color: Colors.black26, offset: Offset(2, 2)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            emoji, // Display the emoji
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              shortAffirmation, // Display the affirmation
              style: const TextStyle(fontSize: 14, color: Colors.teal, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.touch_app, size: 18, color: Colors.teal),
        ],
      ),
    );
  }
}