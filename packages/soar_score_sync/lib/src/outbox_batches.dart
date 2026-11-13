import 'dart:convert';

import 'package:soar_score_core/soar_score_core.dart';
import 'package:soar_score_api/soar_score_api.dart';

import 'sync_mappers.dart';

/// Room left in a request for what changes between batches: the cursor's
/// digits and the first-upload flag.
const int exchangeEnvelopeMargin = 1024;

/// The outbox cut into exchanges that each fit the service's limits.
class OutboxBatches {
  const OutboxBatches(this.batches, this.oversized);

  /// Dependency-ordered batches; their concatenation is [pending] without the
  /// [oversized] mutations.
  final List<List<MutationRecord>> batches;

  /// Mutations that exceed the byte limit even alone. They can never be sent.
  final List<MutationRecord> oversized;
}

/// Cuts [pending] (already in dependency order) into batches of at most
/// [maxMutations] mutations whose whole request body stays within
/// [maxBytes].
///
/// [envelopeBytes] is the UTF-8 length of the request with no mutations (its
/// scope, versions and cursor). A batch's size is that plus the exact length
/// of each mutation as it is serialized and the commas between them, with
/// [exchangeEnvelopeMargin] to spare. Multibyte text counts in bytes.
///
/// A mutation is [oversized] only when the exact request that carries it
/// alone ([soloBytes]) exceeds [maxBytes]; one that fits only without the
/// margin goes in a batch of its own.
OutboxBatches splitOutbox(
  List<MutationRecord> pending, {
  required int envelopeBytes,
  required int Function(MutationRecord mutation) soloBytes,
  int maxBytes = syncExchangeMaxBodyBytes,
  int maxMutations = syncExchangeMaxMutations,
}) {
  final room = maxBytes - envelopeBytes - exchangeEnvelopeMargin;
  final batches = <List<MutationRecord>>[];
  final oversized = <MutationRecord>[];
  var current = <MutationRecord>[];
  var used = 0;
  for (final mutation in pending) {
    final size = utf8
        .encode(jsonEncode(mutationToDto(mutation).toJson()))
        .length;
    if (size > room) {
      if (soloBytes(mutation) > maxBytes) {
        oversized.add(mutation);
      } else {
        if (current.isNotEmpty) batches.add(current);
        batches.add([mutation]);
        current = <MutationRecord>[];
        used = 0;
      }
      continue;
    }
    final next = used + size + (current.isEmpty ? 0 : 1);
    if (current.isNotEmpty && (next > room || current.length >= maxMutations)) {
      batches.add(current);
      current = <MutationRecord>[];
      used = 0;
    }
    used += size + (current.isEmpty ? 0 : 1);
    current.add(mutation);
  }
  if (current.isNotEmpty) batches.add(current);
  return OutboxBatches(batches, oversized);
}
