import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Bottom padding for bottom bars and sheets.
///
/// - Samsung / Android 3-button bar (48–56 dp): nothing is hidden behind it.
/// - Gesture navigation (0–16 dp): a clean [min] margin, no oversized gap.
/// - Keyboard open: the content floats above it.
double safeBottomInset(BuildContext context, {double min = 16}) {
  return math.max(min, MediaQuery.viewPaddingOf(context).bottom) +
      MediaQuery.viewInsetsOf(context).bottom;
}
