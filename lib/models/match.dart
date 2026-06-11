import 'team.dart';

/// Match statuses as defined by the football-data.org v4 API.
enum MatchStatus {
  scheduled,
  timed,
  inPlay,
  paused,
  finished,
  suspended,
  postponed,
  cancelled,
  awarded,
  unknown;

  static MatchStatus fromApi(String? value) => switch (value) {
        'SCHEDULED' => scheduled,
        'TIMED' => timed,
        'IN_PLAY' => inPlay,
        'PAUSED' => paused,
        'FINISHED' => finished,
        'SUSPENDED' => suspended,
        'POSTPONED' => postponed,
        'CANCELLED' => cancelled,
        'AWARDED' => awarded,
        _ => unknown,
      };

  String toApi() => switch (this) {
        scheduled => 'SCHEDULED',
        timed => 'TIMED',
        inPlay => 'IN_PLAY',
        paused => 'PAUSED',
        finished => 'FINISHED',
        suspended => 'SUSPENDED',
        postponed => 'POSTPONED',
        cancelled => 'CANCELLED',
        awarded => 'AWARDED',
        unknown => 'UNKNOWN',
      };
}

/// Tournament stages, ordered chronologically for the bracket view.
enum Stage {
  groupStage('GROUP_STAGE', 'Group stage'),
  last32('LAST_32', 'Round of 32'),
  last16('LAST_16', 'Round of 16'),
  quarterFinals('QUARTER_FINALS', 'Quarter-finals'),
  semiFinals('SEMI_FINALS', 'Semi-finals'),
  thirdPlace('THIRD_PLACE', 'Third place'),
  finalStage('FINAL', 'Final'),
  unknown('UNKNOWN', 'Unknown');

  const Stage(this.api, this.label);
  final String api;
  final String label;

  static Stage fromApi(String? value) =>
      Stage.values.firstWhere((s) => s.api == value, orElse: () => unknown);
}

class Score {
  const Score({
    this.winner,
    this.duration,
    this.fullTimeHome,
    this.fullTimeAway,
    this.halfTimeHome,
    this.halfTimeAway,
  });

  final String? winner; // HOME_TEAM | AWAY_TEAM | DRAW
  final String? duration; // REGULAR | EXTRA_TIME | PENALTY_SHOOTOUT
  final int? fullTimeHome;
  final int? fullTimeAway;
  final int? halfTimeHome;
  final int? halfTimeAway;

  factory Score.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const Score();
    final fullTime = json['fullTime'] as Map<String, dynamic>?;
    final halfTime = json['halfTime'] as Map<String, dynamic>?;
    return Score(
      winner: json['winner'] as String?,
      duration: json['duration'] as String?,
      fullTimeHome: fullTime?['home'] as int?,
      fullTimeAway: fullTime?['away'] as int?,
      halfTimeHome: halfTime?['home'] as int?,
      halfTimeAway: halfTime?['away'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'winner': winner,
        'duration': duration,
        'fullTime': {'home': fullTimeHome, 'away': fullTimeAway},
        'halfTime': {'home': halfTimeHome, 'away': halfTimeAway},
      };
}

class WcMatch {
  const WcMatch({
    required this.id,
    required this.utcDate,
    required this.status,
    required this.stage,
    this.matchday,
    this.group,
    this.homeTeam = const TeamRef(),
    this.awayTeam = const TeamRef(),
    this.score = const Score(),
    this.venue,
    this.lastUpdated,
  });

  final int id;
  final DateTime utcDate;
  final MatchStatus status;
  final Stage stage;
  final int? matchday;
  final String? group; // GROUP_A .. GROUP_L
  final TeamRef homeTeam;
  final TeamRef awayTeam;
  final Score score;
  final String? venue;
  final DateTime? lastUpdated;

  DateTime get localKickoff => utcDate.toLocal();

  bool get isLive =>
      status == MatchStatus.inPlay || status == MatchStatus.paused;

  bool get isFinished =>
      status == MatchStatus.finished || status == MatchStatus.awarded;

  bool get isUpcoming =>
      status == MatchStatus.scheduled || status == MatchStatus.timed;

  /// "Group A" from "GROUP_A", or the stage label for knockout matches.
  String get stageOrGroupLabel {
    final g = group;
    if (g != null) return 'Group ${g.substring(g.length - 1)}';
    return stage.label;
  }

  /// "2 – 1" while live or finished, null otherwise.
  String? get displayScore {
    final home = score.fullTimeHome, away = score.fullTimeAway;
    if (home == null || away == null) return null;
    return '$home – $away';
  }

  factory WcMatch.fromJson(Map<String, dynamic> json) => WcMatch(
        id: json['id'] as int,
        utcDate: DateTime.parse(json['utcDate'] as String),
        status: MatchStatus.fromApi(json['status'] as String?),
        stage: Stage.fromApi(json['stage'] as String?),
        matchday: json['matchday'] as int?,
        group: json['group'] as String?,
        homeTeam: TeamRef.fromJson(json['homeTeam'] as Map<String, dynamic>?),
        awayTeam: TeamRef.fromJson(json['awayTeam'] as Map<String, dynamic>?),
        score: Score.fromJson(json['score'] as Map<String, dynamic>?),
        venue: json['venue'] as String?,
        lastUpdated: json['lastUpdated'] != null
            ? DateTime.tryParse(json['lastUpdated'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'utcDate': utcDate.toUtc().toIso8601String(),
        'status': status.toApi(),
        'stage': stage.api,
        'matchday': matchday,
        'group': group,
        'homeTeam': homeTeam.toJson(),
        'awayTeam': awayTeam.toJson(),
        'score': score.toJson(),
        'venue': venue,
        'lastUpdated': lastUpdated?.toUtc().toIso8601String(),
      };
}
