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
        'Bonuses',
      ]);
      expect(_labels(homePath), isNot(contains('Matrix')));
    });

    test('lists contest tasks for a contest route', () {
      expect(_labels(contestWorkspacePath(_contestId)), [
        'Workspace',
        'Matrix',
        'Scoring',
        'Reports',
      ]);
    });

    test('wires Contests to the main page and Workspace to the contest', () {
      final system = shellDestinationsFor(homePath);
      expect(system.first.location, homePath);
      expect(system[1].location, participantsPath);
      expect(system.skip(2).every((d) => d.location == null), isTrue);

      final contest = shellDestinationsFor(contestWorkspacePath(_contestId));
      expect(contest.first.location, contestWorkspacePath(_contestId));
      expect(contest.skip(1).every((d) => d.location == null), isTrue);
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
