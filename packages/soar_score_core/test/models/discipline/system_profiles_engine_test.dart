import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

/// Contest options the platform defines; a profile can only suggest their
/// defaults, so they are not discipline config fields.
const _coreOptions = {'group_score_mode', 'rounding_mode', 'decimal_places'};

/// Score fields the engine accepts that the data rows do not hold yet. Each
/// is a recorded difference, to be settled in a follow-up, not a decision.
///
/// F5J: the engine takes the flight penalty entered with each score
/// (`plan/data-model/contest-options.md`, "Not options"), but the example
/// document has no such score field (issue 201).
final _engineOnlyScoreFields = {
  DisciplineType.f5j: {'flight_penalty'},
};

/// The data rows in `SystemDisciplineProfiles` against the scoring engine
/// profiles in `ScoringProfileRegistry`.
void main() {
  final registry = ScoringProfileRegistry([
    F5jProfile(),
    F3jProfile(),
    AlesProfile(),
    ThermalProfile(),
  ]);

  for (final shipped in SystemDisciplineProfiles.all) {
    final data = shipped.profile;
    group(data.name, () {
      late ScoringProfile engine;
      setUp(() => engine = registry.resolve(data.type, data.version));

      test('resolves in the registry by type and version', () {
        expect(engine.discipline, data.type);
        expect(engine.rulesVersion, data.version);
      });

      test('the score fields are the fields the engine accepts', () {
        final accepted = engine.fields
            .where((f) => f.acceptedInSubmission)
            .map((f) => f.id)
            .toSet();

        expect(
          accepted.difference(
            shipped.scoreFields.map((f) => f.fieldKey).toSet(),
          ),
          _engineOnlyScoreFields[data.type] ?? isEmpty,
        );
        expect(
          shipped.scoreFields
              .map((f) => f.fieldKey)
              .toSet()
              .difference(accepted),
          isEmpty,
        );
      });

      test('each score field has the type the engine expects', () {
        for (final field in shipped.scoreFields) {
          expect(
            engine.field(field.fieldKey)?.type,
            field.fieldType,
            reason: field.fieldKey,
          );
        }
      });

      test('the profile default options are the engine defaults', () {
        for (final MapEntry(:key, :value)
            in (data.defaultOptions ?? const <String, Object?>{}).entries) {
          expect(engine.defaultOptions[key], value, reason: key);
        }
      });

      test('the config fields are the discipline options of the engine', () {
        expect(
          shipped.configFields
              .map((f) => f.fieldKey)
              .where(engine.defaultOptions.containsKey)
              .toSet(),
          engine.defaultOptions.keys.toSet().difference(_coreOptions),
        );
      });

      test('the config field defaults are the engine defaults', () {
        for (final field in shipped.configFields) {
          if (field.defaultValue == null) continue;
          expect(
            engine.defaultOptions[field.fieldKey],
            field.defaultValue,
            reason: field.fieldKey,
          );
        }
      });
    });
  }
}
