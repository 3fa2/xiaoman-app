library phosphor_flutter;

import 'package:flutter/widgets.dart';

/// Simple data class for duotone icon secondary icon reference.
/// Not an IconData subclass (Flutter 3.47+ makes IconData final).
class PhosphorDuotoneIconData {
  const PhosphorDuotoneIconData(this.primary, this.secondary);
  final IconData primary;
  final IconData secondary;
}
