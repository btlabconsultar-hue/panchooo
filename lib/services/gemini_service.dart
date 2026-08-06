import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/sport_models.dart';

enum AiProvider { local, huggingFace }

class AiService {
  static const defaultHuggingFaceApiKey = '';

  AiService({http.Client? client, String? huggingFaceApiKey})
    : _client = client ?? http.Client(),
      _huggingFaceApiKey = _normalizeApiKey(huggingFaceApiKey);

  final http.Client _client;
  String _huggingFaceApiKey;

  static const _huggingFaceModel = 'distilgpt2';

  AiProvider selectedProvider = AiProvider.local;

  bool get isConfigured {
    if (selectedProvider == AiProvider.huggingFace) {
      return _huggingFaceApiKey.isNotEmpty;
    }
    return true;
  }

  bool get hasAnyKey => _huggingFaceApiKey.isNotEmpty;

  String get huggingFaceApiKey => _huggingFaceApiKey;

  void setApiKey(String key, AiProvider provider) {
    if (provider == AiProvider.huggingFace) {
      _huggingFaceApiKey = _normalizeApiKey(key);
    }
  }

  void setProvider(AiProvider provider) {
    selectedProvider = provider;
  }

  String get currentApiKey => _huggingFaceApiKey;

  Future<String> ask({
    required String question,
    required Sport sport,
    required LeagueOption league,
    required List<SportMatch> matches,
  }) async {
    final prompt = _buildPrompt(question, sport, league, matches);

    if (selectedProvider == AiProvider.huggingFace &&
        _huggingFaceApiKey.isNotEmpty) {
      try {
        final hfAnswer = await _askHuggingFace(prompt);
        if (hfAnswer.trim().isNotEmpty && hfAnswer.length > 10) {
          return hfAnswer;
        }
      } catch (e) {
        // Silenciosamente falla a respuesta local si hay error.
      }
    }

    return _localAnswer(question, sport, league, matches);
  }

  Future<String> _askHuggingFace(String prompt) async {
    final uri = Uri.parse(
      'https://api-inference.huggingface.co/models/$_huggingFaceModel',
    );

    final response = await _client.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_huggingFaceApiKey',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'inputs': prompt,
        'parameters': {
          'max_new_tokens': 220,
          'temperature': 0.7,
          'return_full_text': false,
          'do_sample': true,
        },
        'options': {'wait_for_model': true},
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Error en Hugging Face: ${response.statusCode} ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is List && decoded.isNotEmpty) {
      final first = decoded.first;
      if (first is Map<String, dynamic>) {
        return _extractHuggingFaceText(first);
      }
    }
    if (decoded is Map<String, dynamic>) {
      return _extractHuggingFaceText(decoded);
    }
    return decoded.toString();
  }

  String _extractHuggingFaceText(Map<String, dynamic> payload) {
    final candidates = <String?>[
      payload['generated_text']?.toString(),
      payload['text']?.toString(),
      payload['content']?.toString(),
      payload['answer']?.toString(),
    ];

    for (final candidate in candidates) {
      if (candidate != null && candidate.trim().isNotEmpty) {
        return candidate.trim();
      }
    }

    return payload.toString();
  }

  static String _normalizeApiKey(String? key) {
    return (key ?? '').trim();
  }

  String _buildPrompt(
    String question,
    Sport sport,
    LeagueOption league,
    List<SportMatch> matches,
  ) {
    final context = matches.isEmpty
        ? 'No hay datos de partidos disponibles.'
        : 'Hay ${matches.length} partidos cargados.';
    return 'Pregunta sobre deportes: $question. Contexto: $context. Responde brevemente en español.';
  }

  String _localAnswer(
    String question,
    Sport sport,
    LeagueOption league,
    List<SportMatch> matches,
  ) {
    final lower = _normalize(question);
    if (matches.isEmpty) {
      return 'No tengo partidos cargados ahora mismo. Usa la pantalla principal para refrescar los partidos.';
    }

    final teamMatches = _findTeamMatches(lower, matches);
    final teamName = teamMatches.isNotEmpty
        ? _favoriteTeamName(teamMatches.first)
        : null;

    if (lower.contains('tabla') ||
        lower.contains('posición') ||
        lower.contains('posiciones')) {
      if (standingsAvailable(matches)) {
        return _standingsSummary(league.displayName, matches);
      }
      return 'Puedo decirte los próximos y pasados partidos, pero no tengo la tabla cargada para esta liga.';
    }

    if (teamMatches.isNotEmpty &&
        (lower.contains('cuando') ||
            lower.contains('juega') ||
            lower.contains('próximo') ||
            lower.contains('siguiente'))) {
      return _teamNextMatchSummary(teamName!, teamMatches);
    }

    if (teamMatches.isNotEmpty &&
        (lower.contains('ganó') ||
            lower.contains('resultado') ||
            lower.contains('empató') ||
            lower.contains('perdió'))) {
      return _teamLastResultSummary(teamName!, teamMatches);
    }

    if (lower.contains('anterior') ||
        lower.contains('pasado') ||
        lower.contains('último')) {
      if (teamMatches.isNotEmpty) {
        return _teamPreviousMatchesSummary(teamName!, teamMatches);
      }
      return _previousMatchesSummary(matches);
    }

    if (teamMatches.isNotEmpty) {
      return _teamNextMatchSummary(teamName!, teamMatches);
    }

    if (lower.contains('próximo') || lower.contains('siguiente')) {
      return _nextMatchSummary(matches);
    }

    if (lower.contains('ganó') ||
        lower.contains('quién ganó') ||
        lower.contains('resultado')) {
      return _lastFinishedMatchSummary(matches);
    }

    return 'Veo ${matches.length} partidos cargados para ${league.displayName}. Si querés, preguntame por un equipo o por el próximo partido.';
  }

  String _normalize(String text) {
    return text
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ü', 'u')
        .replaceAll(RegExp('[^a-z0-9 ]'), ' ')
        .replaceAll(RegExp('\s+'), ' ')
        .trim();
  }

  List<SportMatch> _findTeamMatches(String query, List<SportMatch> matches) {
    final tokens = _tokens(query);
    return matches.where((match) {
      final home = _normalize(match.homeTeamName);
      final away = _normalize(match.awayTeamName);
      final homeTokens = _tokens(home);
      final awayTokens = _tokens(away);
      final commonHome = homeTokens.where(tokens.contains).length;
      final commonAway = awayTokens.where(tokens.contains).length;
      return commonHome > 0 || commonAway > 0;
    }).toList();
  }

  List<String> _tokens(String text) {
    const stopWords = {
      'cuando',
      'juega',
      'que',
      'el',
      'la',
      'los',
      'las',
      'en',
      'de',
      'del',
      'y',
      'vs',
      'contra',
      'por',
      'un',
      'una',
      'lo',
      'se',
      'es',
      'a',
      'para',
      'con',
      'al',
      'o',
      'me',
      'te',
      'mi',
      'su',
      'sus',
      'este',
      'esa',
      'ese',
      'otro',
      'como',
      'cual',
      'hoy',
      'ayer',
      'manana',
    };
    return text
        .split(RegExp('\s+'))
        .where((token) => token.isNotEmpty && !stopWords.contains(token))
        .toList();
  }

  String _favoriteTeamName(SportMatch match) {
    return match.homeTeamName;
  }

  String _teamNextMatchSummary(String teamName, List<SportMatch> matches) {
    final now = DateTime.now();
    final upcoming = matches.where((m) => m.startTime.isAfter(now)).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    if (upcoming.isNotEmpty) {
      final match = upcoming.first;
      return 'El próximo partido de $teamName es ${match.homeTeamName} vs ${match.awayTeamName} el ${match.startTime.toLocal()}.';
    }
    return _teamLastResultSummary(teamName, matches);
  }

  String _teamLastResultSummary(String teamName, List<SportMatch> matches) {
    final finished =
        matches
            .where((m) => m.homeScore != null && m.awayScore != null)
            .toList()
          ..sort((a, b) => b.startTime.compareTo(a.startTime));
    if (finished.isNotEmpty) {
      final last = finished.first;
      return '$teamName jugó su último partido contra ${last.homeTeamName == teamName ? last.awayTeamName : last.homeTeamName} y el resultado fue ${last.scoreLabel}.';
    }
    return 'No hay partidos finalizados para $teamName en los datos cargados.';
  }

  String _teamPreviousMatchesSummary(
    String teamName,
    List<SportMatch> matches,
  ) {
    final recent =
        matches
            .where((m) => m.homeScore != null && m.awayScore != null)
            .toList()
          ..sort((a, b) => b.startTime.compareTo(a.startTime));
    if (recent.isEmpty) {
      return 'No hay partidos pasados registrados para $teamName.';
    }
    final summary = recent
        .take(3)
        .map((match) {
          return '${match.homeTeamName} ${match.scoreLabel} ${match.awayTeamName}';
        })
        .join(' · ');
    return 'Resultados recientes de $teamName: $summary.';
  }

  String _previousMatchesSummary(List<SportMatch> matches) {
    final recent =
        matches
            .where((m) => m.homeScore != null && m.awayScore != null)
            .toList()
          ..sort((a, b) => b.startTime.compareTo(a.startTime));
    if (recent.isEmpty) {
      return 'No hay partidos pasados cargados en este momento.';
    }
    final match = recent.first;
    return '${match.homeTeamName} ${match.scoreLabel} ${match.awayTeamName} el ${match.startTime.toLocal()}.';
  }

  String _nextMatchSummary(List<SportMatch> matches) {
    final tomorrow = DateTime.now();
    final upcoming =
        matches.where((m) => m.startTime.isAfter(tomorrow)).toList()
          ..sort((a, b) => a.startTime.compareTo(b.startTime));
    if (upcoming.isEmpty) {
      return 'No hay próximos partidos cargados.';
    }
    final next = upcoming.first;
    return 'El siguiente partido es ${next.homeTeamName} vs ${next.awayTeamName} el ${next.startTime.toLocal()}.';
  }

  String _lastFinishedMatchSummary(List<SportMatch> matches) {
    final finished =
        matches
            .where((m) => m.homeScore != null && m.awayScore != null)
            .toList()
          ..sort((a, b) => b.startTime.compareTo(a.startTime));
    if (finished.isEmpty) {
      return 'No hay resultados disponibles aún.';
    }
    final last = finished.first;
    return 'El último partido finalizado fue ${last.homeTeamName} ${last.scoreLabel} ${last.awayTeamName}.';
  }

  bool standingsAvailable(List<SportMatch> matches) {
    return matches.isNotEmpty;
  }

  String _standingsSummary(String leagueName, List<SportMatch> matches) {
    return 'La liga $leagueName tiene ${matches.length} partidos cargados. Revisa la tabla de posiciones en la pantalla principal.';
  }
}
