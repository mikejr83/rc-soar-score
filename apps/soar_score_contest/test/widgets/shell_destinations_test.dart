import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/router.dart';
import 'package:soar_score_contest/widgets/shell_destinations.dart';

const String _contestId = '01890a5d-ac96-774b-bcce-b302099a8057';

List<String> _labels(String path) =>
    shellDestinationsFor(path).map((destination) => destination.label).toList();

void main() {
  group('contestIdFor', () {
    test('returns the id segment of contest routes', () {
      expect(contestIdFor(contestWorkspacePath(_contestId)), _contestId);
      expect(contestIdFor('$contestsPath/$_contestId'), _contestId);
    });

    test('returns null outside the contest routes', () {
      expect(contestIdFor(homePath), isNull);
      expect(contestIdFor('$homePath/workspace'), isNull);
      expect(contestIdFor(contestsPath), isNull);
      expect(contestIdFor('$contestsPath/'), isNull);
      expect(contestIdFor(newContestPath), isNull);
      expect(shellScopeFor(newContestPath), ShellScope.system);
    });
  });

  group('shellScopeFor', () {
    test('is system on the main page and below it', () {
      expect(shellScopeFor(homePath), ShellScope.system);
      expect(shellScopeFor('$homePath/workspace'), ShellScope.system);
    });

    test('is contest on contest routes', () {
      expect(
        shellScopeFor(contestWorkspacePath(_contestId)),
        ShellScope.contest,
      );
    });
  });

  group('shellDestinationsFor', () {
    test('lists system-level destinations without contest tasks', () {
      expect(_labels(homePath), [
        'Contests',
        'Participants',
        'Roles',
        'Landings',
      ]);
      expect(_labels(homePath), isNot(contains('Matrix')));
    });

    test('lists contest tasks for a contest route', () {
      expect(_labels(contestWorkspacePath(_contestId)), [
        'Workspace',
        'Configuration',
        'Participants',
        'Matrix',
        'Scoring',
        'Reports',
      ]);
    });

    test('adds Sync last in a contest only when the build syncs', () {
      final path = contestWorkspacePath(_contestId);
      final labels = [
        for (final d in shellDestinationsFor(path, showSync: true)) d.label,
      ];
      expect(labels.last, 'Sync');
      expect(
        shellDestinationsFor(path, showSync: true).last.location,
        contestSyncPath(_contestId),
      );
      expect([
        for (final d in shellDestinationsFor(homePath, showSync: true)) d.label,
      ], isNot(contains('Sync')));
    });

    test('wires Contests to the main page and Workspace to the contest', () {
      final system = shellDestinationsFor(homePath);
      expect(system.first.location, homePath);
      expect(system[1].location, participantsPath);
      expect(system[2].location, rolesPath);
      expect(system[3].location, landingsPath);

      final contest = shellDestinationsFor(contestWorkspacePath(_contestId));
      expect(contest.first.location, contestWorkspacePath(_contestId));
      expect(contest[1].location, contestConfigurationPath(_contestId));
      expect(contest[3].location, contestMatrixPath(_contestId));
    });

    test('Landings uses the track_changes icon', () {
      final landings = shellDestinationsFor(homePath)[3];
      expect(landings.icon, Icons.track_changes);
      expect(landings.selectedIcon, Icons.track_changes);
    });

    test('a destination matches its page and pages below it only', () {
      final contests = shellDestinationsFor(homePath).first;
      expect(contests.matches(homePath), isTrue);
      expect(contests.matches('$homePath/workspace'), isTrue);
      expect(contests.matches('${homePath}x'), isFalse);
      expect(shellDestinationsFor(homePath)[1].matches(homePath), isFalse);
      expect(
        shellDestinationsFor(homePath)[1].matches(newParticipantPath),
        isTrue,
      );
    });
  });
}
