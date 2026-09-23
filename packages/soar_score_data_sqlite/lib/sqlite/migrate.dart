import 'package:drift/drift.dart';

/// Initial schema migration (schema version 1): creates the minimal
/// `contests` table.
Future<void> migrateToVersion1(Migrator migrator) => migrator.createAll();
