import 'package:flutter/material.dart';
import 'quote_utils.dart';

class FloatingQuoteBubble extends StatelessWidget {
  final QuoteItem item;

  const FloatingQuoteBubble({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              blurRadius: 6,
              color: Colors.black26,
              offset: Offset(2, 2),
            )
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.format_quote, size: 18, color: Colors.teal),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                item.quote,
                style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
