import 'package:drift/native.dart';
import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_data/soar_score_data.dart';

/// An in-memory installation database with the pieces under test.
class Installation {
  Installation._(this.db, this.stores) {
    unitOfWork = DriftUnitOfWork(
      db,
      stores,
      clock: () => DateTime.utc(2026, 5, 1, 12),
    );
    applier = DriftReplicatedChangeApplier(db, stores);
    syncStore = DriftSyncStore(db);
  }

  factory Installation.open() {
    final db = SoarScoreDatabase(
      NativeDatabase.memory(),
      profile: DatabaseProfile.native,
    );
    return Installation._(db, EntityStores.forDatabase(db));
  }

  final SoarScoreDatabase db;
  final EntityStores stores;
  late final DriftUnitOfWork unitOfWork;
  late final DriftReplicatedChangeApplier applier;
  late final DriftSyncStore syncStore;

  Future<int> count(String table) async =>
      (await db.customSelect('SELECT COUNT(*) AS n FROM $table').getSingle())
          .read<int>('n');
}

var _requests = 0;

core.MutationMetadata metadata({String? requestId}) => core.MutationMetadata(
  clientMutationId: requestId ?? 'request-${_requests++}',
  authority: core.Authority.director,
  clientTime: DateTime.utc(2026, 5, 1, 11),
);

core.Contest contest({
  String name = 'Spring Meet',
  int revision = 0,
  core.Id? id,
}) => core.Contest(
  id: id ?? core.Id.create(),
  name: name,
  startDateTime: DateTime.utc(2026, 4, 15, 10, 30),
  endDateTime: DateTime.utc(2026, 4, 16, 20),
  timezone: 'America/Denver',
  createdAt: DateTime.utc(2026, 4),
  updatedAt: DateTime.utc(2026, 4),
  revision: revision,
);
