import 'package:flutter/material.dart';

import '../network/api_exception.dart';

/// Error state with a Retry action. Scrollable so it works inside
/// `RefreshIndicator`. [onRetry] should `ref.invalidate(<source provider>)`.
class AppErrorView extends StatelessWidget {
  const AppErrorView({
    super.key,
    required this.error,
    required this.onRetry,
    this.title = 'Something went wrong',
    this.icon = Icons.cloud_off_rounded,
  });

  final Object error;
  final VoidCallback onRetry;
  final String title;
  final IconData icon;

  static String messageOf(Object error) => error is ApiException
      ? error.message
      : 'Something went wrong. Please try again.';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(32),
      children: [
        Icon(icon, size: 48, color: theme.colorScheme.error),
        const SizedBox(height: 12),
        Text(
          title,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        Text(
          messageOf(error),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(minimumSize: const Size(160, 48)),
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ),
      ],
    );
  }
}

/// Empty state with guidance and an optional next action.
class AppEmptyView extends StatelessWidget {
  const AppEmptyView({
    super.key,
    required this.title,
    this.message,
    this.icon,
    this.iconWidget,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? message;

  /// Material icon, or pass [iconWidget] (e.g. a `HugeIcon`).
  final IconData? icon;
  final Widget? iconWidget;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(32),
      children: [
        iconWidget ??
            Icon(
              icon ?? Icons.inbox_outlined,
              size: 56,
              color: theme.colorScheme.onSurfaceVariant,
            ),
        const SizedBox(height: 12),
        Text(
          title,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium,
        ),
        if (message != null) ...[
          const SizedBox(height: 4),
          Text(
            message!,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(height: 20),
          Center(
            child: FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(180, 48)),
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
          ),
        ],
      ],
    );
  }
}
