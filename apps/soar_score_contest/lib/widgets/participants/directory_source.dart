import 'package:flutter/widgets.dart';

import '../../api_client_provider.dart';
import '../../auth/auth_session_inherited.dart';
import '../../services/participants/directory_pilot_source.dart';

/// The directory search for the signed-in director, or null when there is
/// none (signed out, or no hosted client): then the search lists only the
/// director's own profiles.
///
/// Keeps [previous] while the clients are the same, so the pilots already
/// found keep the ids their copies will have.
DirectoryPilotSource? directorySourceOf(
  BuildContext context,
  DirectoryPilotSource? previous,
) {
  final signedIn = authSessionOf(context)?.isSignedIn ?? false;
  final hosted = publicationClientOf(context);
  final local = apiClientOf(context);
  if (!signedIn || hosted == null || local == null) return null;
  if (previous != null &&
      identical(previous.hosted, hosted) &&
      identical(previous.local, local)) {
    return previous;
  }
  return DirectoryPilotSource(hosted: hosted, local: local);
}
