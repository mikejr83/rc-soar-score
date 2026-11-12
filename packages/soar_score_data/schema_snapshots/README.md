# Database schema snapshots

The SQL files capture Drift-generated table definitions and the project's custom indexes for SQLite and PostgreSQL. They cover both native and server profiles; migration tests select the tables belonging to the profile under test. Treat a published version's snapshots as immutable.

Version 1 was reconstructed from the version 2 Drift export by removing the new `pilot_import_links` table; no other table definitions or custom indexes changed in this migration. Version 2 is the first frozen baseline. Before a later schema change ships, increment `schemaVersion`, add a transactional upgrade step and run `dart run tool/export_schema_snapshot.dart` from `packages/soar_score_data` to freeze that version. Add tests that open the previous snapshot with representative data, upgrade, verify preservation and exercise rollback on both backends. Also review sync and contest-file compatibility.

The version 1 to 2 upgrade creates the pilot-link table and does not rewrite existing records. If a version 1 alpha database already has a compatible pilot-link table, the upgrade preserves it and its rows. If its structure is incompatible, the upgrade stops without modifying it; inspect and back up that database before resolving the conflict. Never delete a user's database as a migration step.

Before deploying an upgrade, create and verify backups of the service database and users' local databases using the applicable backup procedure. The migration itself does not create backups. Rehearse upgrades and restoration on copies before rollout.

The service accepts clients with the same schema version only. Deploy the upgraded service before upgrading clients; version 1 clients cannot sync with the version 2 service until upgraded, and version 2 clients cannot sync with a version 1 service. Version 2 imports version 1 contest exports, whose format does not include pilot links.
