import 'dart:io';

/// Writes a small file the import can fingerprint and returns its path. The
/// content stands in for a GliderScore `.mdb`, which the journey never reads.
Future<String> writeGliderScoreFixtureFile(String content) async {
  final dir = await Directory.systemTemp.createTemp('soar_gs_e2e');
  final file = File('${dir.path}${Platform.pathSeparator}E2E Contests.mdb');
  await file.writeAsString(content);
  return file.path;
}
