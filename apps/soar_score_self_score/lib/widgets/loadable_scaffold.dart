import 'package:flutter/material.dart';

import '../data/self_score_repository.dart';
import 'load_error_view.dart';

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
    super.key,
  });

  final Future<T> Function() load;

  /// Compared with `==`; a record of the repository and the route ids works.
  final Object reloadKey;

  /// Gets the loaded data, or null while loading or after a failure.
  final PreferredSizeWidget Function(BuildContext context, T? data) appBar;
  final Widget Function(BuildContext context, T data) builder;

  @override
  State<LoadableScaffold<T>> createState() => _LoadableScaffoldState<T>();
}

class _LoadableScaffoldState<T> extends State<LoadableScaffold<T>> {
  late Future<T> _future = widget.load();

  @override
  void didUpdateWidget(LoadableScaffold<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reloadKey != widget.reloadKey) {
      _future = widget.load();
    }
  }

  void _retry() {
    setState(() {
      _future = widget.load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: _future,
      builder: (context, snapshot) {
        final data = snapshot.data;
        final Widget body;
        if (snapshot.hasError) {
          final error = snapshot.error;
          body = LoadErrorView(
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
          return Scaffold(
            appBar: widget.appBar(context, data),
            body: SafeArea(child: widget.builder(context, data)),
          );
        }
        return Scaffold(
          appBar: widget.appBar(context, null),
          body: SafeArea(child: body),
        );
      },
    );
  }
}
