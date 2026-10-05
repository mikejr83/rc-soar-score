/// The environment holds missing or invalid settings.
class ConfigException implements Exception {
  ConfigException(this.problems);

  /// One human-readable line per problem.
  final List<String> problems;

  @override
  String toString() =>
      'Invalid server configuration:\n${problems.map((p) => '  - $p').join('\n')}';
}
