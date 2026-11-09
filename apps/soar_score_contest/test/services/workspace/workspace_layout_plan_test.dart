import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/services/workspace/workspace_control.dart';
import 'package:soar_score_contest/services/workspace/workspace_layout_plan.dart';
import 'package:soar_score_contest/services/workspace/workspace_section.dart';
import 'package:soar_score_core/soar_score_core.dart';

const _ns = WorkspaceSection.nextStep;
const _ck = WorkspaceSection.checklist;
const _iv = WorkspaceSection.invitations;
const _at = WorkspaceSection.attention;
const _pr = WorkspaceSection.progress;
const _ct = WorkspaceSection.controls;
const _fc = WorkspaceSection.facts;
const _ac = WorkspaceSection.activity;

WorkspaceLayoutPlan _plan(
  LifecycleState l, {
  bool matrix = false,
  bool attention = false,
}) => WorkspaceLayoutPlan.of(
  lifecycle: l,
  hasMatrix: matrix,
  hasAttentionItems: attention,
);

void main() {
  group('main column', () {
    for (final l in [
      LifecycleState.created,
      LifecycleState.configuring,
      LifecycleState.ready,
    ]) {
      test('${l.name} without matrix', () {
        expect(_plan(l).main, [_ns, _ck, _iv, _ac]);
      });
      test('${l.name} with matrix', () {
        expect(_plan(l, matrix: true).main, [_ns, _ck, _iv, _pr, _ac]);
      });
    }

    test('running ignores matrix and attention inputs', () {
      for (final m in [false, true]) {
        for (final a in [false, true]) {
          expect(_plan(LifecycleState.running, matrix: m, attention: a).main, [
            _ns,
            _iv,
            _at,
            _pr,
            _ac,
          ]);
        }
      }
    });

    test('completed shows attention only when there are items', () {
      expect(_plan(LifecycleState.completed).main, [_ns, _pr, _ac]);
      expect(_plan(LifecycleState.completed, attention: true).main, [
        _ns,
        _pr,
        _at,
        _ac,
      ]);
    });

    test('checklist is absent from running onward', () {
      for (final l in [LifecycleState.running, LifecycleState.completed]) {
        final p = _plan(l, matrix: true, attention: true);
        expect([...p.main, ...p.side, ...p.single], isNot(contains(_ck)));
      }
    });

    test('invitations sit right under the checklist while setting up', () {
      for (final l in [
        LifecycleState.created,
        LifecycleState.configuring,
        LifecycleState.ready,
      ]) {
        final main = _plan(l).main;
        expect(main.indexOf(_iv), main.indexOf(_ck) + 1);
      }
    });

    test('invitations are absent once completed', () {
      expect(_plan(LifecycleState.completed).single, isNot(contains(_iv)));
    });

    test('progress is absent before running without a matrix', () {
      for (final l in [
        LifecycleState.created,
        LifecycleState.configuring,
        LifecycleState.ready,
      ]) {
        expect(_plan(l).single, isNot(contains(_pr)));
      }
    });
  });

  group('side column and single column', () {
    test('side is always controls then facts', () {
      for (final l in LifecycleState.values) {
        expect(_plan(l).side, [_ct, _fc]);
      }
    });

    test('single is main without activity, then controls, facts, activity', () {
      for (final l in LifecycleState.values) {
        for (final m in [false, true]) {
          for (final a in [false, true]) {
            final p = _plan(l, matrix: m, attention: a);
            expect(p.single, [...p.main.where((s) => s != _ac), _ct, _fc, _ac]);
          }
        }
      }
    });

    test('running single order matches design frame 1h', () {
      expect(_plan(LifecycleState.running).single, [
        _ns,
        _iv,
        _at,
        _pr,
        _ct,
        _fc,
        _ac,
      ]);
    });
  });

  group('control order', () {
    const c = WorkspaceControl.values;
    test('before running', () {
      for (final l in [
        LifecycleState.created,
        LifecycleState.configuring,
        LifecycleState.ready,
      ]) {
        expect(_plan(l).controls, [
          WorkspaceControl.lifecycle,
          WorkspaceControl.scoring,
          WorkspaceControl.administration,
          WorkspaceControl.publication,
          WorkspaceControl.archive,
        ]);
      }
    });

    test('running', () {
      expect(_plan(LifecycleState.running).controls, [
        WorkspaceControl.scoring,
        WorkspaceControl.results,
        WorkspaceControl.publication,
        WorkspaceControl.administration,
        WorkspaceControl.lifecycle,
        WorkspaceControl.archive,
      ]);
    });

    test('completed', () {
      expect(_plan(LifecycleState.completed).controls, [
        WorkspaceControl.publication,
        WorkspaceControl.lifecycle,
        WorkspaceControl.scoring,
        WorkspaceControl.administration,
        WorkspaceControl.archive,
      ]);
    });

    test('results only while running; archive always last', () {
      expect(c, contains(WorkspaceControl.results));
      for (final l in LifecycleState.values) {
        final controls = _plan(l).controls;
        expect(
          controls.contains(WorkspaceControl.results),
          l == LifecycleState.running,
        );
        expect(controls.last, WorkspaceControl.archive);
      }
    });
  });

  test('ids are unique and stable', () {
    expect(WorkspaceSection.values.map((s) => s.id).toSet().length, 8);
    expect(WorkspaceControl.values.map((s) => s.id).toSet().length, 6);
    expect(WorkspaceControl.lifecycle.id, 'lifecycle');
    expect(WorkspaceSection.nextStep.id, 'next-step');
  });
}
