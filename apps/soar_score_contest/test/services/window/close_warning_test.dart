import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/services/window/close_warning.dart';
import 'package:soar_score_contest/services/window/window_title_channel.dart';
import 'package:soar_score_contest/widgets/unsaved_changes_guard.dart';

/// Plays the Windows runner: asks Dart whether the window may close.
Future<Object?> _runnerAsksToClose() async {
  const codec = StandardMethodCodec();
  final reply = Completer<ByteData?>();
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .handlePlatformMessage(
        WindowTitleChannel.channel.name,
        codec.encodeMethodCall(const MethodCall('confirmClose')),
        reply.complete,
      );
  return codec.decodeEnvelope((await reply.future)!);
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

  group('Windows close request', () {
    setUp(() {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      installCloseWarning();
    });
    tearDown(() {
      debugDefaultTargetPlatformOverride = null;
      WindowTitleChannel.channel.setMethodCallHandler(null);
    });

    test('allows the close when nothing is unsaved', () async {
      expect(await _runnerAsksToClose(), isTrue);
    });

    test('follows the page when edits are unsaved', () async {
      final guard = UnsavedChangesGuard();
      var discard = false;
      Future<bool> confirm() async => discard;
      guard.attach(confirm, hasChanges: () => true);
      addTearDown(() => guard.detach(confirm));

      expect(await _runnerAsksToClose(), isFalse);
      discard = true;
      expect(await _runnerAsksToClose(), isTrue);
    });
  });
}
