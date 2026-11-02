import 'package:equatable/equatable.dart';
import 'package:soar_score_core/soar_score_core.dart';

/// One model a pilot flies in a contest: the contest's snapshot of it, as the
/// wizard draft holds it or as the stored [ContestModelLink] has it.
class ModelEntry extends Equatable {
  const ModelEntry({
    required this.id,
    this.catalogId,
    required this.name,
    this.manufacturer,
    this.modelId,
    this.contestIdentifier,
    this.revision = 0,
  });

  factory ModelEntry.fromLink(ContestModelLink link) => ModelEntry(
    id: link.id,
    catalogId: link.modelCatalogId,
    name: link.modelName,
    manufacturer: link.manufacturer,
    modelId: link.modelId,
    contestIdentifier: link.contestSpecificIdentifier,
    revision: link.revision,
  );

  /// A copy of the profile's [model], to enter in a contest as [id].
  factory ModelEntry.fromCatalog(ModelCatalog model, {required Id id}) =>
      ModelEntry(
        id: id,
        catalogId: model.id,
        name: model.name,
        manufacturer: model.manufacturer,
        modelId: model.modelId,
      );

  /// The link's id (a draft entry gets one when it is made, so a retried
  /// creation repeats the same request).
  final Id id;

  /// The profile model this was copied from, if any.
  final Id? catalogId;

  final String name;
  final String? manufacturer;

  /// The identifier the pilot put on the model.
  final String? modelId;

  /// The identifier the director applied for this contest, such as a serial
  /// number.
  final String? contestIdentifier;

  final int revision;

  /// `Supra · Vladimir's Model`, or just the name.
  String get label {
    final maker = manufacturer?.trim() ?? '';
    return maker.isEmpty ? name : '$name · $maker';
  }

  /// This entry with all four details replaced; blank optional ones clear.
  ModelEntry edited({
    required String name,
    String? manufacturer,
    String? modelId,
    String? contestIdentifier,
  }) => ModelEntry(
    id: id,
    catalogId: catalogId,
    name: name.trim(),
    manufacturer: _blankToNull(manufacturer),
    modelId: _blankToNull(modelId),
    contestIdentifier: _blankToNull(contestIdentifier),
    revision: revision,
  );

  static String? _blankToNull(String? text) {
    final trimmed = text?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  /// The same model as another entry, ignoring ids: what the director would
  /// otherwise enter twice.
  bool sameModelAs(ModelEntry other) =>
      name.trim().toLowerCase() == other.name.trim().toLowerCase() &&
      (manufacturer ?? '').trim().toLowerCase() ==
          (other.manufacturer ?? '').trim().toLowerCase() &&
      (modelId ?? '').trim().toLowerCase() ==
          (other.modelId ?? '').trim().toLowerCase();

  @override
  List<Object?> get props => [
    id,
    catalogId,
    name,
    manufacturer,
    modelId,
    contestIdentifier,
    revision,
  ];
}
