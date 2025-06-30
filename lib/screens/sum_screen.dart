import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SumScreen extends StatefulWidget {
  const SumScreen({super.key});

  @override
  State<SumScreen> createState() => _SumScreenState();
}

class _SumScreenState extends State<SumScreen> {
  final TextEditingController num1Controller = TextEditingController();
  final TextEditingController num2Controller = TextEditingController();
  String result = '';

  Future<void> calculateSum() async {
    final num1 = int.tryParse(num1Controller.text) ?? 0;
    final num2 = int.tryParse(num2Controller.text) ?? 0;

    final response = await http.post(
      Uri.parse('http://10.0.2.2:5000/sum'), // Use 10.0.2.2 for Android emulator
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'num1': num1, 'num2': num2}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        result = 'Sum: ${data['sum']}';
      });
    } else {
      setState(() {
        result = 'Error occurred';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sum Calculator")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: num1Controller,
              decoration: const InputDecoration(labelText: 'Enter number 1'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: num2Controller,
              decoration: const InputDecoration(labelText: 'Enter number 2'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: calculateSum,
              child: const Text("Calculate Sum"),
            ),
            const SizedBox(height: 20),
            Text(result, style: const TextStyle(fontSize: 20)),
          ],
        ),
      ),
    );
  }
}