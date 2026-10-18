import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/local_ui_store_provider.dart';
import 'package:soar_score_ui_storage/soar_score_ui_storage.dart';

void main() {
  testWidgets('gives the store to descendants, or null without one', (
    tester,
  ) async {
    final store = BackendLocalUiStore(MemoryLocalUiBackend());
    LocalUiStore? provided;
    LocalUiStore? bare;
    final probe = Builder(
      builder: (context) {
        provided = localUiStoreOf(context);
        return const SizedBox();
      },
    );
    await tester.pumpWidget(LocalUiStoreInherited(store: store, child: probe));
    expect(provided, same(store));

    await tester.pumpWidget(
      Builder(
        builder: (context) {
          bare = localUiStoreOf(context);
          return const SizedBox();
        },
      ),
    );
    expect(bare, isNull);
  });
}
