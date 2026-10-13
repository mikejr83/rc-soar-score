import 'package:soar_score_core/soar_score_core.dart';

/// Body of `POST /api/v1/landing-tables`.
///
/// The caller generates [id] (a UUIDv7), so repeating the request returns the
/// table it created instead of creating another. [entries] are in selection
/// order; their position becomes their ordinal.
class CreateLandingTableRequest {
  const CreateLandingTableRequest({
    required this.id,
    required this.name,
    required this.inputUnit,
    required this.entries,
  });

  factory CreateLandingTableRequest.fromJson(Map<String, dynamic> json) =>
      CreateLandingTableRequest(
        id: Id.parse(json['id'] as String),
        name: json['name'] as String,
        inputUnit: LandingInputUnit.values.byName(json['input_unit'] as String),
        entries: [
          for (final item in json['entries'] as List<dynamic>)
            LandingEntryInput.fromJson(item as Map<String, dynamic>),
        ],
      );

  final Id id;
  final String name;
  final LandingInputUnit inputUnit;
  final List<LandingEntryInput> entries;

  Map<String, dynamic> toJson() => {
    'id': id.value,
    'name': name,
    'input_unit': inputUnit.name,
    'entries': [for (final entry in entries) entry.toJson()],
  };
}
