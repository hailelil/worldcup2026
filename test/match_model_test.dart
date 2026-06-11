import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:football/models/match.dart';

void main() {
  late List<Map<String, dynamic>> fixtures;

  setUpAll(() {
    final raw = json.decode(
            File('test/fixtures/matches_sample.json').readAsStringSync())
        as Map<String, dynamic>;
    fixtures = (raw['matches'] as List).cast<Map<String, dynamic>>();
  });

  test('parses a finished group match', () {
    final match = WcMatch.fromJson(fixtures[0]);
    expect(match.id, 1);
    expect(match.status, MatchStatus.finished);
    expect(match.isFinished, isTrue);
    expect(match.isLive, isFalse);
    expect(match.stage, Stage.groupStage);
    expect(match.group, 'GROUP_A');
    expect(match.stageOrGroupLabel, 'Group A');
    expect(match.homeTeam.name, 'Mexico');
    expect(match.awayTeam.tla, 'RSA');
    expect(match.score.fullTimeHome, 2);
    expect(match.score.fullTimeAway, 1);
    expect(match.score.halfTimeHome, 1);
    expect(match.score.winner, 'HOME_TEAM');
    expect(match.displayScore, '2 – 1');
    expect(match.venue, 'Estadio Azteca');
    expect(match.utcDate.isUtc, isTrue);
  });

  test('parses a live match', () {
    final match = WcMatch.fromJson(fixtures[1]);
    expect(match.status, MatchStatus.inPlay);
    expect(match.isLive, isTrue);
    expect(match.isFinished, isFalse);
    expect(match.displayScore, '1 – 1');
  });

  test('tolerates TBD knockout matches with null teams, score and venue', () {
    final match = WcMatch.fromJson(fixtures[2]);
    expect(match.stage, Stage.last16);
    expect(match.group, isNull);
    expect(match.stageOrGroupLabel, 'Round of 16');
    expect(match.homeTeam.isPlaceholder, isTrue);
    expect(match.homeTeam.displayName, 'TBD');
    expect(match.displayScore, isNull);
    expect(match.venue, isNull);
    expect(match.isUpcoming, isTrue);
  });

  test('survives a JSON round-trip', () {
    for (final fixture in fixtures) {
      final match = WcMatch.fromJson(fixture);
      final reparsed = WcMatch.fromJson(match.toJson());
      expect(reparsed.id, match.id);
      expect(reparsed.status, match.status);
      expect(reparsed.utcDate, match.utcDate);
      expect(reparsed.homeTeam.name, match.homeTeam.name);
      expect(reparsed.score.fullTimeHome, match.score.fullTimeHome);
      expect(reparsed.displayScore, match.displayScore);
    }
  });

  test('unknown status and stage values do not throw', () {
    final mutated = Map<String, dynamic>.from(fixtures[0])
      ..['status'] = 'SOMETHING_NEW'
      ..['stage'] = 'BONUS_ROUND';
    final match = WcMatch.fromJson(mutated);
    expect(match.status, MatchStatus.unknown);
    expect(match.stage, Stage.unknown);
  });

  test('the bundled seed parses completely', () {
    final raw = json.decode(
            File('assets/seed/wc2026_seed.json').readAsStringSync())
        as Map<String, dynamic>;
    final matches = (raw['matches'] as List)
        .cast<Map<String, dynamic>>()
        .map(WcMatch.fromJson)
        .toList();
    expect(matches, hasLength(104));
    expect(matches.where((m) => m.stage == Stage.groupStage), hasLength(72));
    expect(matches.where((m) => m.stage == Stage.last32), hasLength(16));
    expect(matches.where((m) => m.stage == Stage.finalStage), hasLength(1));
    expect(matches.where((m) => m.stage == Stage.thirdPlace), hasLength(1));
    // Opening match: Mexico vs South Africa at the Azteca.
    expect(matches.first.homeTeam.name, 'Mexico');
    expect(matches.first.venue, 'Estadio Azteca');
  });
}
