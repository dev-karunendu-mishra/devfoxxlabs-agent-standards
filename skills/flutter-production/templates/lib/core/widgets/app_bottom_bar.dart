import 'package:flutter/material.dart';

import '../utils/sheet_insets.dart';

/// Docked bottom action bar (Save, Continue, Pay, Go Online…).
///
/// Use it as `Scaffold.bottomNavigationBar` or at the end of a `Column`. It
/// never hides behind the 3-button navigation bar, has no oversized gap in
/// gesture mode, and lifts above the keyboard.
class AppBottomBar extends StatelessWidget {
  const AppBottomBar({
    super.key,
    required this.child,
    this.backgroundColor,
    this.horizontalPadding = 16,
    this.topPadding = 12,
    this.minBottomPadding = 16,
    this.showTopBorder = true,
  });

  final Widget child;
  final Color? backgroundColor;
  final double horizontalPadding;
  final double topPadding;
  final double minBottomPadding;
  final bool showTopBorder;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor ?? colorScheme.surface,
        border: showTopBorder
            ? Border(top: BorderSide(color: colorScheme.outlineVariant))
            : null,
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          topPadding,
          horizontalPadding,
          safeBottomInset(context, min: minBottomPadding),
        ),
        child: child,
      ),
    );
  }
}
