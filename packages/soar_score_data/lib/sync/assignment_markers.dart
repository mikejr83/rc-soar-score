import 'package:drift/drift.dart' show Variable;
import 'package:soar_score_core/soar_score_core.dart' as core;

import '../database.dart';
import 'sql_placeholders.dart';

/// Clears the `superseded_by_assignment_id` that points at [removed], so the
/// assignment it replaced is live again when [removed] goes.
///
/// A removal that deletes both ends of a move takes the newer row first, and
/// the older row's marker would otherwise point at a row that no longer
/// exists when the transaction commits.
Future<void> clearSupersededMarkers(SoarScoreDatabase db, core.Id removed) =>
    db.customUpdate(
      portableSql(
        db,
        'UPDATE matrix_assignments SET superseded_by_assignment_id = NULL '
        'WHERE superseded_by_assignment_id = ?',
      ),
      variables: [Variable<String>(removed.value)],
      updates: {db.matrixAssignments},
    );
