import 'package:flutter/material.dart';

import '../utils/sheet_insets.dart';

/// Opens the app's standard bottom sheet: safe-area aware, keyboard aware,
/// rounded top corners, and a floating circular close button centered above
/// the sheet (no drag-handle bar). Use it for quick 1–2 field entries and
/// pickers; large forms are full screens.
Future<T?> showAppModalSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isDismissible = true,
  bool enableDrag = true,
  bool showCloseButton = true,
  EdgeInsetsGeometry contentPadding = const EdgeInsets.fromLTRB(20, 20, 20, 0),
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    elevation: 0,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    builder: (ctx) => AppModalSheet(
      showCloseButton: showCloseButton,
      contentPadding: contentPadding,
      child: builder(ctx),
    ),
  );
}

class AppModalSheet extends StatelessWidget {
  const AppModalSheet({
    super.key,
    required this.child,
    this.showCloseButton = true,
    this.contentPadding = const EdgeInsets.fromLTRB(20, 20, 20, 0),
  });

  final Widget child;
  final bool showCloseButton;
  final EdgeInsetsGeometry contentPadding;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.9;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showCloseButton) ...[
            Center(
              child: Material(
                color: colorScheme.surface,
                shape: CircleBorder(
                  side: BorderSide(color: colorScheme.outlineVariant),
                ),
                elevation: 3,
                clipBehavior: Clip.antiAlias,
                child: IconButton(
                  tooltip: 'Close',
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          Flexible(
            child: Material(
              color: colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              clipBehavior: Clip.antiAlias,
              child: SingleChildScrollView(
                padding: contentPadding.add(
                  EdgeInsets.only(bottom: safeBottomInset(context)),
                ),
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
