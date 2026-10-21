import 'package:flutter/material.dart';

/// How the viewer was reached, which decides its leading button.
enum ViewerLead {
  /// A browser tab: the tab's own close button does the job.
  none,

  /// Opened in place (no second window): back to the Reports page.
  back,
}

/// The viewer's slim app bar: report and contest name, the page setup the
/// print will use, Save as PDF, the one primary Print action, and an overflow
/// menu. Not inside the shell, so it carries the report's own identity.
class ViewerAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ViewerAppBar({
    super.key,
    required this.title,
    required this.contestName,
    required this.setupText,
    required this.expanded,
    required this.compact,
    required this.lead,
    required this.onLead,
    required this.printEnabled,
    required this.pdfEnabled,
    required this.pdfPrimary,
    required this.onPrint,
    required this.onPdf,
    required this.preview,
    required this.onPreview,
    required this.onPageSetup,
    required this.onReset,
  });

  final String title;
  final String contestName;

  /// "Letter · Landscape · 2 pages", or why nothing can be printed.
  final String setupText;
  final bool expanded;
  final bool compact;
  final ViewerLead lead;
  final VoidCallback onLead;
  final bool printEnabled;
  final bool pdfEnabled;

  /// Printing is unavailable, so Save as PDF becomes the primary action.
  final bool pdfPrimary;
  final VoidCallback onPrint;
  final VoidCallback onPdf;
  final bool preview;
  final ValueChanged<bool> onPreview;
  final VoidCallback onPageSetup;
  final VoidCallback onReset;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pdf = pdfPrimary
        ? FilledButton.icon(
            key: const ValueKey('viewer-pdf'),
            onPressed: pdfEnabled ? onPdf : null,
            icon: const Icon(Icons.picture_as_pdf, size: 18),
            label: const Text('Save as PDF'),
          )
        : OutlinedButton.icon(
            key: const ValueKey('viewer-pdf'),
            onPressed: pdfEnabled ? onPdf : null,
            icon: const Icon(Icons.picture_as_pdf, size: 18),
            label: const Text('Save as PDF'),
          );
    return AppBar(
      // The preview scrolls under the bar; keep it from tinting.
      scrolledUnderElevation: 0,
      centerTitle: true,
      toolbarHeight: 64,
      leading: lead == ViewerLead.back
          ? IconButton(
              key: const ValueKey('viewer-back'),
              tooltip: 'Back to Reports',
              onPressed: onLead,
              icon: const Icon(Icons.arrow_back),
            )
          : null,
      automaticallyImplyLeading: false,
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            header: true,
            child: Text(
              title,
              key: const ValueKey('viewer-title'),
              style: theme.textTheme.titleLarge,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            compact ? '$contestName · $setupText' : contestName,
            key: const ValueKey('viewer-subtitle'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      actions: [
        if (expanded)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Row(
              spacing: 6,
              children: [
                Icon(
                  printEnabled ? Icons.crop_landscape : Icons.info_outline,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                Text(
                  setupText,
                  key: const ValueKey('viewer-setup-text'),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        if (expanded) ...[pdf, const SizedBox(width: 8)],
        FilledButton.icon(
          key: const ValueKey('viewer-print'),
          onPressed: printEnabled ? onPrint : null,
          icon: const Icon(Icons.print, size: 18),
          label: const Text('Print'),
        ),
        MenuAnchor(
          menuChildren: [
            if (!expanded)
              MenuItemButton(
                leadingIcon: const Icon(Icons.picture_as_pdf),
                onPressed: pdfEnabled ? onPdf : null,
                child: const Text('Save as PDF'),
              ),
            CheckboxMenuButton(
              value: preview,
              onChanged: (value) => onPreview(value ?? false),
              child: const Text('Print preview'),
            ),
            MenuItemButton(
              leadingIcon: const Icon(Icons.description_outlined),
              onPressed: onPageSetup,
              child: const Text('Page setup…'),
            ),
            MenuItemButton(
              leadingIcon: const Icon(Icons.restart_alt),
              onPressed: onReset,
              child: const Text('Reset filters and options'),
            ),
            const Divider(height: 1),
            MenuItemButton(
              leadingIcon: const Icon(Icons.print_outlined),
              trailingIcon: const Text('Ctrl+P'),
              onPressed: printEnabled ? onPrint : null,
              child: const Text('Print'),
            ),
          ],
          builder: (context, controller, _) => IconButton(
            key: const ValueKey('viewer-overflow'),
            tooltip: 'Page setup and more',
            onPressed: () =>
                controller.isOpen ? controller.close() : controller.open(),
            icon: const Icon(Icons.more_vert),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}
