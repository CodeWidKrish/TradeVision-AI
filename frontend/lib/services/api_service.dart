import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000';

  Future<String> fetchBackendMessage() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/test/'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['message']?.toString() ?? 'No message found';
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch backend: $e');
    }
  }
}