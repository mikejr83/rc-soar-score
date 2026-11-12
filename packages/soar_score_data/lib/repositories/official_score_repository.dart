import 'package:soar_score_core/soar_score_core.dart' as core;

import 'audit_event_repository.dart';
import 'drift_repository.dart';
import 'latest_timestamps.dart';

/// Official scores in the database; append-only.
class OfficialScoreRepository extends DriftRepository
    implements core.OfficialScoreRepository {
  OfficialScoreRepository(super.db, {super.stores});

  late final _audits = AuditEventRepository(db, stores: stores);
  late final _store = store<core.OfficialScore>('OfficialScore');

  @override
  Future<core.OfficialScore?> findById(core.Id id) => _store.find(id);

  @override
  Future<List<core.OfficialScore>> listForPlaceholder(
    core.Id scorePlaceholderId,
  ) => _store.whereId(
    'score_placeholder_id',
    scorePlaceholderId,
    orderBy: 'score_revision',
  );

  @override
  Future<core.OfficialScore?> currentForPlaceholder(
    core.Id scorePlaceholderId,
  ) async {
    final scores = await listForPlaceholder(scorePlaceholderId);
    return scores.isEmpty ? null : scores.last;
  }

  @override
  Future<Map<core.Id, core.OfficialScore>> currentForPlaceholders(
    Iterable<core.Id> scorePlaceholderIds,
  ) async {
    final scores = await _store.whereIdIn(
      'score_placeholder_id',
      scorePlaceholderIds,
    );
    final current = <core.Id, core.OfficialScore>{};
    for (final score in scores) {
      final best = current[score.scorePlaceholderId];
      if (best == null || score.scoreRevision > best.scoreRevision) {
        current[score.scorePlaceholderId] = score;
      }
    }
    return current;
  }

  @override
  Future<Map<core.Id, DateTime>> latestSetAtForContests(
    Iterable<core.Id> contestIds,
  ) => latestTimestampByContest(
    db,
    table: 'official_scores',
    column: 'set_at',
    contestIds: contestIds,
  );

  @override
  Future<core.OfficialScore> append(
    core.OfficialScore score, {
    required core.MutationMetadata metadata,
  }) => unitOfWork.run((context) => context.append(score, metadata: metadata));

  @override
  Future<core.OfficialScore> recordOfficial(
    core.OfficialScore score,
    core.ScorePlaceholder placeholder, {
    required core.MutationMetadata metadata,
  }) {
    if (placeholder.id != score.scorePlaceholderId) {
      throw ArgumentError('the placeholder is not the score\'s');
    }
    if (placeholder.scoreRevision != score.scoreRevision) {
      throw ArgumentError(
        'the placeholder carries score revision ${placeholder.scoreRevision}, '
        'the score is revision ${score.scoreRevision}',
      );
    }
    return unitOfWork.run((context) async {
      await context.append(score, metadata: metadata);
      await context.save(
        placeholder,
        metadata: metadata.forPart(placeholder.id.value),
      );
      return score;
    });
  }

  @override
  Future<core.PromotedScore> recordPromotion(
    core.PromotedScore promotion, {
    required core.MutationMetadata metadata,
  }) {
    final score = promotion.officialScore;
    final placeholder = promotion.placeholder;
    if (placeholder.id != score.scorePlaceholderId) {
      throw ArgumentError('the placeholder is not the score\'s');
    }
    if (placeholder.scoreRevision != score.scoreRevision) {
      throw ArgumentError(
        'the placeholder carries score revision ${placeholder.scoreRevision}, '
        'the score is revision ${score.scoreRevision}',
      );
    }
    for (final review in promotion.supersededReviews) {
      if (review.scorePlaceholderId != placeholder.id) {
        throw ArgumentError('a superseded review is not the slot\'s');
      }
    }
    return unitOfWork.run((context) async {
      await context.append(score, metadata: metadata);
      final saved = await context.save(
        placeholder,
        metadata: metadata.forPart(placeholder.id.value),
      );
      final reviews = <core.ReviewRequest>[
        for (final review in promotion.supersededReviews)
          await context.save(
            review,
            metadata: metadata.forPart(review.id.value),
          ),
      ];
      for (final audit in promotion.audits) {
        await _audits.append(audit);
      }
      return core.PromotedScore(
        officialScore: score,
        placeholder: saved,
        supersededReviews: reviews,
        audits: promotion.audits,
      );
    });
  }

  @override
  Future<core.RecordedScore> recordEntry(
    core.RecordedScore entry, {
    required core.MutationMetadata metadata,
  }) {
    _check(entry);
    return unitOfWork.run((context) => _storeEntry(context, entry, metadata));
  }

  @override
  Future<List<core.RecordedScore>> recordEntries(
    List<core.RecordedScore> entries, {
    required core.MutationMetadata metadata,
  }) {
    for (final entry in entries) {
      _check(entry);
    }
    return unitOfWork.run((context) async {
      final saved = <core.RecordedScore>[];
      for (final entry in entries) {
        // Each entry is its own part of the request, so its mutation ids
        // stay unique and a repeated request derives the same ones.
        saved.add(
          await _storeEntry(
            context,
            entry,
            metadata.forPart(entry.attempt.clientMutationId),
          ),
        );
      }
      return saved;
    });
  }

  void _check(core.RecordedScore entry) {
    final score = entry.officialScore;
    final placeholder = entry.placeholder;
    if (placeholder.id != score.scorePlaceholderId ||
        placeholder.id != entry.attempt.scorePlaceholderId) {
      throw ArgumentError('the placeholder is not the entry\'s');
    }
    if (score.scoreAttemptId != entry.attempt.id) {
      throw ArgumentError('the official score is not taken from the attempt');
    }
    if (placeholder.scoreRevision != score.scoreRevision) {
      throw ArgumentError(
        'the placeholder carries score revision ${placeholder.scoreRevision}, '
        'the score is revision ${score.scoreRevision}',
      );
    }
  }

  Future<core.RecordedScore> _storeEntry(
    core.WriteContext context,
    core.RecordedScore entry,
    core.MutationMetadata metadata,
  ) async {
    final score = entry.officialScore;
    final placeholder = entry.placeholder;
    await context.append(entry.attempt, metadata: metadata);
    await context.append(score, metadata: metadata.forPart(score.id.value));
    final saved = await context.save(
      placeholder,
      metadata: metadata.forPart(placeholder.id.value),
    );
    final contest = entry.contest;
    final savedContest = contest == null
        ? null
        : await context.save(
            contest,
            metadata: metadata.forPart(contest.id.value),
          );
    final audit = entry.audit;
    if (audit != null) await _audits.append(audit);
    return core.RecordedScore(
      attempt: entry.attempt,
      officialScore: score,
      placeholder: saved,
      contest: savedContest,
      audit: audit,
    );
  }
}
