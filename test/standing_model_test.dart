import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:football/models/standing.dart';

void main() {
  test('parses the standings fixture', () {
    final raw = json.decode(
            File('test/fixtures/standings_sample.json').readAsStringSync())
        as Map<String, dynamic>;
    final standings = GroupStanding.listFromJson(raw['standings'] as List);

    expect(standings, hasLength(1));
    final groupA = standings.first;
    expect(groupA.group, 'GROUP_A');
    expect(groupA.label, 'Group A');
    expect(groupA.table, hasLength(4));

    final leader = groupA.table.first;
    expect(leader.position, 1);
    expect(leader.team.tla, 'MEX');
    expect(leader.points, 3);
    expect(leader.goalDifference, 1);
  });

  test('ignores non-TOTAL standing types', () {
    final standings = GroupStanding.listFromJson([
      {'stage': 'GROUP_STAGE', 'type': 'HOME', 'group': 'GROUP_A', 'table': []},
      {'stage': 'GROUP_STAGE', 'type': 'TOTAL', 'group': 'GROUP_B', 'table': []},
    ]);
    expect(standings, hasLength(1));
    expect(standings.first.group, 'GROUP_B');
  });

  test('the bundled seed standings parse into 12 groups of 4', () {
    final raw = json.decode(
            File('assets/seed/wc2026_seed.json').readAsStringSync())
        as Map<String, dynamic>;
    final standings = GroupStanding.listFromJson(raw['standings'] as List);
    expect(standings, hasLength(12));
    for (final s in standings) {
      expect(s.table, hasLength(4));
    }
    expect(standings.first.group, 'GROUP_A');
    expect(standings.last.group, 'GROUP_L');
  });
}
