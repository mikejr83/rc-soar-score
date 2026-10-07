import 'package:soar_score_core/soar_score_core.dart';

/// Whether [profile] matches the free-text [query] typed in the participant
/// search box.
///
/// The query is split on whitespace and every word must appear (ignoring
/// case) in the first name, last name, email, FAI number or national
/// organization ID, so `ada love`, `lovelace ada` and `ada@ex` all find
/// Ada Lovelace. A blank query matches everyone.
bool matchesParticipantSearch(ParticipantProfile profile, String query) {
  final words = query
      .toLowerCase()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty);
  final fields = [
    profile.firstName,
    profile.lastName,
    profile.email,
    profile.faiNumber,
    profile.nationalOrgId,
  ].whereType<String>().map((field) => field.toLowerCase()).toList();
  return words.every((word) => fields.any((field) => field.contains(word)));
}
