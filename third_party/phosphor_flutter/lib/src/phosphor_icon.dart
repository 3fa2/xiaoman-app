library phosphor_flutter;

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// PhosphorIcon is a simplified version after the Flutter 3.47+ patch.
/// Duotone rendering is no longer supported (PhosphorDuotoneIconData
/// is no longer an IconData subclass).
class PhosphorIcon extends Icon {
  const PhosphorIcon(
    IconData icon, {
    Key? key,
    double? size,
    double? fill,
    double? weight,
    double? grade,
    double? opticalSize,
    Color? color,
    List<Shadow>? shadows,
    String? semanticLabel,
    TextDirection? textDirection,
    double duotoneSecondaryOpacity = 0.20,
    Color? duotoneSecondaryColor,
  }) : super(
          icon,
          color: color,
          fill: fill,
          grade: grade,
          key: key,
          opticalSize: opticalSize,
          semanticLabel: semanticLabel,
          shadows: shadows,
          size: size,
          textDirection: textDirection,
          weight: weight,
        );
}
