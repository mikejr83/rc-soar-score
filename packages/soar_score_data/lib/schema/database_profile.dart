import 'table_group.dart';

/// Which table groups a database creates, chosen where it is opened.
enum DatabaseProfile {
  /// An offline installation: everything except the backend-only group.
  native({
    TableGroup.contest,
    TableGroup.director,
    TableGroup.system,
    TableGroup.issued,
    TableGroup.derived,
    TableGroup.clientOnly,
  }),

  /// The service: every group except the client-only one.
  server({
    TableGroup.contest,
    TableGroup.director,
    TableGroup.system,
    TableGroup.issued,
    TableGroup.derived,
    TableGroup.backendOnly,
  });

  const DatabaseProfile(this.groups);

  final Set<TableGroup> groups;
}
