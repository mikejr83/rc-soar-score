import 'package:flutter/widgets.dart';

import 'text_size.dart';

/// The most the device scale and the chosen size may magnify text together, so
/// Extra large on top of a large system setting cannot break the layouts.
const double maxCombinedTextScale = 2.5;

/// Multiplies the device's [TextScaler] by [factor], never magnifying beyond
/// [maxCombinedTextScale] (at 14 logical pixels, as `textScaleFactor` does).
class PreferredTextScaler extends TextScaler {
  const PreferredTextScaler(this.platform, this.factor);

  /// A scaler for [size] on top of [platform].
  factory PreferredTextScaler.of(TextScaler platform, TextSize size) =>
      PreferredTextScaler(platform, size.factor);

  final TextScaler platform;
  final double factor;

  @override
  double scale(double fontSize) {
    if (fontSize == 0) return 0;
    final scaled = platform.scale(fontSize) * factor;
    final max = fontSize * maxCombinedTextScale;
    return scaled > max ? max : scaled;
  }

  @override
  // ignore: deprecated_member_use
  double get textScaleFactor => scale(14) / 14;

  @override
  bool operator ==(Object other) =>
      other is PreferredTextScaler &&
      other.platform == platform &&
      other.factor == factor;

  @override
  int get hashCode => Object.hash(platform, factor);
}
