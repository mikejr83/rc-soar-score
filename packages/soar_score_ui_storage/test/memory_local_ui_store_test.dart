import 'package:soar_score_ui_storage/soar_score_ui_storage.dart';

import 'support/local_ui_store_contract.dart';

void main() {
  var backend = MemoryLocalUiBackend();
  localUiStoreContract(
    'In-memory',
    open: ({required fresh}) async {
      if (fresh) backend = MemoryLocalUiBackend();
      return backend;
    },
  );
}
