import 'package:json_annotation/json_annotation.dart';

/// When eligible results are copied to the public projection (`public_update_mode` option).
///
/// [json] is the exact text in `plan/data-model/contest-options.md`.
@JsonEnum(valueField: 'json')
enum PublicUpdateMode {
  automatic('Automatic'),
  roundCompletion('RoundCompletion'),
  manual('Manual');

  const PublicUpdateMode(this.json);

  final String json;
}
