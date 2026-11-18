/// Makes a file name safe for a file system: characters it refuses are
/// replaced, Windows' reserved names, trailing dots and spaces and an empty or
/// very long base are handled. The extension is not part of the base, so the
/// same logic serves `.pdf` reports and `.csv` exports.
class FileName {
  const FileName._();

  static final _illegal = RegExp(r'[\\/:*?"<>|\x00-\x1f]');
  static final _reserved = RegExp(
    r'^(con|prn|aux|nul|com[1-9]|lpt[1-9])$',
    caseSensitive: false,
  );
  static const _maxBaseLength = 120;

  /// `base` made safe for a file system, with `[extension]` (no dot) attached.
  static String named(String base, String extension) =>
      '${safe(base)}.$extension';

  /// A safe base for a file system name, without the extension.
  static String safe(String base) {
    var name = base.replaceAll(_illegal, '-').trim();
    if (name.length > _maxBaseLength) {
      name = name.substring(0, _maxBaseLength);
    }
    name = name.replaceAll(RegExp(r'[. ]+$'), '');
    if (name.isEmpty) {
      name = 'Report';
    } else if (_reserved.hasMatch(name)) {
      name = '$name-';
    }
    return name;
  }
}
