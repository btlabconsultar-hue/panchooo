import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/sport_models.dart';

class SportsService {
  SportsService({http.Client? client, String? apiFootballKey})
    : _client = client ?? http.Client(),
      _apiFootballKey = apiFootballKey ?? '';

  final http.Client _client;
  String _apiFootballKey;

  bool get hasFootballKey => _apiFootballKey.isNotEmpty;
  String get apiFootballKey => _apiFootballKey;

  void setApiFootballKey(String key) {
    _apiFootballKey = key;
  }

  static List<LeagueOption> leaguesFor(Sport sport) {
    switch (sport) {
      case Sport.football:
        return const [
          LeagueOption(
            name: 'liga_profesional',
            sport: Sport.football,
            apiCode: 'arg.1',
            apiFootballId: 128,
            standingsCode: '4406',
            displayName: 'Liga Profesional Argentina',
          ),
          LeagueOption(
            name: 'primera_nacional',
            sport: Sport.football,
            apiCode: 'arg.2',
            apiFootballId: 4634,
            standingsCode: '4616',
            displayName: 'Primera Nacional',
          ),
        ];
      case Sport.basketball:
        return const [
          LeagueOption(
            name: 'nba',
            sport: Sport.basketball,
            apiCode: 'nba',
            standingsCode: '4387',
            displayName: 'NBA',
          ),
        ];
    }
  }

  Future<List<SportMatch>> fetchMatches({
    required Sport sport,
    required LeagueOption league,
    DateTime? from,
    DateTime? to,
  }) async {
    if (sport == Sport.football &&
        hasFootballKey &&
        league.apiFootballId != null) {
      return _fetchFootballMatches(league: league, from: from, to: to);
    }

    return _fetchLegacyMatches(
      sport: sport,
      league: league,
      from: from,
      to: to,
    );
  }

  Future<List<SportMatch>> _fetchFootballMatches({
    required LeagueOption league,
    DateTime? from,
    DateTime? to,
  }) async {
    final season = DateTime.now().year;
    final queryParameters = <String, String>{
      'league': league.apiFootballId!.toString(),
      'season': season.toString(),
      'timezone': 'America/Argentina/Buenos_Aires',
    };
    if (from != null) {
      queryParameters['from'] = _formatApiFootballDate(from);
    }
    if (to != null) {
      queryParameters['to'] = _formatApiFootballDate(to);
    }

    final uri = Uri.https(
      'v3.football.api-sports.io',
      '/fixtures',
      queryParameters,
    );
    final response = await _client.get(
      uri,
      headers: {'x-apisports-key': _apiFootballKey},
    );

    if (response.statusCode != 200) {
      return _fetchLegacyMatches(
        sport: Sport.football,
        league: league,
        from: from,
        to: to,
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final fixtures = decoded['response'] as List<dynamic>? ?? <dynamic>[];

    return fixtures
        .map(
          (item) =>
              _parseApiFootballFixture(item as Map<String, dynamic>, league),
        )
        .toList();
  }

  Future<List<SportMatch>> _fetchLegacyMatches({
    required Sport sport,
    required LeagueOption league,
    DateTime? from,
    DateTime? to,
  }) async {
    final baseUri = Uri.parse(
      'https://site.api.espn.com/apis/site/v2/sports/${sport == Sport.football ? 'soccer' : 'basketball'}/${league.apiCode}/scoreboard',
    );

    final queryParameters = <String, String>{};
    if (from != null && to != null) {
      queryParameters['dates'] = '${_formatDate(from)}-${_formatDate(to)}';
    }

    final uri = queryParameters.isEmpty
        ? baseUri
        : baseUri.replace(queryParameters: queryParameters);
    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      if (queryParameters.isNotEmpty) {
        final fallback = await _client.get(baseUri);
        if (fallback.statusCode == 200) {
          return _parseMatchesFromBody(fallback.body, sport, league);
        }
      }
      throw Exception(
        'No se pudieron cargar los partidos (${response.statusCode}).',
      );
    }

    return _parseMatchesFromBody(response.body, sport, league);
  }

  String _formatApiFootballDate(DateTime time) {
    final year = time.year.toString().padLeft(4, '0');
    final month = time.month.toString().padLeft(2, '0');
    final day = time.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  List<SportMatch> _parseMatchesFromBody(
    String body,
    Sport sport,
    LeagueOption league,
  ) {
    final decoded = jsonDecode(body) as Map<String, dynamic>;
    final events = decoded['events'] as List<dynamic>? ?? <dynamic>[];

    return events.map((event) => _parseEvent(event, sport, league)).toList();
  }

  SportMatch _parseApiFootballFixture(
    Map<String, dynamic> item,
    LeagueOption league,
  ) {
    final fixture =
        item['fixture'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final teams = item['teams'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final goals = item['goals'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final leagueInfo =
        item['league'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final status =
        fixture['status'] as Map<String, dynamic>? ?? <String, dynamic>{};

    final homeTeam =
        teams['home'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final awayTeam =
        teams['away'] as Map<String, dynamic>? ?? <String, dynamic>{};

    final startTime =
        DateTime.tryParse(fixture['date']?.toString() ?? '') ?? DateTime.now();
    final elapsed = status['elapsed']?.toString() ?? '';
    final statusText =
        status['long']?.toString() ?? status['short']?.toString() ?? 'Próximo';

    return SportMatch(
      id:
          fixture['id']?.toString() ??
          '${league.apiCode}-${DateTime.now().millisecondsSinceEpoch}',
      sport: Sport.football,
      leagueName: leagueInfo['name']?.toString() ?? league.displayName,
      homeTeamName: homeTeam['name']?.toString() ?? 'Equipo local',
      awayTeamName: awayTeam['name']?.toString() ?? 'Equipo visitante',
      homeLogoUrl: homeTeam['logo']?.toString() ?? '',
      awayLogoUrl: awayTeam['logo']?.toString() ?? '',
      startTime: startTime,
      status: statusText,
      homeScore: _parseScore(goals['home']),
      awayScore: _parseScore(goals['away']),
      minute: elapsed.isEmpty ? '' : elapsed,
      venue: fixture['venue']?['name']?.toString() ?? 'Sin estadio',
      rawData: item,
    );
  }

  Future<List<StandingEntry>> fetchStandings({
    required Sport sport,
    required LeagueOption league,
  }) async {
    if (sport == Sport.football &&
        hasFootballKey &&
        league.apiFootballId != null) {
      return _fetchFootballStandings(league);
    }

    final uri = Uri.parse(
      'https://www.thesportsdb.com/api/v1/json/3/lookuptable.php?l=${league.standingsCode}',
    );

    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      throw Exception('No se pudo cargar la tabla (${response.statusCode}).');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final rows = decoded['table'] as List<dynamic>? ?? <dynamic>[];

    return rows.map((row) => _parseStanding(row)).toList();
  }

  Future<List<StandingEntry>> _fetchFootballStandings(
    LeagueOption league,
  ) async {
    final season = DateTime.now().year;
    final uri = Uri.https('v3.football.api-sports.io', '/standings', {
      'league': league.apiFootballId!.toString(),
      'season': season.toString(),
    });

    final response = await _client.get(
      uri,
      headers: {'x-apisports-key': _apiFootballKey},
    );

    if (response.statusCode != 200) {
      return _fetchStandingsLegacy(league);
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final responseList = decoded['response'] as List<dynamic>? ?? <dynamic>[];
    if (responseList.isEmpty) {
      return _fetchStandingsLegacy(league);
    }

    final standingsRoot = responseList.first['league'] as Map<String, dynamic>?;
    final table = standingsRoot?['standings'] as List<dynamic>?;
    final rows = table?.first as List<dynamic>? ?? <dynamic>[];

    return rows.map((row) {
      final data = row as Map<String, dynamic>;
      return StandingEntry(
        rank: data['rank'] as int? ?? 0,
        teamName: data['team']?['name']?.toString() ?? 'Equipo',
        played: data['all']?['played'] as int? ?? 0,
        wins: data['all']?['win'] as int? ?? 0,
        draws: data['all']?['draw'] as int? ?? 0,
        losses: data['all']?['lose'] as int? ?? 0,
        goalsFor: data['all']?['goals']?['for'] as int? ?? 0,
        goalsAgainst: data['all']?['goals']?['against'] as int? ?? 0,
        goalDifference: data['goalsDiff'] as int? ?? 0,
        points: data['points'] as int? ?? 0,
        logoUrl: data['team']?['logo']?.toString() ?? '',
      );
    }).toList();
  }

  Future<List<StandingEntry>> _fetchStandingsLegacy(LeagueOption league) async {
    final uri = Uri.parse(
      'https://www.thesportsdb.com/api/v1/json/3/lookuptable.php?l=${league.standingsCode}',
    );

    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      throw Exception('No se pudo cargar la tabla (${response.statusCode}).');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final rows = decoded['table'] as List<dynamic>? ?? <dynamic>[];
    return rows.map((row) => _parseStanding(row)).toList();
  }

  SportMatch _parseEvent(dynamic event, Sport sport, LeagueOption league) {
    final eventMap = event as Map<String, dynamic>;
    final competition =
        (eventMap['competitions'] as List<dynamic>?)?.firstOrNull
            as Map<String, dynamic>?;
    final competitors =
        (competition?['competitors'] as List<dynamic>?) ?? <dynamic>[];
    final status =
        competition?['status'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final type = status['type'] as Map<String, dynamic>? ?? <String, dynamic>{};

    final homeCompetitor =
        competitors.firstWhere(
              (item) => item['homeAway'] == 'home',
              orElse: () => null,
            )
            as Map<String, dynamic>?;
    final awayCompetitor =
        competitors.firstWhere(
              (item) => item['homeAway'] == 'away',
              orElse: () => null,
            )
            as Map<String, dynamic>?;

    final homeTeam =
        homeCompetitor?['team'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final awayTeam =
        awayCompetitor?['team'] as Map<String, dynamic>? ?? <String, dynamic>{};

    final homeScore = _parseScore(homeCompetitor?['score']);
    final awayScore = _parseScore(awayCompetitor?['score']);
    final startTime =
        DateTime.tryParse(eventMap['date']?.toString() ?? '') ?? DateTime.now();

    return SportMatch(
      id:
          eventMap['id']?.toString() ??
          '${league.apiCode}-${DateTime.now().millisecondsSinceEpoch}',
      sport: sport,
      leagueName: league.displayName,
      homeTeamName: homeTeam['displayName']?.toString() ?? 'Equipo local',
      awayTeamName: awayTeam['displayName']?.toString() ?? 'Equipo visitante',
      homeLogoUrl: homeTeam['logo']?.toString() ?? '',
      awayLogoUrl: awayTeam['logo']?.toString() ?? '',
      startTime: startTime,
      status:
          type['detail']?.toString() ??
          type['shortDetail']?.toString() ??
          'Próximo',
      homeScore: homeScore,
      awayScore: awayScore,
      minute: _formatMinute(status),
      venue:
          (competition?['venue'] as Map<String, dynamic>?)?['fullName']
              ?.toString() ??
          'Sin estadio',
      rawData: eventMap,
    );
  }

  StandingEntry _parseStanding(dynamic row) {
    final standing = row as Map<String, dynamic>;
    return StandingEntry(
      rank: int.tryParse(standing['intRank']?.toString() ?? '0') ?? 0,
      teamName: standing['strTeam']?.toString() ?? 'Equipo',
      played: int.tryParse(standing['intPlayed']?.toString() ?? '0') ?? 0,
      wins: int.tryParse(standing['intWin']?.toString() ?? '0') ?? 0,
      draws: int.tryParse(standing['intDraw']?.toString() ?? '0') ?? 0,
      losses: int.tryParse(standing['intLoss']?.toString() ?? '0') ?? 0,
      goalsFor: int.tryParse(standing['intGoalsFor']?.toString() ?? '0') ?? 0,
      goalsAgainst:
          int.tryParse(standing['intGoalsAgainst']?.toString() ?? '0') ?? 0,
      goalDifference:
          int.tryParse(standing['intGoalDifference']?.toString() ?? '0') ?? 0,
      points: int.tryParse(standing['intPoints']?.toString() ?? '0') ?? 0,
      logoUrl: standing['strBadge']?.toString() ?? '',
    );
  }

  int? _parseScore(dynamic value) {
    if (value == null) {
      return null;
    }
    return int.tryParse(value.toString());
  }

  String _formatDate(DateTime time) {
    final year = time.year.toString().padLeft(4, '0');
    final month = time.month.toString().padLeft(2, '0');
    final day = time.day.toString().padLeft(2, '0');
    return '$year$month$day';
  }

  String _formatMinute(Map<String, dynamic> status) {
    final displayClock = status['displayClock']?.toString() ?? '';
    final period = status['period']?.toString() ?? '';
    if (displayClock.isNotEmpty) {
      return displayClock;
    }
    if (period.isNotEmpty) {
      return 'Q$period';
    }
    return '';
  }
}

extension ListExtension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
