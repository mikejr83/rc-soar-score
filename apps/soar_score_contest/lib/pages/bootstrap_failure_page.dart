import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class BootstrapFailurePage extends StatefulWidget {
  const BootstrapFailurePage({
    required this.error,
    required this.onRetry,
    required this.onQuit,
    this.showQuit = !kIsWeb,
    super.key,
  });

  final Object error;
  final Future<void> Function() onRetry;
  final VoidCallback onQuit;
  final bool showQuit;

  @override
  State<BootstrapFailurePage> createState() => _BootstrapFailurePageState();
}

class _BootstrapFailurePageState extends State<BootstrapFailurePage> {
  late Object _error = widget.error;
  bool _retrying = false;

  Future<void> _retry() async {
    setState(() => _retrying = true);
    try {
      await widget.onRetry();
    } catch (error) {
      if (mounted) {
        setState(() => _error = error);
      }
    } finally {
      if (mounted) {
        setState(() => _retrying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.storage_rounded,
                  size: 40,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Application startup failed',
                  style: theme.textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Soar Score could not start. No partial contest data was '
                  'loaded.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                SelectableText('Reason: $_error', textAlign: TextAlign.center),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    FilledButton.icon(
                      onPressed: _retrying ? null : _retry,
                      icon: _retrying
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh),
                      label: Text(_retrying ? 'Retrying...' : 'Retry'),
                    ),
                    if (widget.showQuit)
                      OutlinedButton.icon(
                        onPressed: widget.onQuit,
                        icon: const Icon(Icons.close),
                        label: const Text('Quit'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
