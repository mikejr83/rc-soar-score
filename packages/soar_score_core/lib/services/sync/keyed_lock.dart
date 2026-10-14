import 'dart:async';

/// Runs bodies that share a key one after another.
///
/// The acceptor takes one per scope, so two exchanges for a scope never
/// assign the same sequence. It covers one process: a deployment that runs
/// several service instances needs a database lock instead.
class KeyedLock {
  final Map<Object, Future<void>> _tails = {};

  Future<T> run<T>(Object key, Future<T> Function() body) async {
    final previous = _tails[key] ?? Future<void>.value();
    final done = Completer<void>();
    final tail = done.future;
    _tails[key] = tail;
    await previous;
    try {
      return await body();
    } finally {
      done.complete();
      if (identical(_tails[key], tail)) _tails.remove(key);
    }
  }
}
