@TestOn('browser')
library;

import 'package:soar_score_ui_storage/src/indexed_db_local_ui_backend.dart';
import 'package:test/test.dart';

import 'support/local_ui_store_contract.dart';

void main() {
  var counter = 0;
  late String name;
  localUiStoreContract(
    'IndexedDB',
    open: ({required fresh}) {
      if (fresh) {
        name =
            'soar_score_ui_test_${counter++}_${DateTime.now().microsecondsSinceEpoch}';
      }
      return IndexedDbLocalUiBackend.open(databaseName: name);
    },
  );
}
