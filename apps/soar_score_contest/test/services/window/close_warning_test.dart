import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/services/window/close_warning.dart';
import 'package:soar_score_contest/widgets/unsaved_changes_guard.dart';

/// Plays the engine: the user closed the window, so ask whether to exit.
Future<Object?> _windowCloseRequested() async {
  const codec = JSONMethodCodec();
  final reply = Completer<ByteData?>();
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .handlePlatformMessage(
        SystemChannels.platform.name,
        codec.encodeMethodCall(const MethodCall('System.requestAppExit')),
        reply.complete,
      );
  final answer = codec.decodeEnvelope((await reply.future)!) as Map;
  return answer['response'];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UnsavedChangesGuard registry', () {
    test('reports unsaved edits only while a dirty page is attached', () {
      final guard = UnsavedChangesGuard();
      var dirty = false;
      Future<bool> confirm() async => !dirty;

      expect(UnsavedChangesGuard.anyUnsavedChanges, isFalse);
      guard.attach(confirm, hasChanges: () => dirty);
      expect(UnsavedChangesGuard.anyUnsavedChanges, isFalse);
      dirty = true;
      expect(UnsavedChangesGuard.anyUnsavedChanges, isTrue);
      guard.detach(confirm);
      expect(UnsavedChangesGuard.anyUnsavedChanges, isFalse);
    });

    test('pages can tell a close from a navigation', () async {
      final guard = UnsavedChangesGuard();
      final seen = <bool>[];
      Future<bool> confirm() async {
        seen.add(UnsavedChangesGuard.closingApp);
        return true;
      }

      guard.attach(confirm);
      addTearDown(() => guard.detach(confirm));

      await guard.confirmLeave();
      await UnsavedChangesGuard.confirmCloseAll();
      expect(seen, [false, true]);
      expect(UnsavedChangesGuard.closingApp, isFalse);
    });

    test('a second close request joins the question being asked', () async {
      final guard = UnsavedChangesGuard();
      final answer = Completer<bool>();
      var asked = 0;
      Future<bool> confirm() {
        asked++;
        return answer.future;
      }

      guard.attach(confirm, hasChanges: () => true);
      addTearDown(() => guard.detach(confirm));

      final first = UnsavedChangesGuard.confirmCloseAll();
      final second = UnsavedChangesGuard.confirmCloseAll();
      answer.complete(false);
      expect([await first, await second], [false, false]);
      expect(asked, 1);
    });

    test('a refusal from any page stops the close', () async {
      final clean = UnsavedChangesGuard();
      final dirty = UnsavedChangesGuard();
      Future<bool> allow() async => true;
      Future<bool> refuse() async => false;
      clean.attach(allow);
      dirty.attach(refuse, hasChanges: () => true);
      addTearDown(() {
        clean.detach(allow);
        dirty.detach(refuse);
      });

      expect(await UnsavedChangesGuard.confirmCloseAll(), isFalse);
      dirty.detach(refuse);
      expect(await UnsavedChangesGuard.confirmCloseAll(), isTrue);
    });
  });

  group('window close request', () {
    setUpAll(installCloseWarning);

    test('allows the close when nothing is unsaved', () async {
      expect(await _windowCloseRequested(), 'exit');
    });

    test('follows the page when edits are unsaved', () async {
      final guard = UnsavedChangesGuard();
      var discard = false;
      Future<bool> confirm() async => discard;
      guard.attach(confirm, hasChanges: () => true);
      addTearDown(() => guard.detach(confirm));

      expect(await _windowCloseRequested(), 'cancel');
      discard = true;
      expect(await _windowCloseRequested(), 'exit');
    });
  });
}
