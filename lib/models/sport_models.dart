enum Sport { football, basketball }

class LeagueOption {
  const LeagueOption({
    required this.name,
    required this.sport,
    required this.apiCode,
    this.apiFootballId,
    required this.standingsCode,
    required this.displayName,
  });

  final String name;
  final Sport sport;
  final String apiCode;
  final int? apiFootballId;
  final String standingsCode;
  final String displayName;
}

class SportMatch {
  const SportMatch({
    required this.id,
    required this.sport,
    required this.leagueName,
    required this.homeTeamName,
    required this.awayTeamName,
    required this.homeLogoUrl,
    required this.awayLogoUrl,
    required this.startTime,
    required this.status,
    required this.homeScore,
    required this.awayScore,
    required this.minute,
    required this.venue,
    required this.rawData,
  });

  final String id;
  final Sport sport;
  final String leagueName;
  final String homeTeamName;
  final String awayTeamName;
  final String homeLogoUrl;
  final String awayLogoUrl;
  final DateTime startTime;
  final String status;
  final int? homeScore;
  final int? awayScore;
  final String minute;
  final String venue;
  final Map<String, dynamic> rawData;

  bool get isLive =>
      status.toLowerCase().contains('live') ||
      status.toLowerCase().contains('final');

  String get scoreLabel {
    if (homeScore == null || awayScore == null) {
      return 'Sin resultado';
    }
    return '$homeScore - $awayScore';
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      'id': id,
      'sport': sport.name,
      'leagueName': leagueName,
      'homeTeamName': homeTeamName,
      'awayTeamName': awayTeamName,
      'homeLogoUrl': homeLogoUrl,
      'awayLogoUrl': awayLogoUrl,
      'startTime': startTime.toIso8601String(),
      'status': status,
      'homeScore': homeScore,
      'awayScore': awayScore,
      'minute': minute,
      'venue': venue,
    };
  }

  factory SportMatch.fromFirestoreMap(Map<String, dynamic> data) {
    return SportMatch(
      id: data['id'] as String,
      sport: Sport.values.firstWhere(
        (element) => element.name == data['sport'],
        orElse: () => Sport.football,
      ),
      leagueName: data['leagueName'] as String,
      homeTeamName: data['homeTeamName'] as String,
      awayTeamName: data['awayTeamName'] as String,
      homeLogoUrl: data['homeLogoUrl'] as String,
      awayLogoUrl: data['awayLogoUrl'] as String,
      startTime: DateTime.parse(data['startTime'] as String),
      status: data['status'] as String,
      homeScore: data['homeScore'] as int?,
      awayScore: data['awayScore'] as int?,
      minute: data['minute'] as String,
      venue: data['venue'] as String,
      rawData: {},
    );
  }
}

class StandingEntry {
  const StandingEntry({
    required this.rank,
    required this.teamName,
    required this.played,
    required this.wins,
    required this.draws,
    required this.losses,
    required this.goalsFor,
    required this.goalsAgainst,
    required this.goalDifference,
    required this.points,
    required this.logoUrl,
  });

  final int rank;
  final String teamName;
  final int played;
  final int wins;
  final int draws;
  final int losses;
  final int goalsFor;
  final int goalsAgainst;
  final int goalDifference;
  final int points;
  final String logoUrl;
}

class ChatMessage {
  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });

  final String text;
  final bool isUser;
  final DateTime timestamp;
}
