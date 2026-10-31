import 'package:flutter/material.dart';

import 'package:soar_score_ui_storage/soar_score_ui_storage.dart';

import '../l10n/app_localizations.dart';
import '../services/alpha_notice/alpha_notice_key.dart';
import '../services/ui_account/ui_account.dart';

/// Covers [child] with the alpha release warning until the user ticks the
/// acknowledgement and continues. With a [store] the acknowledgement time is
/// remembered on this device and the warning stays away for
/// [alphaNoticeQuietPeriod], so a page reload (such as the sign-in redirect on
/// web) does not bring it back. Without a store it is kept for this run only.
///
/// [child] stays mounted underneath (the router keeps its place) but cannot
/// be reached by pointer, keyboard or screen reader while the warning shows.
class AlphaNoticeGate extends StatefulWidget {
  const AlphaNoticeGate({
    super.key,
    required this.enabled,
    required this.child,
    this.store,
    this.now = DateTime.now,
  });

  /// Where the acknowledgement time is remembered; `null` keeps it in memory.
  final LocalUiStore? store;

  /// The current time; tests replace it.
  final DateTime Function() now;

  /// When `false` the warning never shows (demo and E2E builds, tests).
  final bool enabled;

  final Widget child;

  @override
  State<AlphaNoticeGate> createState() => _AlphaNoticeGateState();
}

class _AlphaNoticeGateState extends State<AlphaNoticeGate> {
  bool _acknowledged = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadAcknowledgement();
  }

  /// Reads the stored time; until it arrives the app stays covered, so the
  /// warning never flashes for someone who already acknowledged it.
  Future<void> _loadAcknowledgement() async {
    final store = widget.store;
    if (!widget.enabled || store == null) return;
    _loading = true;
    final at = await store.get(localUiAccountId, alphaNoticeAcknowledgedKey);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (at != null) {
        final age = widget.now().difference(at);
        _acknowledged = !age.isNegative && age < alphaNoticeQuietPeriod;
      }
    });
  }

  void _acknowledge() {
    setState(() => _acknowledged = true);
    final store = widget.store;
    if (store != null) {
      store.set(localUiAccountId, alphaNoticeAcknowledgedKey, widget.now());
    }
  }

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
        if (!_loading)
          FocusScope(
            autofocus: true,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _AlphaNoticeCard(onContinue: _acknowledge),
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
