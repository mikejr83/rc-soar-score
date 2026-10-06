import 'package:soar_score_api_handlers/auth/principal.dart';
import 'package:soar_score_api_handlers/middleware/request_id.dart';
import 'package:soar_score_core/soar_score_core.dart';

/// The metadata for a write made by [principal].
///
/// Each write gets its own mutation id (the repository requires one per
/// contest and mutation), so two requests never collide on it.
MutationMetadata writeMetadata(Principal principal) =>
    principal.mutationMetadata(
      clientMutationId: generateRequestId(),
      clientTime: DateTime.now().toUtc(),
    );
