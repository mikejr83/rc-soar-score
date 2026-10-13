import 'package:equatable/equatable.dart';

import '../workspace_facts.dart';
import 'attention_item.dart';
import 'attention_source.dart';
import 'missing_scores_source.dart';

/// The needs-attention list for one set of facts.
///
/// The empty-state sentence says only what the sources can verify. Until the
/// review and sync sources exist (#375, #376) that is the scores; each source
/// that lands widens the sentence.
class NeedsAttention extends Equatable {
  const NeedsAttention({this.items = const [], this.complete = true});

  /// The sources the list reads, in the order their rows appear.
  static const List<AttentionSource> defaultSources = [MissingScoresSource()];

  /// The words under "Nothing needs attention".
  static const String emptyTitle = 'Nothing needs attention';
  static const String emptyText = 'Every finished round has all its scores.';

  /// Shown instead of the empty state when a source could not be read.
  static const String incompleteText =
      'Some of this could not be loaded, so it may be incomplete.';

  factory NeedsAttention.of(
    WorkspaceFacts facts, {
    List<AttentionSource> sources = defaultSources,
  }) {
    final items = <AttentionItem>[];
    var complete = true;
    for (final source in sources) {
      final result = source.read(facts);
      items.addAll(result.items);
      complete = complete && result.available;
    }
    return NeedsAttention(items: List.unmodifiable(items), complete: complete);
  }

  final List<AttentionItem> items;

  /// False when a source could not be read; the list may be missing rows.
  final bool complete;

  bool get hasItems => items.isNotEmpty;

  /// True only when every source was read and found nothing.
  bool get isAllClear => items.isEmpty && complete;

  /// The quiet line beside the card title.
  String get summary => switch (items.length) {
    0 => isAllClear ? 'All clear' : 'Not available',
    1 => '1 item',
    final n => '$n items',
  };

  @override
  List<Object?> get props => [items, complete];
}
