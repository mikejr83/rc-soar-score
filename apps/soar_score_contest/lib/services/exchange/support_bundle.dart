import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:soar_score_data/soar_score_data.dart';

/// The `.rcsoar` file of an export for support: a zip holding the contest
/// file as it is exported, a manifest about the installation it came from,
/// and the app log. A plain export is the contest file alone.
const supportManifestEntry = 'manifest.json';
const supportContestEntry = 'contest.json';
const supportLogEntry = 'app.log';

/// The zip of a support export.
Uint8List encodeSupportBundle({
  required Map<String, Object?> manifest,
  required List<int> contest,
  required String log,
}) {
  final archive = Archive()
    ..addFile(
      ArchiveFile.bytes(
        supportManifestEntry,
        utf8.encode(const JsonEncoder.withIndent(' ').convert(manifest)),
      ),
    )
    ..addFile(ArchiveFile.bytes(supportContestEntry, contest))
    ..addFile(ArchiveFile.bytes(supportLogEntry, utf8.encode(log)));
  return Uint8List.fromList(ZipEncoder().encode(archive));
}

/// Whether [bytes] start like a zip file.
bool isSupportBundle(List<int> bytes) =>
    bytes.length > 4 &&
    bytes[0] == 0x50 &&
    bytes[1] == 0x4b &&
    bytes[2] == 0x03 &&
    bytes[3] == 0x04;

/// The contest file inside [bytes]: the entry of a support export, or
/// [bytes] themselves when they are a plain export.
///
/// Throws an [ExchangeException] for a zip that has no contest file or whose
/// contest file would be larger than a contest export can be.
List<int> contestFileOf(List<int> bytes) {
  if (!isSupportBundle(bytes)) return bytes;
  const notContest = ExchangeException(
    'not_a_contest_file',
    'The file is not a contest export.',
  );
  if (bytes.length > exchangeMaxBytes) {
    throw const ExchangeException(
      'too_large',
      'The file is larger than a contest export can be.',
    );
  }
  final Archive archive;
  try {
    archive = ZipDecoder().decodeBytes(bytes);
  } on Object {
    throw notContest;
  }
  final entry = archive.findFile(supportContestEntry);
  // The declared size is checked before anything is inflated.
  if (entry == null || !entry.isFile) throw notContest;
  if (entry.size > exchangeMaxBytes) {
    throw const ExchangeException(
      'too_large',
      'The file is larger than a contest export can be.',
    );
  }
  final content = entry.readBytes() ?? (throw notContest);
  // The header's declared size is advisory, so the inflated length is checked
  // too: a file that inflates past the cap, or whose header disagrees with its
  // content, is refused.
  if (content.length > exchangeMaxBytes) {
    throw const ExchangeException(
      'too_large',
      'The file is larger than a contest export can be.',
    );
  }
  if (entry.size > 0 && content.length != entry.size) throw notContest;
  return content;
}
