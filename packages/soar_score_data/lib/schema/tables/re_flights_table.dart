import 'package:drift/drift.dart';

import '../../contests_table.dart';
import '../enum_values.dart';
import 'contest_configuration_revisions_table.dart';
import 'rounds_table.dart';

/// `ReFlight`: the table of re flights, one column per model field.
@DataClassName('ReFlightData')
class ReFlights extends Table {
  TextColumn get id => text()();
  TextColumn get contestId =>
      text().references(Contests, #id, onDelete: KeyAction.cascade)();
  TextColumn get creditedRoundId => text().references(Rounds, #id)();
  TextColumn get sourceRoundId => text().references(Rounds, #id)();
  IntColumn get sourceGroup => integer()();
  TextColumn get type => text().check(type.isIn(reFlightTypeValues))();
  IntColumn get sequence => integer()();
  TextColumn get previousReflightId =>
      text().nullable().references(ReFlights, #id)();
  TextColumn get status => text().check(status.isIn(reFlightStatusValues))();
  TextColumn get reason => text()();
  TextColumn get scheduledRoundId => text().references(Rounds, #id)();
  IntColumn get flownGroup => integer()();
  BoolColumn get deviationAcknowledged => boolean()();
  IntColumn get requestedGroupSize => integer().nullable()();
  IntColumn get achievableMaxSize => integer().nullable()();
  BoolColumn get sizeExceptionConfirmed => boolean()();
  IntColumn get randomSeed => integer().nullable()();
  TextColumn get algorithmVersion => text().nullable()();
  TextColumn get configRevisionId =>
      text().references(ContestConfigurationRevisions, #id)();
  TextColumn get createdBy => text()();
  TextColumn get createdAt => text()();
  TextColumn get groupFinalizedBy => text().nullable()();
  TextColumn get groupFinalizedAt => text().nullable()();
  TextColumn get finalizedBy => text().nullable()();
  TextColumn get finalizedAt => text().nullable()();
  TextColumn get cancelledBy => text().nullable()();
  TextColumn get cancelledAt => text().nullable()();
  TextColumn get cancelReason => text().nullable()();
  IntColumn get revision => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {sourceRoundId, sourceGroup, sequence},
  ];
}

/// Columns of `re_flights` that hold JSON as text.
const reFlightsJsonColumns = <String>{};
