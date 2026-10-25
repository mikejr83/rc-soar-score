import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// Covers [child] with the alpha release warning until the user ticks the
/// acknowledgement and continues. The acknowledgement is kept only for this
/// run of the app, so the warning returns on every launch.
///
/// [child] stays mounted underneath (the router keeps its place) but cannot
/// be reached by pointer, keyboard or screen reader while the warning shows.
class AlphaNoticeGate extends StatefulWidget {
  const AlphaNoticeGate({
    super.key,
    required this.enabled,
    required this.child,
  });

  /// When `false` the warning never shows (demo and E2E builds, tests).
  final bool enabled;

  final Widget child;

  @override
  State<AlphaNoticeGate> createState() => _AlphaNoticeGateState();
}

class _AlphaNoticeGateState extends State<AlphaNoticeGate> {
  bool _acknowledged = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || _acknowledged) return widget.child;
    return Stack(
      fit: StackFit.expand,
      children: [
        ExcludeFocus(
          child: ExcludeSemantics(child: AbsorbPointer(child: widget.child)),
        ),
        const ModalBarrier(dismissible: false, color: Colors.black54),
        FocusScope(
          autofocus: true,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _AlphaNoticeCard(
                onContinue: () => setState(() => _acknowledged = true),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AlphaNoticeCard extends StatefulWidget {
  const _AlphaNoticeCard({required this.onContinue});

  final VoidCallback onContinue;

  @override
  State<_AlphaNoticeCard> createState() => _AlphaNoticeCardState();
}

class _AlphaNoticeCardState extends State<_AlphaNoticeCard> {
  bool _understood = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Semantics(
      scopesRoute: true,
      explicitChildNodes: true,
      namesRoute: true,
      label: l10n.alphaNoticeTitle,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Material(
          elevation: 6,
          borderRadius: BorderRadius.circular(16),
          color: theme.colorScheme.surface,
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.alphaNoticeTitle,
                        style: theme.textTheme.headlineSmall,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.alphaNoticeIntro),
                        for (final text in [
                          l10n.alphaNoticeStorage,
                          l10n.alphaNoticeScoring,
                          l10n.alphaNoticeMissing,
                          l10n.alphaNoticePrimary,
                        ])
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(text),
                          ),
                        const SizedBox(height: 8),
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                          value: _understood,
                          onChanged: (v) =>
                              setState(() => _understood = v ?? false),
                          title: Text(l10n.alphaNoticeAcknowledge),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton(
                            onPressed: _understood ? widget.onContinue : null,
                            child: Text(l10n.alphaNoticeContinue),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
