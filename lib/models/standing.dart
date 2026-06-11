import 'team.dart';

class TableEntry {
  const TableEntry({
    required this.position,
    required this.team,
    required this.playedGames,
    required this.won,
    required this.draw,
    required this.lost,
    required this.points,
    required this.goalsFor,
    required this.goalsAgainst,
    required this.goalDifference,
  });

  final int position;
  final TeamRef team;
  final int playedGames;
  final int won;
  final int draw;
  final int lost;
  final int points;
  final int goalsFor;
  final int goalsAgainst;
  final int goalDifference;

  factory TableEntry.fromJson(Map<String, dynamic> json) => TableEntry(
        position: json['position'] as int? ?? 0,
        team: TeamRef.fromJson(json['team'] as Map<String, dynamic>?),
        playedGames: json['playedGames'] as int? ?? 0,
        won: json['won'] as int? ?? 0,
        draw: json['draw'] as int? ?? 0,
        lost: json['lost'] as int? ?? 0,
        points: json['points'] as int? ?? 0,
        goalsFor: json['goalsFor'] as int? ?? 0,
        goalsAgainst: json['goalsAgainst'] as int? ?? 0,
        goalDifference: json['goalDifference'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'position': position,
        'team': team.toJson(),
        'playedGames': playedGames,
        'won': won,
        'draw': draw,
        'lost': lost,
        'points': points,
        'goalsFor': goalsFor,
        'goalsAgainst': goalsAgainst,
        'goalDifference': goalDifference,
      };
}

class GroupStanding {
  const GroupStanding({required this.group, required this.table});

  final String group; // GROUP_A .. GROUP_L
  final List<TableEntry> table;

  String get label => 'Group ${group.substring(group.length - 1)}';

  /// The live API is inconsistent: matches use "GROUP_A" but standings use
  /// "Group A". Normalize both to "GROUP_A".
  static String _normalizeGroup(String raw) => raw.startsWith('GROUP_')
      ? raw
      : 'GROUP_${raw[raw.length - 1].toUpperCase()}';

  /// Parses the `standings` array of the v4 response, keeping only
  /// `type == "TOTAL"` entries (HOME/AWAY splits are not relevant here).
  static List<GroupStanding> listFromJson(List<dynamic> standings) {
    return standings
        .cast<Map<String, dynamic>>()
        .where((s) => s['type'] == 'TOTAL' && s['group'] != null)
        .map((s) => GroupStanding(
              group: _normalizeGroup(s['group'] as String),
              table: (s['table'] as List<dynamic>? ?? [])
                  .cast<Map<String, dynamic>>()
                  .map(TableEntry.fromJson)
                  .toList(),
            ))
        .toList()
      ..sort((a, b) => a.group.compareTo(b.group));
  }

  Map<String, dynamic> toJson() => {
        'stage': 'GROUP_STAGE',
        'type': 'TOTAL',
        'group': group,
        'table': table.map((e) => e.toJson()).toList(),
      };
}
