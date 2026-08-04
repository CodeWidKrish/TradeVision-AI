import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const ApiTestApp());
}

class ApiTestApp extends StatelessWidget {
  const ApiTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'API Test',
      theme: ThemeData(useMaterial3: true),
      home: const ApiTestPage(),
    );
  }
}

class ApiTestPage extends StatefulWidget {
  const ApiTestPage({super.key});

  @override
  State<ApiTestPage> createState() => _ApiTestPageState();
}

class _ApiTestPageState extends State<ApiTestPage> {
  final TextEditingController _symbolController =
      TextEditingController(text: 'AAPL');

  String output = 'Press any button to test an endpoint';

  @override
  void dispose() {
    _symbolController.dispose();
    super.dispose();
  }

  String get symbol {
    final value = _symbolController.text.trim().toUpperCase();
    return value.isEmpty ? 'AAPL' : value;
  }

  Future<void> callEndpoint(String title, String url) async {
    setState(() {
      output = 'Loading $title...\n$url';
    });

    try {
      final res = await http.get(Uri.parse(url));

      String bodyText;
      try {
        final decoded = jsonDecode(res.body);
        bodyText = const JsonEncoder.withIndent('  ').convert(decoded);
      } catch (_) {
        bodyText = res.body;
      }

      setState(() {
        output = '''
$title
URL: $url
Status: ${res.statusCode}

$bodyText
''';
      });
    } catch (e) {
      setState(() {
        output = '''
$title
URL: $url

Exception: $e
''';
      });
    }
  }

  Widget endpointButton(String label, String url) {
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: ElevatedButton(
          onPressed: () => callEndpoint(label, url),
          child: Text(label),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const base = 'http://127.0.0.1:8000';

    return Scaffold(
      appBar: AppBar(title: const Text('Backend Endpoint Tester')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _symbolController,
                decoration: const InputDecoration(
                  labelText: 'Stock Symbol',
                  hintText: 'Enter AAPL, TSLA, MSFT...',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 12),
              endpointButton('Test', '$base/test/'),
              endpointButton('Stocks', '$base/stocks/$symbol'),
              endpointButton('Stock Details', '$base/stock-details/$symbol'),
              endpointButton('Recommendation', '$base/recommendation/$symbol'),
              endpointButton('Overview', '$base/overview?symbol=$symbol'),
              endpointButton('News', '$base/news/$symbol'),
              endpointButton('Indicators', '$base/indicators?symbol=$symbol'),
              endpointButton('Chart', '$base/chart/$symbol'),
              const SizedBox(height: 12),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(output),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}