import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/self_score_repository.dart';
import '../l10n/app_localizations.dart';
import '../router.dart';
import '../session/guest_session_scope.dart';
import 'load_error_view.dart';
import 'results_refresh_bar.dart';

/// A page scaffold that loads its data, shows a loading state while waiting,
/// an error with Retry when the load fails, and [builder] once it succeeds.
/// The data loads again when [reloadKey] changes, for example when the route
/// moves to another pilot.
class LoadableScaffold<T> extends StatefulWidget {
  const LoadableScaffold({
    required this.load,
    required this.reloadKey,
    required this.appBar,
    required this.builder,
    this.allowRefresh = false,
    super.key,
  });

  final Future<T> Function() load;

  /// Shows a manual refresh action and the last successful fetch time.
  final bool allowRefresh;

  /// Compared with `==`; a record of the repository and the route ids works.
  final Object reloadKey;

  /// Gets the loaded data, or null while loading or after a failure.
  final PreferredSizeWidget Function(BuildContext context, T? data) appBar;
  final Widget Function(BuildContext context, T data) builder;

  @override
  State<LoadableScaffold<T>> createState() => _LoadableScaffoldState<T>();
}

class _LoadableScaffoldState<T> extends State<LoadableScaffold<T>> {
  late Future<T> _future = _start();
  DateTime? _lastRefreshed;
  int _generation = 0;

  /// Loads, and drops the stored guest session when the server says it is
  /// over, so nothing routes from it again.
  Future<T> _start() {
    final generation = ++_generation;
    final future = Future<T>.sync(widget.load);
    future.then<void>(
      (_) {
        if (mounted && generation == _generation) {
          _lastRefreshed = DateTime.now();
        }
      },
      onError: (Object error) {
        if (error is SessionEndedException &&
            mounted &&
            generation == _generation) {
          context.guestSessions.clear();
        }
      },
    );
    return future;
  }

  @override
  void didUpdateWidget(LoadableScaffold<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reloadKey != widget.reloadKey) {
      _lastRefreshed = null;
      _future = _start();
    }
  }

  void _retry() {
    setState(() {
      _future = _start();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: _future,
      builder: (context, snapshot) {
        final data = snapshot.data;
        final Widget body;
        final loading = snapshot.connectionState != ConnectionState.done;
        if (loading) {
          body = Center(
            child: Semantics(
              label: 'Loading',
              child: const CircularProgressIndicator(),
            ),
          );
        } else if (snapshot.hasError) {
          final error = snapshot.error;
          body = error is SessionEndedException
              // Retrying cannot help: the person needs their link again.
              ? LoadErrorView(
                  message: error.message,
                  onRetry: () => context.go(homePath),
                  actionLabel: AppLocalizations.of(context).backToStart,
                  actionIcon: Icons.home_outlined,
                )
              : LoadErrorView(
                  message: error is SelfScoreLoadException
                      ? error.message
                      : 'Could not load this page. Check your connection and try '
                            'again.',
                  onRetry: _retry,
                );
        } else if (data == null) {
          body = Center(
            child: Semantics(
              label: 'Loading',
              child: const CircularProgressIndicator(),
            ),
          );
        } else {
          body = widget.builder(context, data);
        }
        return Scaffold(
          appBar: widget.appBar(
            context,
            loading || snapshot.hasError ? null : data,
          ),
          body: SafeArea(
            child: Column(
              children: [
                if (widget.allowRefresh)
                  ResultsRefreshBar(
                    lastRefreshed: _lastRefreshed,
                    loading: loading,
                    onRefresh: snapshot.error is SessionEndedException
                        ? null
                        : _retry,
                  ),
                Expanded(child: body),
              ],
            ),
          ),
        );
      },
    );
  }
}
