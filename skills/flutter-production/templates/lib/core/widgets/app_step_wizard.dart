import 'package:flutter/material.dart';

/// The app's one multi-step ("wizard") layout — the design first built for
/// "Create Blog": AppBar whose back arrow steps backwards, a segmented
/// progress header with "Step X of N: Label", the step content, and a bottom
/// action bar chosen with [showBackNextFooter]:
///
/// * `false` (default, the blog design): one full-width primary button —
///   Next, or [submitLabel] on the last step.
/// * `true`: a Back / Next footer — Back (Cancel on the first step) beside the
///   primary button, for longer flows where stepping back is common.
///
/// Every multi-step flow must use this widget (see CLAUDE.md, "Multi-step
/// flows"). Change the design here, never per screen.
class AppStepWizard extends StatelessWidget {
  const AppStepWizard({
    super.key,
    required this.title,
    required this.stepLabels,
    required this.currentStep,
    required this.body,
    required this.onStepBack,
    required this.onNext,
    required this.submitLabel,
    this.nextLabel = 'Next',
    this.showBackNextFooter = false,
    this.backLabel = 'Back',
    this.cancelLabel = 'Cancel',
    this.onStepTapped,
    this.isBusy = false,
    this.canPop = true,
    this.confirmDiscard,
    this.actions,
  });

  final String title;
  final List<String> stepLabels;
  final int currentStep;

  /// Content of the current step (it handles its own scrolling).
  final Widget body;

  /// Called by the AppBar back arrow on steps after the first; on the first
  /// step the arrow leaves the wizard (through [confirmDiscard] if needed).
  final VoidCallback onStepBack;

  /// Primary button: validate and advance, or submit on the last step.
  /// Null disables the button (e.g. while the wizard is still loading).
  final VoidCallback? onNext;
  final String submitLabel;
  final String nextLabel;

  /// Show the Back / Next footer instead of the single full-width button.
  final bool showBackNextFooter;
  final String backLabel;

  /// Footer's back button label on the first step, where it leaves the wizard.
  final String cancelLabel;

  /// When set, every progress segment becomes tappable and jumps straight to
  /// that step (validation stays the caller's job). Null keeps the header
  /// display-only, as in the original blog design.
  final ValueChanged<int>? onStepTapped;

  /// Shows a spinner in the primary button and disables it (and step taps).
  final bool isBusy;

  /// False while there is unsaved input; leaving then asks [confirmDiscard].
  final bool canPop;

  /// Asks the user whether to discard unsaved input; true leaves the wizard.
  final Future<bool> Function()? confirmDiscard;

  /// Optional AppBar actions (e.g. a "Save" shortcut while editing).
  final List<Widget>? actions;

  bool get _isLastStep => currentStep == stepLabels.length - 1;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        final leave = confirmDiscard == null || await confirmDiscard!();
        if (leave && context.mounted) navigator.pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: currentStep == 0 ? 'Close' : 'Previous step',
            onPressed: () => currentStep == 0
                ? Navigator.of(context).maybePop()
                : onStepBack(),
          ),
          actions: actions,
        ),
        body: Column(
          children: [
            AppStepWizardHeader(
              stepLabels: stepLabels,
              currentStep: currentStep,
              onStepTapped: isBusy ? null : onStepTapped,
            ),
            Expanded(child: body),
          ],
        ),
        bottomNavigationBar: showBackNextFooter
            ? _buildBackNextFooter(context)
            : _buildPrimaryButtonBar(),
      ),
    );
  }

  Widget _primaryButtonChild() => isBusy
      ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        )
      : Text(_isLastStep ? submitLabel : nextLabel);

  /// Default (blog) bar: one full-width primary button.
  Widget _buildPrimaryButtonBar() {
    return SafeArea(
      minimum: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: isBusy ? null : onNext,
          child: _primaryButtonChild(),
        ),
      ),
    );
  }

  /// Back / Next footer: Back (Cancel on step 1) beside the primary button.
  Widget _buildBackNextFooter(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isFirst = currentStep == 0;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isBusy
                    ? null
                    : () => isFirst
                          ? Navigator.of(context).maybePop()
                          : onStepBack(),
                icon: Icon(isFirst ? Icons.close : Icons.arrow_back),
                label: Text(
                  isFirst ? cancelLabel : backLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: isBusy ? null : onNext,
                child: _primaryButtonChild(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Step progress bar shown at the top of [AppStepWizard].
class AppStepWizardHeader extends StatelessWidget {
  const AppStepWizardHeader({
    super.key,
    required this.stepLabels,
    required this.currentStep,
    this.onStepTapped,
  });

  final List<String> stepLabels;
  final int currentStep;

  /// Makes each segment a tap target for its step; null = display only.
  final ValueChanged<int>? onStepTapped;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (var i = 0; i < stepLabels.length; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                Expanded(child: _segment(context, i)),
              ],
            ],
          ),
          SizedBox(height: onStepTapped == null ? 10 : 0),
          Text(
            'Step ${currentStep + 1} of ${stepLabels.length}: ${stepLabels[currentStep]}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _segment(BuildContext context, int index) {
    final colorScheme = Theme.of(context).colorScheme;
    final bar = ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: index <= currentStep ? 1 : 0,
        minHeight: 6,
        backgroundColor: colorScheme.surfaceContainerHighest,
        valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
      ),
    );
    final tap = onStepTapped;
    if (tap == null) return bar;

    // Same 6dp bar, inside a 48dp-tall tap target.
    return Semantics(
      button: true,
      selected: index == currentStep,
      label: 'Go to step ${index + 1}: ${stepLabels[index]}',
      excludeSemantics: true,
      child: Tooltip(
        message: '${index + 1}. ${stepLabels[index]}',
        child: InkWell(
          key: ValueKey('wizard-step-$index'),
          borderRadius: BorderRadius.circular(8),
          onTap: index == currentStep ? null : () => tap(index),
          child: SizedBox(height: 48, child: Center(child: bar)),
        ),
      ),
    );
  }
}
