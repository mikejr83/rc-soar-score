import '../models/imports/pilot_import_draft.dart';
import '../models/imports/pilot_import_match.dart';
import '../models/imports/pilot_import_link.dart';
import '../models/participants/participant_profile.dart';

/// Matches drafted pilots against a director's existing participants.
///
/// Pure. Order of rules: email, FAI number, national organization ID, and
/// only then name, which is never automatic: it only produces a "likely"
/// match for a person to decide. Changes nothing and merges nothing.
///
/// An exact match is an update: a non-blank value from the file replaces the
/// profile's value, a blank one never clears it. Names are never overwritten,
/// and neither is the field the match was made on.
class PilotImportMatcher {
  const PilotImportMatcher();

  List<PilotMatch> match(
    List<PilotDraft> drafts,
    List<ParticipantProfile> existing, {
    List<PilotImportLink> links = const [],
  }) {
    final result = <PilotMatch>[];
    final seen = <PilotDraft>[];

    for (final draft in drafts) {
      final found = _find(draft, existing);
      final duplicateOf = _earlierSamePerson(draft, seen);
      seen.add(draft);

      final remembered = links.where(
        (l) =>
            l.sourceSystem == PilotImportLink.gliderScore6 &&
            l.sourcePilotNo == draft.sourcePilotNo,
      );
      final link = remembered.length == 1 ? remembered.single : null;
      final target = link == null
          ? <ParticipantProfile>[]
          : existing.where((p) => p.id == link.participantProfileId).toList();
      if (target.length == 1) {
        final profile = target.single;
        final identifierConflict =
            found.rule != null &&
            found.rule != PilotMatchRule.name &&
            found.profiles.any((p) => p.id != profile.id);
        final candidates = <ParticipantProfile>[
          profile,
          if (identifierConflict)
            ...found.profiles.where((p) => p.id != profile.id),
        ];
        final values = sourceValues(draft);
        final sourceChanges = [
          for (final e in values.entries)
            if (link!.sourceValues[e.key] != e.value)
              PilotFieldChange(
                field: e.key,
                from: link.sourceValues[e.key] as String?,
                to: e.value as String? ?? '—',
              ),
        ];
        final changed = sourceChanges.isNotEmpty;
        result.add(
          PilotMatch(
            draft: draft,
            kind: identifierConflict
                ? PilotMatchKind.likely
                : PilotMatchKind.exact,
            candidateIds: [for (final p in candidates) p.id],
            candidateRevisions: {for (final p in candidates) p.id: p.revision},
            rule: PilotMatchRule.name,
            conflict: identifierConflict,
            changes: _changes(draft, profile, PilotMatchRule.name),
            duplicateOfSourcePilotNo: duplicateOf?.sourcePilotNo,
            remembered: true,
            sourceChanged: changed,
            sourceChanges: sourceChanges,
          ),
        );
        continue;
      }

      final exactOne =
          found.rule != null &&
          found.rule != PilotMatchRule.name &&
          found.profiles.length == 1;
      final kind = found.profiles.isEmpty
          ? PilotMatchKind.newPilot
          : exactOne
          ? PilotMatchKind.exact
          : PilotMatchKind.likely;

      result.add(
        PilotMatch(
          draft: draft,
          kind: kind,
          candidateIds: [for (final p in found.profiles) p.id],
          candidateRevisions: {
            for (final p in found.profiles) p.id: p.revision,
          },
          rule: found.rule,
          conflict: found.conflict,
          changes: kind == PilotMatchKind.exact
              ? _changes(draft, found.profiles.single, found.rule!)
              : const [],
          duplicateOfSourcePilotNo: duplicateOf?.sourcePilotNo,
        ),
      );
    }
    return result;
  }

  /// Normalized source values used to detect changes since confirmation.
  static Map<String, Object?> sourceValues(PilotDraft d) {
    String? value(String? s) {
      final v = s?.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
      return v == null || v.isEmpty ? null : v;
    }

    return {
      'firstName': value(d.firstName),
      'lastName': value(d.lastName),
      'email': normalizeEmail(d.email),
      'faiNumber': normalizeNumber(d.faiNumber),
      'nationalOrgId': normalizeNumber(d.nationalOrgId),
      'club': value(d.club),
      'city': value(d.city),
      'state': value(d.state),
      'country': value(d.country),
    };
  }

  /// Every strong identifier the draft has (email, FAI number, national
  /// organization ID) is looked up. If they all point at one profile, that is
  /// the match. If they point at different profiles, or one identifier
  /// matches several, the match is not automatic: all of the profiles are
  /// returned as candidates and [conflict] is set when they disagree. Name is
  /// tried only when no identifier matched anything.
  static ({
    PilotMatchRule? rule,
    List<ParticipantProfile> profiles,
    bool conflict,
  })
  _find(PilotDraft draft, List<ParticipantProfile> existing) {
    final email = normalizeEmail(draft.email);
    final fai = normalizeNumber(draft.faiNumber);
    final org = normalizeNumber(draft.nationalOrgId);

    final strong = <(PilotMatchRule, bool Function(ParticipantProfile)?)>[
      (
        PilotMatchRule.email,
        email == null ? null : (p) => normalizeEmail(p.email) == email,
      ),
      (
        PilotMatchRule.faiNumber,
        fai == null ? null : (p) => normalizeNumber(p.faiNumber) == fai,
      ),
      (
        PilotMatchRule.nationalOrgId,
        org == null ? null : (p) => normalizeNumber(p.nationalOrgId) == org,
      ),
    ];

    PilotMatchRule? rule;
    final profiles = <ParticipantProfile>[];
    var matchedKeys = 0;
    var multipleOnOneKey = false;
    for (final (keyRule, test) in strong) {
      if (test == null) {
        continue;
      }
      final matched = existing.where(test).toList();
      if (matched.isEmpty) {
        continue;
      }
      matchedKeys++;
      rule ??= keyRule;
      if (matched.length > 1) {
        multipleOnOneKey = true;
      }
      for (final profile in matched) {
        if (!profiles.any((p) => p.id == profile.id)) {
          profiles.add(profile);
        }
      }
    }
    if (profiles.isNotEmpty) {
      return (
        rule: rule,
        profiles: profiles,
        conflict: profiles.length > 1 && (matchedKeys > 1 || multipleOnOneKey),
      );
    }

    final name = normalizeName(draft.firstName, draft.lastName);
    final byName = existing
        .where((p) => normalizeName(p.firstName, p.lastName) == name)
        .toList();
    return (
      rule: byName.isEmpty ? null : PilotMatchRule.name,
      profiles: byName,
      conflict: false,
    );
  }

  /// The first earlier draft that is the same person by email, FAI number,
  /// national organization ID or name.
  static PilotDraft? _earlierSamePerson(
    PilotDraft draft,
    List<PilotDraft> earlier,
  ) {
    final email = normalizeEmail(draft.email);
    final fai = normalizeNumber(draft.faiNumber);
    final org = normalizeNumber(draft.nationalOrgId);
    final name = normalizeName(draft.firstName, draft.lastName);
    for (final other in earlier) {
      if ((email != null && email == normalizeEmail(other.email)) ||
          (fai != null && fai == normalizeNumber(other.faiNumber)) ||
          (org != null && org == normalizeNumber(other.nationalOrgId)) ||
          name == normalizeName(other.firstName, other.lastName)) {
        return other;
      }
    }
    return null;
  }

  static List<PilotFieldChange> _changes(
    PilotDraft draft,
    ParticipantProfile profile,
    PilotMatchRule rule,
  ) {
    final changes = <PilotFieldChange>[];
    void check(
      String field,
      String? incoming,
      String? current, {
      bool Function(String a, String b)? same,
    }) {
      if (incoming == null) {
        return;
      }
      final equal =
          current != null && (same ?? (a, b) => a == b)(incoming, current);
      if (!equal) {
        changes.add(
          PilotFieldChange(field: field, from: current, to: incoming),
        );
      }
    }

    bool sameEmail(String a, String b) =>
        normalizeEmail(a) == normalizeEmail(b);
    bool sameNumber(String a, String b) =>
        normalizeNumber(a) == normalizeNumber(b);

    if (rule != PilotMatchRule.email) {
      check('email', draft.email, profile.email, same: sameEmail);
    }
    if (rule != PilotMatchRule.faiNumber) {
      check('faiNumber', draft.faiNumber, profile.faiNumber, same: sameNumber);
    }
    if (rule != PilotMatchRule.nationalOrgId) {
      check(
        'nationalOrgId',
        draft.nationalOrgId,
        profile.nationalOrgId,
        same: sameNumber,
      );
    }
    check('club', draft.club, profile.club);
    check('city', draft.city, profile.city);
    check('state', draft.state, profile.state);
    check('country', draft.country, profile.country);
    return changes;
  }

  /// Lower-cased, trimmed email; null when blank.
  static String? normalizeEmail(String? email) {
    final text = email?.trim().toLowerCase();
    return text == null || text.isEmpty ? null : text;
  }

  /// FAI and registration numbers compared without case or spaces.
  static String? normalizeNumber(String? number) {
    final text = number?.replaceAll(RegExp(r'\s+'), '').toUpperCase();
    return text == null || text.isEmpty ? null : text;
  }

  /// First and last name without case, accents or extra spaces.
  static String normalizeName(String first, String last) =>
      _fold('$first $last').replaceAll(RegExp(r'\s+'), ' ').trim();

  static const _accents = <String, String>{
    'àáâãäåāă': 'a',
    'çćč': 'c',
    'ďđ': 'd',
    'èéêëēěę': 'e',
    'ğ': 'g',
    'ìíîïī': 'i',
    'ł': 'l',
    'ñńň': 'n',
    'òóôõöøō': 'o',
    'řŕ': 'r',
    'śšş': 's',
    'ťţ': 't',
    'ùúûüūů': 'u',
    'ýÿ': 'y',
    'źżž': 'z',
  };

  static String _fold(String text) {
    final buffer = StringBuffer();
    for (final rune in text.toLowerCase().runes) {
      final char = String.fromCharCode(rune);
      var replaced = char;
      for (final entry in _accents.entries) {
        if (entry.key.contains(char)) {
          replaced = entry.value;
          break;
        }
      }
      buffer.write(replaced);
    }
    return buffer.toString().replaceAll('ß', 'ss').replaceAll('æ', 'ae');
  }
}
