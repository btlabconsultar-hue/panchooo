import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/models/sport_models.dart';
import 'package:myapp/services/gemini_service.dart';

void main() {
  test(
    'devuelve una respuesta local cuando no hay proveedor de pago configurado',
    () async {
      final service = AiService();
      service.setProvider(AiProvider.local);

      final answer = await service.ask(
        question: '¿Quién juega mañana?',
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

      expect(answer, isNotEmpty);
      expect(answer, contains('No tengo partidos cargados'));
    },
  );
}
