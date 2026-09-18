import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SoarLogo extends StatelessWidget {
  final double size;
  final Color? color;

  const SoarLogo({
    super.key,
    this.size = 32.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    // Falls back to the theme's primary color if no specific color is passed
    final logoColor = color ?? Theme.of(context).colorScheme.primary;

    return SvgPicture.asset(
      'assets/images/explorer_q.svg',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(logoColor, BlendMode.srcIn),
    );
  }
}
