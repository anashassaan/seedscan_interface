import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiChatService {
  static const String _baseUrl = 'https://seedscan-llm-api.vercel.app';

  /// Check connectivity by accessing the health endpoint.
  static Future<bool> isOnline() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/api/health'))
          .timeout(const Duration(seconds: 3));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Stream<String> generateResponseStream({
    required String userId,
    required String message,
    String? conversationId,
  }) async* {
    final url = Uri.parse('$_baseUrl/api/chat/stream');
    final request = http.Request('POST', url);
    request.headers['Content-Type'] = 'application/json';
    request.headers['Accept'] = 'text/event-stream';

    // API Expects: "user_id", "message", "conversation_id" "plant_context" (optional)
    request.body = jsonEncode({
      "user_id": userId,
      "message": message,
      "conversation_id": conversationId ?? "default_session"
    });

    final client = http.Client();
    try {
      final response = await client
          .send(request)
          .timeout(const Duration(seconds: 15), onTimeout: () {
        throw TimeoutException("API Connection Timeout");
      });

      if (response.statusCode != 200) {
        final errorBody = await response.stream.bytesToString();
        throw Exception("API Error: ${response.statusCode} - $errorBody");
      }

      await for (final chunk in response.stream.transform(utf8.decoder)) {
        final lines = chunk.split('\n');
        for (final line in lines) {
          if (line.startsWith('data: ')) {
            final data = line.substring(6).trim();
            if (data == '[DONE]') {
              return;
            }
            if (data.isNotEmpty) {
              try {
                final parsed = jsonDecode(data);
                if (parsed is Map && parsed.containsKey('chunk')) {
                  yield parsed['chunk'];
                } else if (parsed is Map && parsed.containsKey('text')) {
                  yield parsed['text'];
                } else {
                  yield data; // Fallback
                }
              } catch (e) {
                // Not JSON, yield plain
                yield data;
              }
            }
          }
        }
      }
    } finally {
      client.close();
    }
  }
}
