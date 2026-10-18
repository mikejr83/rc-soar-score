import 'package:flutter/widgets.dart';

import 'services/ui_account/ui_account.dart';

/// Exposes the [UiAccount] to the widget tree. Mirrors
/// `LocalUiStoreInherited`; dependents rebuild when the account changes.
class UiAccountInherited extends InheritedNotifier<UiAccount> {
  const UiAccountInherited({
    super.key,
    required UiAccount account,
    required super.child,
  }) : super(notifier: account);
}

/// The [UiAccount] in scope, or `null` when none is provided (tests that pump
/// pages bare).
UiAccount? uiAccountOf(BuildContext context) =>
    context.dependOnInheritedWidgetOfExactType<UiAccountInherited>()?.notifier;

/// The account id to key `LocalUiStore` calls by: the Local account's id when
/// no [UiAccount] is provided. Rebuilds the caller when the account changes.
String uiAccountIdOf(BuildContext context) =>
    uiAccountOf(context)?.id ?? localUiAccountId;
