import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../services/text_size/text_size.dart';
import '../../services/text_size/text_size_controller.dart';

/// The `Text size` card on the Settings page: a Default, Large or Extra large
/// choice that applies at once and is remembered on this device for the
/// account.
class TextSizeSetting extends StatelessWidget {
  const TextSizeSetting({super.key, required this.controller});

  /// `null` when the build has no text size controller; the choice is then
  /// shown but cannot be changed.
  final TextSizeController? controller;

  Future<void> _choose(
    BuildContext context,
    TextSizeController controller,
    TextSize size,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final message = AppLocalizations.of(context).textSizeSaveFailed;
    if (await controller.setSize(size)) return;
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final controller = this.controller;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.textSizeHeading, style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              l10n.textSizeDescription,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            SegmentedButton<TextSize>(
              key: const ValueKey('text-size-control'),
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                  value: TextSize.standard,
                  label: Text(l10n.textSizeDefault),
                ),
                ButtonSegment(
                  value: TextSize.large,
                  label: Text(l10n.textSizeLarge),
                ),
                ButtonSegment(
                  value: TextSize.extraLarge,
                  label: Text(l10n.textSizeExtraLarge),
                ),
              ],
              selected: {controller?.size ?? TextSize.standard},
              onSelectionChanged: controller == null
                  ? null
                  : (selection) =>
                        _choose(context, controller, selection.single),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.textSizePreview,
              key: const ValueKey('text-size-preview'),
              style: theme.textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}
