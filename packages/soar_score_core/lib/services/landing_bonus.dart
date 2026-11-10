import '../errors/scoring_validation_error.dart';
import '../models/contest/contest_configuration_revision.dart';
import '../models/landing/landing_table_with_results.dart';
import '../repositories/repository.dart';
import '../scoring/profile/scoring_issue.dart';

/// The landing points of the `landing` entry in [components], taken from the
/// landing table of [revision]; 0 when no landing was entered.
///
/// Throws a [ScoringValidationError] when the contest has no landing table
/// to score a landing with, or the entry is not one of the table's.
Future<double> resolveLandingBonus(
  Repository repository,
  ContestConfigurationRevision revision,
  Map<String, Object?> components,
) async {
  final entry = components['landing'];
  if (entry == null) return 0;
  final tableId = revision.landingTableId;
  final table = tableId == null
      ? null
      : await repository.landingTableRepository.findById(tableId);
  return landingPoints(table, entry);
}

/// The points of [entry] in [table]; throws a [ScoringValidationError] when
/// there is no table or the entry is not one of its.
double landingPoints(LandingTableWithResults? table, Object entry) {
  if (table == null) {
    throw ScoringValidationError(const [
      ScoringIssue(
        code: 'not_allowed',
        fieldId: 'landing',
        message: 'The contest has no landing table to score a landing.',
      ),
    ]);
  }
  for (final result in table.results) {
    if (result.entryKey == entry) return result.pointValue.toDouble();
  }
  throw ScoringValidationError([
    ScoringIssue(
      code: 'not_allowed',
      fieldId: 'landing',
      message: '"$entry" is not an entry of the contest\'s landing table.',
    ),
  ]);
}

/// Resolves landing points for many flights of one contest, reading the
/// landing table at most once.
///
/// Gives the same points, and throws the same errors, as
/// [resolveLandingBonus]: a flight without a landing entry scores 0 and needs
/// no table.
class LandingBonusResolver {
  LandingBonusResolver(this.repository, this.revision);

  final Repository repository;
  final ContestConfigurationRevision revision;

  Future<LandingTableWithResults?>? _table;

  Future<double> bonusOf(Map<String, Object?> components) async {
    final entry = components['landing'];
    if (entry == null) return 0;
    final tableId = revision.landingTableId;
    final table = await (_table ??= tableId == null
        ? Future.value(null)
        : repository.landingTableRepository.findById(tableId));
    return landingPoints(table, entry);
  }
}
