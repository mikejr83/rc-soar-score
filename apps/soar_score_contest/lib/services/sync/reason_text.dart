/// A reason code spelled out as a sentence, for example `stale_base` as
/// `Stale base.`; [fallback] when there is no code.
String reasonText(String? code, {String fallback = 'No reason was given.'}) {
  if (code == null || code.isEmpty) return fallback;
  final words = code.replaceAll('_', ' ');
  return '${words[0].toUpperCase()}${words.substring(1)}.';
}
