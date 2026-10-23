import 'package:soar_score_ui_storage/soar_score_ui_storage.dart';

/// How large the contest app's text is, chosen on the Settings page.
enum TextSize {
  /// The app's own sizes, unchanged.
  standard(1),
  large(1.25),
  extraLarge(1.5);

  const TextSize(this.factor);

  /// The multiplier applied on top of the device's own text scale.
  final double factor;
}

/// The chosen text size, remembered per account. An unknown stored value
/// reads as [TextSize.standard].
final LocalUiKey<TextSize> textSizeKey = LocalUiKey<TextSize>(
  name: 'text_size',
  defaultValue: TextSize.standard,
  encode: (size) => size.name,
  decode: (data) => TextSize.values.byName(data as String),
);
