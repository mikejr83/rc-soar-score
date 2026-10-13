import 'package:equatable/equatable.dart';

import '../workspace_facts.dart';
import 'attention_item.dart';

/// What one source found. [available] is false when the source could not be
/// read, so an empty list is not mistaken for "nothing to see".
class AttentionResult extends Equatable {
  const AttentionResult({this.items = const [], this.available = true});

  const AttentionResult.unavailable() : items = const [], available = false;

  final List<AttentionItem> items;
  final bool available;

  @override
  List<Object?> get props => [items, available];
}

/// Something that can put rows on the needs-attention list. A new kind of
/// row is a new source; the list and the card do not change.
abstract interface class AttentionSource {
  AttentionResult read(WorkspaceFacts facts);
}
