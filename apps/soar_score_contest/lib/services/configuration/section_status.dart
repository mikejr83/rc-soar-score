import 'configuration_draft.dart';
import 'section_id.dart';
import 'setting_def.dart';

/// What a section of the page needs attention for: errors, unsaved changes
/// and settings the contest's state has fixed. The section list and chip row
/// show it in words and icons.
class SectionStatus {
  const SectionStatus({
    required this.errors,
    required this.unsaved,
    required this.fixed,
    required this.allFixed,
    required this.readOnly,
  });

  factory SectionStatus.of(
    SectionId id,
    ConfigurationDraft draft, {
    required bool readOnly,
  }) {
    final settings = [
      for (final def in draft.catalog.inSection(id))
        if (def.type != SettingType.readOnly || def.key == 'landing_table')
          if (draft.isVisible(def.key)) def,
    ];
    final keys = {for (final def in settings) def.key};
    final fixed = readOnly
        ? 0
        : settings.where((def) => draft.effectOf(def).fixed).length;
    return SectionStatus(
      errors: draft.errors.keys.where(keys.contains).length,
      unsaved: draft.changes.where((c) => keys.contains(c.def.key)).length,
      fixed: fixed,
      allFixed: settings.isNotEmpty && fixed == settings.length,
      readOnly: readOnly,
    );
  }

  final int errors;
  final int unsaved;
  final int fixed;
  final bool allFixed;

  /// The whole page is read-only (completed or locked).
  final bool readOnly;

  bool get isEmpty => errors == 0 && unsaved == 0 && fixed == 0 && !readOnly;

  /// The words for the section list, for example `2 unsaved`.
  List<SectionMark> get marks => [
    if (errors > 0)
      SectionMark(
        kind: SectionMarkKind.error,
        text: '$errors error${errors > 1 ? 's' : ''}',
        count: errors,
      ),
    if (unsaved > 0)
      SectionMark(
        kind: SectionMarkKind.unsaved,
        text: '$unsaved unsaved',
        count: unsaved,
      ),
    if (fixed > 0)
      SectionMark(
        kind: SectionMarkKind.fixed,
        text: allFixed ? 'Fixed' : 'Partly fixed',
        count: 0,
      ),
    if (readOnly)
      const SectionMark(
        kind: SectionMarkKind.fixed,
        text: 'Read-only',
        count: 0,
      ),
  ];
}

enum SectionMarkKind { error, unsaved, fixed }

class SectionMark {
  const SectionMark({
    required this.kind,
    required this.text,
    required this.count,
  });

  final SectionMarkKind kind;
  final String text;

  /// The number to show beside the icon in the chip row; 0 for none.
  final int count;
}
