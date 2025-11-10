import 'package:flutter/material.dart';
import 'quote_utils.dart';

class FloatingQuoteBubble extends StatefulWidget {
  final QuoteItem item;

  const FloatingQuoteBubble({super.key, required this.item});

  @override
  State<FloatingQuoteBubble> createState() => _FloatingQuoteBubbleState();
}

class _FloatingQuoteBubbleState extends State<FloatingQuoteBubble> {
  Image? quoteImage;

  @override
  void initState() {
    super.initState();
    _generateImage();
  }

  Future<void> _generateImage() async {
    final bytes = await renderQuoteAsImage(context, widget.item);
    if (bytes != null) {
      setState(() {
        quoteImage = Image.memory(bytes, fit: BoxFit.cover);
      });
    }
  }

  void _showPopup() async {
    final bytes = await renderQuoteAsImage(context, widget.item);
    if (bytes == null) return;

    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.memory(bytes),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Close", style: TextStyle(color: Colors.teal)),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _showPopup,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(blurRadius: 6, color: Colors.black26, offset: Offset(2, 2)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.image, size: 18, color: Colors.teal),
            const SizedBox(width: 6),
            if (quoteImage != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(width: 80, height: 50, child: quoteImage),
              )
            else
              const Text("Loading...", style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
          ],
        ),
      ),
    );
  }
}
