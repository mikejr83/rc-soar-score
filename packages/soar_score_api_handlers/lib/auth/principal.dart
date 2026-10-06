import 'package:equatable/equatable.dart';
import 'package:shelf/shelf.dart';
import 'package:soar_score_core/soar_score_core.dart';

/// Request context key under which the auth layer stores the [Principal].
const String principalContextKey = 'soar_score.principal';

/// Who a request acts as: the account that owns what it creates and is the
/// actor of its mutations, and the authority it acts under.
///
/// The hosted server's token verifier produces one from the verified
/// identity. The embedded offline instance has no sign-in, so it uses the
/// installation's Local account (see [fixedPrincipal]). Handlers read it with
/// [requirePrincipal] and never learn which of the two supplied it.
class Principal extends Equatable {
  const Principal({
    required this.accountId,
    this.authority = Authority.director,
  });

  final Id accountId;
  final Authority authority;

  /// The metadata for a mutation this principal makes.
  ///
  /// [clientMutationId] is the request's idempotency key.
  MutationMetadata mutationMetadata({
    required String clientMutationId,
    required DateTime clientTime,
  }) => MutationMetadata(
    clientMutationId: clientMutationId,
    authority: authority,
    clientTime: clientTime,
    actorId: accountId,
  );

  @override
  List<Object?> get props => [accountId, authority];
}

/// The [Principal] the auth layer set on [request], or null if none did.
Principal? principalOf(Request request) =>
    request.context[principalContextKey] as Principal?;

/// The [Principal] of [request].
///
/// Throws a [StateError] when none is set: every route that needs one sits
/// behind an auth layer, so a missing principal is a wiring mistake, not a
/// client error.
Principal requirePrincipal(Request request) =>
    principalOf(request) ??
    (throw StateError('No principal on the request: auth layer not applied.'));

/// An auth layer that lets every request through as [principal].
///
/// For the embedded offline instance, which has no sign-in. It has the shape
/// of `AuthMiddleware`, so it plugs into `buildApiHandler` exactly where the
/// hosted server's token verification does.
Handler Function(Handler) fixedPrincipal(Principal principal) =>
    (inner) =>
        (request) =>
            inner(request.change(context: {principalContextKey: principal}));
