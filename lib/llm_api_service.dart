import 'dart:convert';

import 'package:http/http.dart' as http;

class LlmApiService {
  const LlmApiService();

  static const String _apiUrl = String.fromEnvironment('LLM_API_URL');
  static const String _apiToken = String.fromEnvironment('LLM_API_TOKEN');
  static const String _model = String.fromEnvironment(
    'LLM_MODEL',
    defaultValue: 'gpt-4o-mini',
  );

  bool get isConfigured => _apiUrl.trim().isNotEmpty;

  Future<String?> generateReply({
    required String prompt,
    required Map<String, dynamic> lifeContext,
    required List<Map<String, String>> history,
  }) async {
    if (!isConfigured) return null;

    final uri = Uri.tryParse(_apiUrl);
    if (uri == null) return null;

    final headers = <String, String>{'Content-Type': 'application/json'};
    if (_apiToken.trim().isNotEmpty) {
      headers['Authorization'] = 'Bearer $_apiToken';
    }

    final payload = <String, dynamic>{
      'model': _model,
      'prompt': prompt,
      'context': lifeContext,
      'history': history,
      'locale': 'ar-SA',
    };

    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final res = await http
            .post(uri, headers: headers, body: jsonEncode(payload))
            .timeout(Duration(seconds: attempt == 0 ? 35 : 45));

        if (res.statusCode < 200 || res.statusCode >= 300) {
          continue;
        }

        final decoded = jsonDecode(res.body);
        if (decoded is Map<String, dynamic>) {
          final direct = decoded['reply']?.toString().trim();
          if (direct != null && direct.isNotEmpty) return direct;

          final choices = decoded['choices'];
          if (choices is List && choices.isNotEmpty) {
            final first = choices.first;
            if (first is Map<String, dynamic>) {
              final content = (first['message'] as Map<String, dynamic>?)?['content']
                  ?.toString()
                  .trim();
              if (content != null && content.isNotEmpty) return content;
            }
          }
        }
      } catch (_) {
        // Retry once to absorb cold starts and transient network failures.
      }
    }

    return null;
  }
}
