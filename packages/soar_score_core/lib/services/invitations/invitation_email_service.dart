import 'package:logging/logging.dart';

import '../../enums/audit_action.dart';
import '../../enums/audit_outcome.dart';
import '../../enums/authority.dart';
import '../../enums/role_type.dart';
import '../../errors/contest_state_error.dart';
import '../../errors/entity_not_found_error.dart';
import '../../models/contest/contest.dart';
import '../../models/id.dart';
import '../../models/participants/participant_profile.dart';
import '../../models/scores/invitation.dart';
import '../../models/sync/audit_event.dart';
import '../../repositories/repository.dart';
import '../../repositories/request_throttle_store.dart';
import 'invitation_service.dart';
import 'participant_access.dart';

/// What the provider said about one invitation email.
///
/// The first four are the answers to a send ([InvitationMailer]); `sending`
/// is stored while a send is in flight, and `bounced` and `complained` arrive
/// later from the provider. None of them is proof that the pilot read the
/// mail.
enum InvitationEmailStatus {
  /// A send was started and has no answer stored yet.
  sending('sending'),

  /// The provider took the message for delivery.
  accepted('accepted'),

  /// The provider refused the request; nothing was sent.
  rejected('rejected'),

  /// The sender could not send (not configured, throttled); nothing was sent.
  unavailable('unavailable'),

  /// The send may or may not have gone out.
  unconfirmed('unconfirmed'),

  /// The provider later reported that the address does not accept mail.
  bounced('bounced'),

  /// The recipient later marked the mail as unwanted.
  complained('complained'),

  /// Not sent: the director has reached the hourly limit of new emails for
  /// the contest. Nothing was sent; a later request with a new id can send.
  limited('limited');

  const InvitationEmailStatus(this.wire);

  /// The value stored in an invitation's delivery outcomes.
  final String wire;

  static InvitationEmailStatus? fromWire(Object? value) {
    for (final status in values) {
      if (status.wire == value) return status;
    }
    return null;
  }
}

/// What the provider later reported about an email it had accepted.
enum InvitationEmailFeedback {
  /// The address does not accept mail (a hard bounce, or a soft one the
  /// provider gave up on).
  bounce(InvitationEmailStatus.bounced),

  /// The recipient marked the mail as unwanted.
  complaint(InvitationEmailStatus.complained);

  const InvitationEmailFeedback(this.status);

  /// The status stored for it.
  final InvitationEmailStatus status;
}

/// One invitation email to send.
///
/// [link] is the pilot's secret link: whoever sends this must never log it.
class InvitationMail {
  const InvitationMail({
    required this.to,
    required this.pilotName,
    required this.contestName,
    required this.contestStart,
    required this.contestEnd,
    required this.timeZone,
    required this.location,
    required this.link,
  });

  final String to;
  final String pilotName;
  final String contestName;

  /// The contest's first and last moment, in UTC; [timeZone] is its IANA zone.
  final DateTime contestStart;
  final DateTime contestEnd;
  final String timeZone;

  /// Host, city, state and country that are set, in that order; may be empty.
  final List<String> location;
  final String link;
}

/// The answer to [InvitationMailer.send].
class InvitationMailResult {
  const InvitationMailResult(this.status, {this.messageId});

  /// One of `accepted`, `rejected`, `unavailable`, `unconfirmed`.
  final InvitationEmailStatus status;

  /// The provider's id for an accepted message.
  final String? messageId;
}

/// Sends one invitation email. The server implements it over the shared
/// transactional sender; tests use a fake.
abstract interface class InvitationMailer {
  Future<InvitationMailResult> send(InvitationMail mail);
}

/// Why a participation was not emailed.
enum InvitationEmailSkip {
  /// The pilot has no email address, or not one that looks like an address.
  noEmail,

  /// The participation has no active invitation to send.
  noInvitation,

  /// The invitation exists but its link cannot be recomputed (the server's
  /// secret changed since it was issued).
  linkUnavailable,

  /// Only pilots are invited so far.
  notPilot,
}

/// The result for one requested participation: either [skipped] with a reason
/// or the [status] of its email.
class InvitationEmailResult {
  const InvitationEmailResult.skipped(this.participationId, this.skipped)
    : status = null,
      repeated = false;

  const InvitationEmailResult.sent(
    this.participationId,
    InvitationEmailStatus this.status, {
    this.repeated = false,
  }) : skipped = null;

  final Id participationId;
  final InvitationEmailSkip? skipped;
  final InvitationEmailStatus? status;

  /// True when the request id had already been used for this participation,
  /// so nothing was sent now and [status] is the stored outcome.
  final bool repeated;
}

/// Attaches what the email provider reports later (a bounce or a complaint)
/// to the invitation email it is about (#790).
///
/// It needs only the repository, so reports about mail already sent are still
/// recorded when sending is switched off.
class InvitationDeliveryFeedback {
  InvitationDeliveryFeedback(this.repository, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final Repository repository;
  final DateTime Function() _clock;

  /// Records what the provider reported about the email it accepted under
  /// [messageId]: the entry's status becomes `bounced` or `complained`, with
  /// `reported_at` and, for a bounce, the provider's [bounceType]
  /// (`permanent`, `transient` or `undetermined`). Nothing else about the
  /// invitation or its link changes.
  ///
  /// Repeating a report changes nothing, a complaint replaces a bounce, and a
  /// bounce never replaces a complaint. Only an entry the provider accepted
  /// can be reported on. Returns whether a stored outcome changed; false for
  /// a message id that is not an invitation email (a support message, say).
  Future<bool> recordFeedback({
    required String messageId,
    required InvitationEmailFeedback feedback,
    String? bounceType,
  }) async {
    final invitationId = await repository.invitationRepository
        .findIdByDeliveryMessageId(messageId);
    if (invitationId == null) return false;
    final reportedAt = _clock().toUtc().toIso8601String();
    var changed = false;
    await repository.invitationRepository.updateDeliveryOutcomes(invitationId, (
      current,
    ) {
      changed = false;
      final index = current.indexWhere(
        (entry) =>
            entry['channel'] == 'email' && entry['message_id'] == messageId,
      );
      if (index < 0) return null;
      final entry = current[index];
      final stored = InvitationEmailStatus.fromWire(entry['status']);
      final wanted = feedback.status;
      final replaceable =
          stored == InvitationEmailStatus.accepted ||
          (stored == InvitationEmailStatus.bounced &&
              wanted == InvitationEmailStatus.complained);
      if (!replaceable) return null;
      changed = true;
      return [
        for (var i = 0; i < current.length; i++)
          if (i == index)
            {
              ...entry,
              'status': wanted.wire,
              'reported_at': reportedAt,
              if (feedback == InvitationEmailFeedback.bounce &&
                  bounceType != null)
                'bounce_type': bounceType,
            }
          else
            current[i],
      ];
    });
    return changed;
  }
}

final _logger = Logger('InvitationEmail');

/// Emails invitation links to pilots (#790).
///
/// Delivery is a side effect of a director's request, never a condition of
/// the link: the link exists whatever happens here, and an outcome other than
/// accepted changes nothing about it. Each send is stored on the invitation
/// before it is attempted, keyed by the request id, so a retry of the same
/// request never sends a second time (a send that was started and never
/// answered reads back as `unconfirmed`). Outcomes hold no address, message
/// text or link.
class InvitationEmailService {
  InvitationEmailService(
    this.repository,
    this.invitations,
    this.mailer, {
    required this.linkFor,
    this.throttle,
    this.maxSendsPerWindow = defaultMaxSendsPerWindow,
    this.window = const Duration(hours: 1),
    DateTime Function()? clock,
    Id Function()? newId,
  }) : _clock = clock ?? DateTime.now,
       _newId = newId ?? Id.create;

  final Repository repository;
  final InvitationService invitations;
  final InvitationMailer mailer;

  /// The pilot's link for an invitation [credential].
  final String Function(String credential) linkFor;
  final DateTime Function() _clock;
  final Id Function() _newId;

  /// The most participations one request takes.
  static const maxParticipations = 500;

  /// The most new emails one director may start for one contest in a
  /// [window]. A contest of 100 pilots emailed once, with a few resends,
  /// stays well under it.
  static const defaultMaxSendsPerWindow = 300;

  /// The bucket of the delivery counter in [throttle]; the caller is
  /// `{director id}:{contest id}`.
  static const throttleBucket = 'invitation-email';

  /// Counts each new send (never a retry of a request id that already has an
  /// outcome) in a counter shared by every server instance. Null means no
  /// limit, for tests that do not exercise it.
  final RequestThrottleStore? throttle;
  final int maxSendsPerWindow;
  final Duration window;

  static final _address = RegExp(
    r"^[A-Za-z0-9.!#$%&'*+/=?^_`{|}~-]+"
    r'@[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?'
    r'(?:\.[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?)+$',
  );

  /// Emails the active invitation of each of [participationIds] to its pilot.
  ///
  /// The contest must still be issuable (Configuring, Ready or Running), and
  /// every id must belong to it; otherwise nothing is sent. A participation
  /// that cannot be emailed (no address, no invitation) comes back skipped and
  /// the others are still sent. Repeating a [requestId] returns the stored
  /// outcome for each participation that was sent and sends nothing again.
  ///
  /// A request id guarantees at most one send per participation, not a
  /// remembered skip: a skip sends nothing and stores nothing, so a retry of
  /// the same id judges that pilot afresh and sends if they have become
  /// eligible (an address added, an invitation issued). That send is then
  /// stored, and a further retry returns it.
  Future<List<InvitationEmailResult>> emailMany({
    required Id contestId,
    required List<Id> participationIds,
    required Id requestedBy,
    required String requestId,
  }) async {
    final contest = await repository.contestRepository.findById(contestId);
    if (contest == null) {
      throw EntityNotFoundError(entityType: 'Contest', entityId: contestId);
    }
    final unique = participationIds.toSet().toList();
    final participations = {
      for (final id in unique)
        id: await repository.contestParticipationRepository.findById(id),
    };
    for (final entry in participations.entries) {
      if (entry.value == null || entry.value!.contestId != contestId) {
        throw EntityNotFoundError(
          entityType: 'ContestParticipation',
          entityId: entry.key,
        );
      }
    }

    // A request id that already has an outcome on one of the participation's
    // invitations (replaced ones included) answers with that outcome, before
    // anything about the pilot or the contest is checked again: what was
    // done does not change because the address, the role or the contest has
    // since changed.
    final earlier = <Id, Map<String, Object?>>{};
    for (final invitation
        in await repository.invitationRepository.listForContest(contestId)) {
      final entry = _entryFor(invitation.deliveryOutcomes, requestId);
      if (entry != null) earlier[invitation.contestParticipationId] = entry;
    }
    if (unique.any((id) => !earlier.containsKey(id))) {
      final check = invitations.issuability(contest);
      if (!check.canIssue) throw ContestStateError(check.code!, check.reason!);
    }

    final active = await invitations.activeForContest(contestId);
    final links = {
      for (final issued in active.links)
        issued.invitation.contestParticipationId: issued,
    };

    final results = <InvitationEmailResult>[];
    for (final id in unique) {
      final stored = earlier[id];
      if (stored != null) {
        results.add(
          InvitationEmailResult.sent(id, _storedStatus(stored), repeated: true),
        );
        continue;
      }
      final participation = participations[id]!;
      if (participation.roleType != RoleType.pilot) {
        results.add(
          InvitationEmailResult.skipped(id, InvitationEmailSkip.notPilot),
        );
        continue;
      }
      final issued = links[id];
      if (issued == null) {
        results.add(
          InvitationEmailResult.skipped(
            id,
            active.unreproducible.contains(id)
                ? InvitationEmailSkip.linkUnavailable
                : InvitationEmailSkip.noInvitation,
          ),
        );
        continue;
      }
      final profile = await repository.participantProfileRepository.findById(
        participation.participantProfileId,
      );
      final address = profile?.email?.trim();
      if (profile == null || address == null || !_address.hasMatch(address)) {
        results.add(
          InvitationEmailResult.skipped(id, InvitationEmailSkip.noEmail),
        );
        continue;
      }
      results.add(
        await _email(
          contest: contest,
          issued: issued,
          profile: profile,
          address: address,
          requestId: requestId,
          requestedBy: requestedBy,
        ),
      );
    }
    return results;
  }

  Future<InvitationEmailResult> _email({
    required Contest contest,
    required IssuedInvitation issued,
    required ParticipantProfile profile,
    required String address,
    required String requestId,
    required Id requestedBy,
  }) async {
    final invitation = issued.invitation;
    final participationId = invitation.contestParticipationId;
    final now = _clock().toUtc();

    // Claim the request id before sending: whoever stores the `sending`
    // entry owns the send; anyone who finds an entry for it already stored
    // reports that and sends nothing.
    var claimed = false;
    Map<String, Object?>? earlier;
    await repository.invitationRepository.updateDeliveryOutcomes(
      invitation.id,
      audit: AuditEvent(
        id: _newId(),
        entityType: 'Invitation',
        entityId: invitation.id,
        contestId: invitation.contestId,
        action: AuditAction.invitationDeliveryRequested,
        actorId: requestedBy,
        authority: Authority.director,
        resultingRevision: invitation.invitationRevision,
        serverTimestamp: now,
        outcome: AuditOutcome.success,
      ),
      (current) {
        claimed = false;
        earlier = _entryFor(current, requestId);
        if (earlier != null) return null;
        claimed = true;
        return [
          ...current,
          {
            'request_id': requestId,
            'channel': 'email',
            'status': InvitationEmailStatus.sending.wire,
            'at': now.toIso8601String(),
          },
        ];
      },
    );
    if (!claimed) {
      return InvitationEmailResult.sent(
        participationId,
        _storedStatus(earlier!),
        repeated: true,
      );
    }

    // The send is counted once it is ours: a retry of a request id, or the
    // loser of two requests racing with the same id, found the claim above and
    // never gets here, so it uses no capacity. Over the limit, or with the
    // counter unreadable, nothing is sent and the entry says why.
    final counter = throttle;
    if (counter != null) {
      InvitationEmailStatus? refused;
      try {
        final count = await counter.hit(
          throttleBucket,
          '${requestedBy.value}:${contest.id.value}',
          window: window,
          now: now,
        );
        if (count.count > maxSendsPerWindow) {
          refused = InvitationEmailStatus.limited;
        }
      } on Object {
        refused = InvitationEmailStatus.unavailable;
      }
      if (refused != null) {
        return _finish(invitation, requestId, InvitationMailResult(refused));
      }
    }

    final InvitationMailResult result;
    try {
      result = await mailer.send(
        InvitationMail(
          to: address,
          pilotName: '${profile.firstName} ${profile.lastName}',
          contestName: contest.name,
          contestStart: contest.startDateTime,
          contestEnd: contest.endDateTime,
          timeZone: contest.timezone,
          location: [
            for (final part in [
              contest.host,
              contest.city,
              contest.state,
              contest.country,
            ])
              if (part != null && part.trim().isNotEmpty) part.trim(),
          ],
          link: linkFor(issued.credential),
        ),
      );
    } on Object {
      return _finish(
        invitation,
        requestId,
        const InvitationMailResult(InvitationEmailStatus.unconfirmed),
      );
    }
    return _finish(invitation, requestId, result);
  }

  Future<InvitationEmailResult> _finish(
    Invitation invitation,
    String requestId,
    InvitationMailResult result,
  ) async {
    try {
      await repository.invitationRepository.updateDeliveryOutcomes(
        invitation.id,
        (current) => [
          for (final entry in current)
            if (entry['request_id'] == requestId)
              {
                ...entry,
                'status': result.status.wire,
                if (result.messageId != null) 'message_id': result.messageId,
              }
            else
              entry,
        ],
      );
    } on Object {
      // The mail has been handled by now, and its audit event was stored with
      // the claim. If this write is lost the entry stays `sending`, which a
      // retry reads as `unconfirmed` and never sends again, so the director is
      // told what the provider said and resends with a new request id if the
      // pilot did not get it.
      _logger.warning('An invitation email outcome could not be stored.');
    }
    return InvitationEmailResult.sent(
      invitation.contestParticipationId,
      result.status,
    );
  }

  /// The status to report for a stored entry. A claimed send with no answer
  /// may or may not have gone out, so it reads as unconfirmed.
  static InvitationEmailStatus _storedStatus(Map<String, Object?> entry) {
    final stored = InvitationEmailStatus.fromWire(entry['status']);
    return stored == null || stored == InvitationEmailStatus.sending
        ? InvitationEmailStatus.unconfirmed
        : stored;
  }

  static Map<String, Object?>? _entryFor(
    List<Map<String, Object?>> outcomes,
    String requestId,
  ) {
    for (final entry in outcomes) {
      if (entry['request_id'] == requestId) return entry;
    }
    return null;
  }
}
