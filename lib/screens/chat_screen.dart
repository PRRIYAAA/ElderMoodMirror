import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

const apiKey = "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"; // 🔑 Replace with your key

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Chat Demo',
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      home: const ChatPage(),
    );
  }
}

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  String _response = "";

  Future<void> sendMessage(String message) async {
    const url = "https://api.openai.com/v1/chat/completions";

    final headers = {
      "Authorization": "Bearer $apiKey",
      "Content-Type": "application/json",
    };

    final body = jsonEncode({
    "model": "gpt-3.5-turbo",
    "messages": [{"role": "system", "content": "You are a helpful assistant."},
    {"role": "user", "content": message},
    ],
    });

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final reply = data['choices'][0]['message']['content'];
        setState(() {
          _response = reply;
        });
      } else {
        setState(() {
          _response = "Error: ${response.statusCode} - ${response.body}";
        });
      }
    } catch (e) {
      setState(() {
        _response = "Failed to connect: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("AI Chat Tester")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(labelText: "Ask me anything"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                sendMessage(_controller.text);
              },
              child: const Text("Send"),
            ),
            const SizedBox(height: 20),
            Text("Response:", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Expanded(
              child: SingleChildScrollView(
                child: Text(_response),
              ),
            ),
          ],
        ),
      ),
    );
  }
}