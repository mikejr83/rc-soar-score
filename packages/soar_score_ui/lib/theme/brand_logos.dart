import 'package:flutter/material.dart';

/// Logo files from the brand kit, bundled with this package.
///
/// Use the dark lockup on dark grounds and the light lockup on light grounds;
/// the mark's own colours never change. Below 64px use [markSmall], below
/// 32px use [markTiny]. Always use the files: the wordmark is drawn lettering.
///
/// The SVG paths are for tooling (favicons, web manifests, print); Flutter
/// renders the PNGs through [BrandLogo].
abstract final class BrandLogos {
  static const String package = 'soar_score_ui';
  static const String _dir = 'assets/logos/';

  static const String lockupLight = '${_dir}rc-soar-score-lockup-light.svg';
  static const String lockupLightTransparent =
      '${_dir}rc-soar-score-lockup-light-transparent.svg';
  static const String lockupDark = '${_dir}rc-soar-score-lockup-dark.svg';
  static const String lockupDarkTransparent =
      '${_dir}rc-soar-score-lockup-dark-transparent.svg';
  static const String mark = '${_dir}rc-soar-score-mark.svg';
  static const String markSmall = '${_dir}rc-soar-score-mark-small.svg';
  static const String markTiny = '${_dir}rc-soar-score-mark-tiny.svg';
  static const String appIcon = '${_dir}rc-soar-score-app-icon.svg';

  static const String lockupLightPng =
      '${_dir}png/rc-soar-score-lockup-light-transparent.png';
  static const String lockupDarkPng =
      '${_dir}png/rc-soar-score-lockup-dark-transparent.png';
  static const String markPng = '${_dir}png/rc-soar-score-mark.png';
  static const String markSmallPng = '${_dir}png/rc-soar-score-mark-small.png';
  static const String markTinyPng = '${_dir}png/rc-soar-score-mark-tiny.png';
  static const String appIconPng = '${_dir}png/rc-soar-score-app-icon.png';
}

/// Which logo [BrandLogo] draws.
///
/// [appIcon] is the square app icon (the same artwork as the native and web
/// app icons), drawn with rounded corners.
enum BrandLogoVariant { lockup, mark, appIcon }

/// The RC Soar Score logo at a given height, picking the file for the size
/// and the ground it sits on.
// ponytail: PNG via Image.asset; swap to flutter_svg if it looks soft on
// high-DPI screens.
class BrandLogo extends StatelessWidget {
  const BrandLogo({
    super.key,
    this.variant = BrandLogoVariant.mark,
    this.height = 40,
    this.onDark,
    this.semanticLabel = 'RC Soar Score logo',
  });

  final BrandLogoVariant variant;
  final double height;

  /// True when drawn on a dark ground; only affects the lockup's wordmark.
  /// Null follows the ambient theme's brightness.
  final bool? onDark;
  final String semanticLabel;

  /// The asset drawn on a ground of the given darkness.
  String assetFor({required bool dark}) => switch (variant) {
    BrandLogoVariant.lockup =>
      (onDark ?? dark) ? BrandLogos.lockupDarkPng : BrandLogos.lockupLightPng,
    BrandLogoVariant.appIcon => BrandLogos.appIconPng,
    BrandLogoVariant.mark when height < 32 => BrandLogos.markTinyPng,
    BrandLogoVariant.mark when height < 64 => BrandLogos.markSmallPng,
    BrandLogoVariant.mark => BrandLogos.markPng,
  };

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      assetFor(dark: Theme.of(context).brightness == Brightness.dark),
      package: BrandLogos.package,
      height: height,
      fit: BoxFit.contain,
      semanticLabel: semanticLabel,
    );
    if (variant != BrandLogoVariant.appIcon) {
      return image;
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(height * 0.22),
      child: image,
    );
  }
}
