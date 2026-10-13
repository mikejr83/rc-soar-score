import 'package:equatable/equatable.dart';

/// The kinds of row the needs-attention list can show. The review and sync
/// rows arrive with their own tickets (#375, #376).
enum AttentionKind { missingScores, reviewRequests, rejectedSync }

/// One row of the needs-attention list: a count, what it is, the detail and
/// where it is fixed.
class AttentionItem extends Equatable {
  const AttentionItem({
    required this.kind,
    required this.count,
    required this.title,
    required this.detail,
    required this.linkLabel,
    this.scoringRound,
    this.opensSync = false,
  });

  final AttentionKind kind;

  /// The number in the badge.
  final int count;

  /// For example "4 scores missing in finished rounds".
  final String title;

  /// For example "Round 2: 1, Round 3: 3".
  final String detail;

  /// The text of the link button.
  final String linkLabel;

  /// The round the link opens in Scoring; `null` when the row links
  /// elsewhere.
  final int? scoringRound;

  /// True when the link opens the contest's sync details.
  final bool opensSync;

  @override
  List<Object?> get props => [
    kind,
    count,
    title,
    detail,
    linkLabel,
    scoringRound,
    opensSync,
  ];
}
