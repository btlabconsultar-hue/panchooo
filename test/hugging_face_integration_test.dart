import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/models/sport_models.dart';
import 'package:myapp/services/gemini_service.dart';

void main() {
  test('AiService local responde sin clave de Hugging Face', () async {
    final service = AiService();
    service.setProvider(AiProvider.local);

    final answer = await service.ask(
      question: 'Hola, cuéntame un chiste sobre el fútbol',
      sport: Sport.football,
      league: const LeagueOption(
        name: 'Liga Test',
        sport: Sport.football,
        apiCode: 'test',
        standingsCode: 'test',
        displayName: 'Liga Test',
      ),
      matches: const [],
    );

    expect(answer, contains('No tengo partidos cargados ahora mismo'));
  });
}
