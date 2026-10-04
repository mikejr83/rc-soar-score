import 'write_context.dart';

/// The only way local code changes synchronized data.
///
/// Everything done through the [WriteContext] commits together or not at all.
/// Core never bumps a revision itself; the implementation does.
abstract interface class UnitOfWork {
  Future<T> run<T>(Future<T> Function(WriteContext context) body);
}
