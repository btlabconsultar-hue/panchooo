import 'dart:convert';

String extractGeminiText(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) {
    return '';
  }

  final codeFencePattern = RegExp(
    r'^```(?:json)?\s*(.*?)\s*```$',
    dotAll: true,
  );
  final fencedMatch = codeFencePattern.firstMatch(trimmed);
  if (fencedMatch != null) {
    return extractGeminiText(fencedMatch.group(1) ?? '');
  }

  if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is Map<String, dynamic> && decoded['text'] is String) {
        return decoded['text'] as String;
      }
      if (decoded is Map && decoded['response'] is String) {
        return decoded['response'] as String;
      }
    } catch (_) {
      // Fallback to raw text below.
    }
  }

  return trimmed;
}
