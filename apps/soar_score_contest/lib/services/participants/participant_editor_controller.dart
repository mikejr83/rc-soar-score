import 'package:flutter/foundation.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../widgets/api_error_text.dart';
import 'participant_countries.dart';
import 'participant_field.dart';
import 'participant_field_rules.dart';
import 'participant_form_values.dart';
import 'participant_kept_values.dart';
import 'participant_review.dart';

/// What the editor is doing now. Only [idle] accepts a save.
enum EditorPhase {
  loading,
  loadFailed,
  idle,
  saving,
  saveFailed,

  /// A profile with the same email exists; nothing is saved until the
  /// director chooses.
  duplicate,

  /// The server refused the save because the profile changed elsewhere.
  stale,

  /// Comparing the director's version with the stored one field by field.
  review,
}

/// The state of the "does this email already exist" lookup in add mode.
enum EmailCheck {
  none,
  checking,
  clear,
  found,

  /// Matching online was not possible; only this device was checked.
  localOnly,

  /// The lookup itself failed. Saving still looks again.
  failed,
}

/// How a call to [ParticipantEditorController.save] ended.
enum SaveOutcome {
  /// Fields need attention; nothing was sent.
  invalid,

  /// A decision or conflict is open, or a save is running.
  blocked,

  /// A duplicate email was found; the director has to choose.
  needsDecision,

  /// The server did not accept the save; see [ParticipantEditorController.error].
  failed,

  /// The server says the profile changed elsewhere.
  conflict,

  /// Nothing differed from the stored profile, so nothing was sent.
  unchanged,

  /// Saved; [ParticipantEditorController.saved] holds the profile.
  saved,

  /// Saved, and the form was reset for the next participant.
  savedAnother,
}

/// The state and rules behind the participant editor page.
///
/// The page owns the text controllers and focus; this owns what is typed,
/// what is stored, which phase the editor is in and every call to the API.
class ParticipantEditorController extends ChangeNotifier {
  ParticipantEditorController({
    required this.client,
    this.participantId,
    this.remoteMatchingUnavailable = false,
    this.managedFields = const {},
  }) : phase = participantId == null ? EditorPhase.idle : EditorPhase.loading;

  final ApiClient client;

  /// The profile to edit, or null to create one.
  final Id? participantId;

  /// True when matching against the online records is not possible, so the
  /// email lookup only covers this device.
  final bool remoteMatchingUnavailable;

  /// Fields owned by the participant's own account, shown read-only.
  final Set<ParticipantField> managedFields;

  bool get creating => participantId == null;

  EditorPhase phase;

  /// The stored profile being edited (null when creating).
  ParticipantProfile? loaded;

  /// The newest stored version, fetched after a stale-revision refusal.
  ParticipantProfile? latest;

  ParticipantFormValues values = const ParticipantFormValues();

  /// What [values] is compared with to tell whether anything changed.
  ParticipantFormValues baseline = const ParticipantFormValues();

  final Set<ParticipantField> touched = {};
  bool submitted = false;

  EmailCheck emailCheck = EmailCheck.none;

  /// The profile whose email matches the one typed (add mode).
  ParticipantProfile? match;

  /// Why the load or the last save failed, in the server's words.
  String? error;

  /// The fields that changed elsewhere, named in the stale banner.
  List<ParticipantField> staleFields = const [];

  ParticipantReview? review;

  /// The profile the last successful save returned.
  ParticipantProfile? saved;

  /// Whether "Save and add another" keeps club and location.
  bool keepClubAndLocation = true;

  /// Who the kept club and location came from, while they are showing.
  String? keptFrom;

  bool _pendingAnother = false;

  bool get dirty => values != baseline;

  /// The message to show under [field], or null before it was visited.
  String? visibleError(ParticipantField field) {
    if (managedFields.contains(field) ||
        !(touched.contains(field) || submitted)) {
      return null;
    }
    return participantFieldError(field, values[field]);
  }

  /// The fields that still need attention after a save attempt.
  Map<ParticipantField, String> get attention =>
      submitted ? attentionNow : const {};

  /// The profile's email is missing (a profile made elsewhere).
  bool get missingEmail => !creating && (loaded?.email ?? '').trim().isEmpty;

  bool get blocked => const {
    EditorPhase.duplicate,
    EditorPhase.stale,
    EditorPhase.review,
  }.contains(phase);

  Future<void> load() async {
    if (creating) {
      return;
    }
    phase = EditorPhase.loading;
    error = null;
    notifyListeners();
    try {
      final profile = await client.participant(participantId!);
      loaded = profile;
      _adopt(ParticipantFormValues.fromProfile(profile));
      phase = EditorPhase.idle;
    } on Object catch (e) {
      error = _text(e);
      phase = EditorPhase.loadFailed;
    }
    notifyListeners();
  }

  void _adopt(ParticipantFormValues stored) {
    values = stored;
    baseline = stored;
    touched.clear();
    submitted = false;
  }

  void setValue(ParticipantField field, String value) {
    if (values[field] == value) {
      return;
    }
    values = values.withField(field, value);
    if (field == ParticipantField.email) {
      emailCheck = EmailCheck.none;
      match = null;
      if (phase == EditorPhase.duplicate) {
        phase = EditorPhase.idle;
      }
    }
    notifyListeners();
  }

  /// Marks [field] visited. In add mode, leaving a valid email looks for an
  /// existing profile so a match is mentioned before saving.
  void leave(ParticipantField field) {
    touched.add(field);
    notifyListeners();
    if (field == ParticipantField.email &&
        creating &&
        participantFieldError(field, values[field]) == null) {
      checkEmail();
    }
  }

  Future<void> checkEmail() async {
    final asked = values[ParticipantField.email];
    emailCheck = EmailCheck.checking;
    notifyListeners();
    ParticipantProfile? found;
    try {
      found = await _findByEmail(asked);
    } on Object {
      if (values[ParticipantField.email] == asked) {
        emailCheck = EmailCheck.failed;
        notifyListeners();
      }
      return;
    }
    if (values[ParticipantField.email] != asked) {
      return;
    }
    match = found;
    emailCheck = remoteMatchingUnavailable
        ? EmailCheck.localOnly
        : found == null
        ? EmailCheck.clear
        : EmailCheck.found;
    notifyListeners();
  }

  Future<ParticipantProfile?> _findByEmail(String email) async {
    final wanted = email.trim().toLowerCase();
    for (final profile in await client.participants()) {
      if (profile.email?.toLowerCase() == wanted) {
        return profile;
      }
    }
    return null;
  }

  /// Validates and saves. The page reacts to the [SaveOutcome].
  Future<SaveOutcome> save({bool another = false}) async {
    if (phase == EditorPhase.saving || blocked) {
      return SaveOutcome.blocked;
    }
    _pendingAnother = another;
    if (attentionNow.isNotEmpty) {
      submitted = true;
      notifyListeners();
      return SaveOutcome.invalid;
    }
    if (creating) {
      phase = EditorPhase.saving;
      notifyListeners();
      try {
        match = await _findByEmail(values[ParticipantField.email]);
      } on Object catch (e) {
        return _failed(e);
      }
      if (match != null) {
        _pendingAnother = another;
        phase = EditorPhase.duplicate;
        notifyListeners();
        return SaveOutcome.needsDecision;
      }
    }
    return _commit(another: another);
  }

  /// The fields that would block a save right now.
  Map<ParticipantField, String> get attentionNow =>
      participantErrors(values, skip: managedFields);

  /// The first field that needs attention, in form order.
  ParticipantField? get firstInvalid {
    final fields = attentionNow.keys;
    return fields.isEmpty ? null : fields.first;
  }

  SaveOutcome _failed(Object e) {
    error = _text(e);
    phase = EditorPhase.saveFailed;
    notifyListeners();
    return SaveOutcome.failed;
  }

  Future<SaveOutcome> _commit({required bool another}) async {
    if (!creating && !dirty) {
      phase = EditorPhase.idle;
      notifyListeners();
      return SaveOutcome.unchanged;
    }
    phase = EditorPhase.saving;
    error = null;
    notifyListeners();
    final v = values;
    final typedCountry = v.optional(ParticipantField.country);
    final country = typedCountry == null
        ? null
        : normalizeCountry(typedCountry);
    try {
      final ParticipantProfile result;
      if (creating) {
        result = await client.createParticipant(
          CreateParticipantRequest(
            id: Id.create(),
            firstName: v[ParticipantField.firstName].trim(),
            lastName: v[ParticipantField.lastName].trim(),
            email: v[ParticipantField.email].trim(),
            club: v.optional(ParticipantField.club),
            faiNumber: v.optional(ParticipantField.faiNumber),
            nationalOrgId: v.optional(ParticipantField.nationalOrgId),
            city: v.optional(ParticipantField.city),
            state: v.optional(ParticipantField.state),
            country: country,
          ),
        );
      } else {
        result = await client.updateParticipant(
          loaded!.id,
          UpdateParticipantRequest(
            baseRevision: loaded!.revision,
            firstName: v[ParticipantField.firstName].trim(),
            lastName: v[ParticipantField.lastName].trim(),
            email: v[ParticipantField.email].trim(),
            club: v.optional(ParticipantField.club),
            faiNumber: v.optional(ParticipantField.faiNumber),
            nationalOrgId: v.optional(ParticipantField.nationalOrgId),
            city: v.optional(ParticipantField.city),
            state: v.optional(ParticipantField.state),
            country: country,
          ),
        );
      }
      saved = result;
    } on ApiHttpError catch (e) {
      if (!creating && e.error?.code == 'stale_revision') {
        return _conflict(e);
      }
      return _failed(e);
    } on Object catch (e) {
      return _failed(e);
    }
    return _afterSave(another: another);
  }

  SaveOutcome _afterSave({required bool another}) {
    final result = saved!;
    if (creating && another) {
      final kept = keepClubAndLocation ? keptValuesOf(values) : null;
      final fresh = kept ?? const ParticipantFormValues();
      keptFrom = kept != null && hasKeptValues(kept) ? values.fullName : null;
      _adopt(fresh);
      emailCheck = EmailCheck.none;
      match = null;
      phase = EditorPhase.idle;
      notifyListeners();
      return SaveOutcome.savedAnother;
    }
    if (!creating) {
      loaded = result;
    }
    baseline = values;
    phase = EditorPhase.idle;
    notifyListeners();
    return SaveOutcome.saved;
  }

  Future<SaveOutcome> _conflict(ApiHttpError refusal) async {
    try {
      latest = await client.participant(loaded!.id);
    } on Object {
      latest = null;
    }
    final theirs = latest;
    staleFields = theirs == null
        ? const []
        : ParticipantFormValues.fromProfile(theirs).differences(baseline);
    error = refusal.error?.message ?? 'The participant changed elsewhere.';
    phase = EditorPhase.stale;
    notifyListeners();
    return SaveOutcome.conflict;
  }

  /// Replaces the director's edits with the newest stored version.
  void reloadLatest() {
    final theirs = latest;
    if (theirs == null) {
      load();
      return;
    }
    loaded = theirs;
    _adopt(ParticipantFormValues.fromProfile(theirs));
    latest = null;
    phase = EditorPhase.idle;
    notifyListeners();
  }

  void startReview() {
    final theirs = latest;
    if (theirs == null) {
      return;
    }
    review = ParticipantReview.build(
      opened: baseline,
      mine: values,
      theirs: ParticipantFormValues.fromProfile(theirs),
    );
    phase = EditorPhase.review;
    notifyListeners();
  }

  void chooseInReview(ParticipantField field, ReviewChoice choice) {
    review = review?.choose(field, choice);
    notifyListeners();
  }

  void backFromReview() {
    phase = EditorPhase.stale;
    notifyListeners();
  }

  /// Saves the version made of the director's picks, against the newest
  /// revision.
  Future<SaveOutcome> applyReview() async {
    final theirs = latest;
    final picks = review;
    if (theirs == null || picks == null) {
      return SaveOutcome.blocked;
    }
    final resolved = picks.resolve(values);
    loaded = theirs;
    latest = null;
    review = null;
    baseline = ParticipantFormValues.fromProfile(theirs);
    values = resolved;
    phase = EditorPhase.idle;
    notifyListeners();
    return _commit(another: false);
  }

  /// The existing profile the director chose in the duplicate decision.
  ParticipantProfile? useExisting() => match;

  void backToEdit() {
    phase = EditorPhase.idle;
    notifyListeners();
  }

  /// Retries after a failed save, keeping what was typed.
  Future<SaveOutcome> retrySave() {
    phase = EditorPhase.idle;
    return save(another: _pendingAnother);
  }

  void toggleKeep({required bool keep}) {
    keepClubAndLocation = keep;
    notifyListeners();
  }

  /// Empties the club and location that were kept from the last add.
  void clearKept() {
    for (final field in keptParticipantFields) {
      values = values.withField(field, '');
    }
    baseline = const ParticipantFormValues();
    keptFrom = null;
    notifyListeners();
  }

  static String _text(Object e) => apiErrorText(e);
}
