import 'package:flutter/widgets.dart';

import 'sample_self_score_repository.dart';
import 'self_score_repository.dart';

/// Provides the [SelfScoreRepository] to the pages. With no scope above, pages
/// get the sample repository.
class SelfScoreScope extends InheritedWidget {
  const SelfScoreScope({
    required this.repository,
    required super.child,
    super.key,
  });

  final SelfScoreRepository repository;

  @override
  bool updateShouldNotify(SelfScoreScope oldWidget) =>
      repository != oldWidget.repository;
}

extension SelfScoreRepositoryContext on BuildContext {
  /// The repository the pages read from.
  SelfScoreRepository get repository =>
      dependOnInheritedWidgetOfExactType<SelfScoreScope>()?.repository ??
      const SampleSelfScoreRepository();
}
