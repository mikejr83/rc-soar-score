import 'package:flutter/foundation.dart';

import '../services/ui_account/ui_account.dart';
import 'acting_account.dart';

/// The [UiAccount] of the native build: the account requests act as, which is
/// the installation's Local account until it is claimed at sign-in.
class ActingUiAccount extends ChangeNotifier implements UiAccount {
  ActingUiAccount(this._acting) : _id = _acting.id.value {
    _acting.addListener(_actingChanged);
  }

  final ActingAccount _acting;
  String _id;

  @override
  String get id => _id;

  void _actingChanged() {
    final id = _acting.id.value;
    if (id == _id) return;
    _id = id;
    notifyListeners();
  }

  @override
  void dispose() {
    _acting.removeListener(_actingChanged);
    super.dispose();
  }
}
