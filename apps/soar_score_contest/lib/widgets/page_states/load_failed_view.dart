import 'package:flutter/material.dart';

import '../../services/api_failure.dart';
import 'page_state_view.dart';

/// The page state for a load that failed with [error], sorted by kind:
///
/// - not signed in or not allowed: the authorization state, no Retry (trying
///   again does not grant access);
/// - not found: the not-found state, no Retry;
/// - an unreachable or failing server: the unavailable state with Retry;
/// - anything else (a rejected request, an unknown conflict): the
///   unavailable state with the server's message and no Retry, since sending
///   the same request again cannot change the answer.
Widget loadFailedView(
  Object error, {
  required String title,
  required VoidCallback onRetry,
  PageStateAction? secondary,
}) {
  final failure = ApiFailure.of(error);
  final retry = failure.retryable
      ? PageStateAction(
          key: const ValueKey('page-state-retry'),
          label: 'Retry',
          onPressed: onRetry,
        )
      : null;
  return switch (failure.kind) {
    ApiFailureKind.unauthorized => PageStateView.authorization(
      title: title,
      body: 'You are not signed in. Sign in again to continue.',
      secondary: secondary,
    ),
    ApiFailureKind.forbidden => PageStateView.authorization(
      title: title,
      body: 'Your account is not allowed to see this. ${failure.message}',
      secondary: secondary,
    ),
    ApiFailureKind.notFound => PageStateView.notFound(
      title: title,
      body: failure.message,
      secondary: secondary,
    ),
    _ => PageStateView.unavailable(
      title: title,
      body: failure.message,
      primary: retry,
      secondary: secondary,
    ),
  };
}
