import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/utils/gemini_response_parser.dart';

void main() {
  group('Gemini response parser', () {
    test('extracts plain text from a normal response', () {
      expect(
        extractGeminiText('River Plate tiene 38 títulos nacionales.'),
        'River Plate tiene 38 títulos nacionales.',
      );
    });

    test('extracts text from a JSON payload', () {
      expect(
        extractGeminiText('{"text":"Boca juega mañana."}'),
        'Boca juega mañana.',
      );
    });

    test('extracts text from a code fence', () {
      expect(extractGeminiText('```json\n{"text":"Hola"}\n```'), 'Hola');
    });
  });
}
