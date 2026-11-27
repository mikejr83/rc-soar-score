import 'package:equatable/equatable.dart';
import 'package:logging/logging.dart';

import '../enums/account_kind.dart';
import '../enums/account_status.dart';
import '../enums/participant_link_origin.dart';
import '../enums/participant_link_status.dart';
import '../errors/contest_state_error.dart';
import '../errors/entity_not_found_error.dart';
import '../errors/forbidden_error.dart';
import '../errors/participant_link_error.dart';
import '../models/accounts/account.dart';
import '../models/accounts/participant_account_link.dart';
import '../models/accounts/participant_directory_entry.dart';
import '../models/id.dart';
import '../repositories/repository.dart';
import 'participant_links/participant_link_service.dart';

final _logger = Logger('DirectoryLookup');

/// What a director types to find a pilot. One key per lookup, matched exactly.
enum DirectoryLookupKey { email, faiNumber, nationalOrgId }

/// A listed pilot as a director may see them: the entry's details, and the
/// account's email only when the pilot chose to show it.
///
/// [email] is null unless the pilot made it visible and the account's email is
/// verified. [emailAvailable] says there is one directors could be given.
class DirectoryMatch extends Equatable {
  const DirectoryMatch({
    required this.entry,
    required this.email,
    required this.emailAvailable,
    this.copiedProfileId,
    this.sharedKey = false,
  });

  final ParticipantDirectoryEntry entry;
  final String? email;
  final bool emailAvailable;

  /// The asking director's own profile this pilot was already copied to (the
  /// pilot's confirmed directory link to a profile that director owns), so a
  /// repeated search finds the same copy. Only the caller's own profiles are
  /// ever named.
  final Id? copiedProfileId;

  /// More than one listed pilot holds the key this match was found by (an FAI
  /// number or national ID; two countries can issue the same one). The
  /// director tells them apart by name and details; an ID alone proves
  /// nothing.
  final bool sharedKey;

  DirectoryMatch withSharedKey() => DirectoryMatch(
    entry: entry,
    email: email,
    emailAvailable: emailAvailable,
    copiedProfileId: copiedProfileId,
    sharedKey: true,
  );

  @override
  List<Object?> get props => [
    entry,
    email,
    emailAvailable,
    copiedProfileId,
    sharedKey,
  ];
}

/// A director finds listed pilots in the directory and copies one into their
/// pilot list (#653). Backend only.
///
/// - Lookup is by exact key only (verified email, FAI number or national
///   organization ID); there is no name search and no listing. An unlisted
///   pilot, an account without an entry and a key nobody holds all answer
///   the same empty list.
/// - A stored email is returned only when the pilot made it visible, and a
///   pilot who keeps it private is not found by it (same empty answer as an
///   unknown address); the address a director typed is never logged.
/// - An ID lookup returns every listed pilot holding it, flagged
///   [DirectoryMatch.sharedKey] when several do; the director picks by name.
/// - Copying links the pilot's account to the director's profile (see
///   [ParticipantLinkService.linkFromDirectory]); the profile itself is the
///   director's own and independent of the account. Any number of directors
///   can copy the same pilot, each to a profile of their own.
/// - A refresh returns the pilot's current details, only to the director
///   whose confirmed directory link is still in place, and only while the
///   entry is still listed. It never writes.
class DirectoryLookupService {
  DirectoryLookupService(this.repository, [this.links]);

  final Repository repository;

  /// Needed to copy; null where the server issues no invitations. Looking up
  /// needs only the repository.
  final ParticipantLinkService? links;

  /// Listed entries of [key] = [value] for [directorAccountId].
  ///
  /// Throws [ForbiddenError] (`registered_account_required`) unless the
  /// director is a registered account. A blank [value] is an
  /// [ArgumentError].
  Future<List<DirectoryMatch>> lookup({
    required Id directorAccountId,
    required DirectoryLookupKey key,
    required String value,
  }) async {
    await _requireDirector(directorAccountId);
    final text = value.trim();
    if (text.isEmpty) {
      throw ArgumentError.value(value, 'value', 'must not be blank');
    }
    if (text.length > 254) {
      throw ArgumentError.value(text.length, 'value', 'is too long');
    }
    final entries = repository.participantDirectoryEntryRepository;
    final found = switch (key) {
      DirectoryLookupKey.email => await _byEmail(text, directorAccountId),
      DirectoryLookupKey.faiNumber => [
        for (final entry in await entries.listListedByFaiNumber(text))
          await _match(entry, directorAccountId),
      ],
      DirectoryLookupKey.nationalOrgId => [
        for (final entry in await entries.listListedByNationalOrgId(text))
          await _match(entry, directorAccountId),
      ],
    };
    // Every pilot holding an ID comes back, never just one: the ID is the
    // pilot's own claim, so the director picks by name, and a key held by
    // several is flagged.
    final present = [for (final m in found) ?m];
    final matches = key != DirectoryLookupKey.email && present.length > 1
        ? [for (final m in present) m.withSharedKey()]
        : present;
    _logger.info(
      'lookup director=${directorAccountId.value} key=${key.name} '
      'results=${matches.length}',
    );
    return matches;
  }

  /// Copies the listed entry [entryId] for [directorAccountId]: links the
  /// pilot's account to [profileId] (the director's profile, which may not
  /// have reached the server yet) and returns the details to copy.
  ///
  /// Throws `link_not_found` for an entry that does not exist or is not
  /// listed, and the errors of [ParticipantLinkService.linkFromDirectory]
  /// (`profile_not_owned`, `already_linked`). Repeating it changes nothing.
  Future<DirectoryMatch> copy({
    required Id directorAccountId,
    required Id entryId,
    required Id profileId,
  }) async {
    await _requireDirector(directorAccountId);
    final entry = await _listedEntry(entryId);
    await _links.linkFromDirectory(
      profileId: profileId,
      accountId: entry.accountId,
      directorAccountId: directorAccountId,
    );
    final match = await _match(entry, directorAccountId);
    if (match == null) throw ParticipantLinkError.linkNotFound();
    _logger.info(
      'copy director=${directorAccountId.value} profile=${profileId.value}',
    );
    return match;
  }

  /// The current details of [entryId] for the director who copied it to
  /// [profileId]. Throws `link_not_found` unless [profileId] is a profile of
  /// that director on the server (a refresh waits for the profile to sync)
  /// that holds the confirmed directory link to this entry's account and the
  /// entry is still listed: the same answer for every other reason.
  Future<DirectoryMatch> refresh({
    required Id directorAccountId,
    required Id entryId,
    required Id profileId,
  }) async {
    await _requireDirector(directorAccountId);
    final entry = await _listedEntry(entryId);
    final profile = await repository.participantProfileRepository.findById(
      profileId,
    );
    // A link says nothing of which director made it, so the profile must be
    // on the server and the caller's own: an id nobody has synced yet proves
    // nothing.
    if (profile == null || profile.ownerAccountId != directorAccountId) {
      throw ParticipantLinkError.linkNotFound();
    }
    final link = await repository.participantAccountLinkRepository.find(
      participantProfileId: profileId,
      accountId: entry.accountId,
    );
    if (link == null || !_isDirectoryLink(link)) {
      throw ParticipantLinkError.linkNotFound();
    }
    final match = await _match(entry, directorAccountId);
    if (match == null) throw ParticipantLinkError.linkNotFound();
    return match;
  }

  static bool _isDirectoryLink(ParticipantAccountLink link) =>
      link.status == ParticipantLinkStatus.confirmed &&
      link.origin == ParticipantLinkOrigin.directoryPull;

  Future<ParticipantDirectoryEntry> _listedEntry(Id entryId) async {
    final entry = await repository.participantDirectoryEntryRepository.findById(
      entryId,
    );
    if (entry == null || !entry.isListed) {
      throw ParticipantLinkError.linkNotFound();
    }
    return entry;
  }

  /// The match of the verified [email], if its account is listed and shows
  /// its email to directors.
  ///
  /// A pilot who keeps the email private is not found by it: a stranger
  /// could otherwise confirm that an address belongs to a listed pilot.
  /// Every outcome that answers "nobody" (no such account, an unverified
  /// email, no entry, an unlisted one) does the same two reads, so the
  /// answer's timing says nothing about which it was.
  Future<List<DirectoryMatch?>> _byEmail(
    String email,
    Id directorAccountId,
  ) async {
    final account = await repository.accountRepository.findByEmail(email);
    final entry = await repository.participantDirectoryEntryRepository
        .findForAccount(account?.id ?? Id.create());
    if (account == null ||
        !account.emailVerified ||
        entry == null ||
        !entry.isListed ||
        !entry.emailVisibleToDirectors) {
      return const [];
    }
    return [await _view(entry, account, directorAccountId)];
  }

  ParticipantLinkService get _links =>
      links ??
      (throw ContestStateError(
        'invitations_not_available',
        'this server does not issue invitations',
      ));

  /// The entry as a director may see it, or null when its account can no
  /// longer be found by directors (not an active registered account).
  Future<DirectoryMatch?> _match(
    ParticipantDirectoryEntry entry,
    Id directorAccountId,
  ) async {
    final account = await repository.accountRepository.findById(
      entry.accountId,
    );
    if (account == null) return null;
    return _view(entry, account, directorAccountId);
  }

  Future<DirectoryMatch?> _view(
    ParticipantDirectoryEntry entry,
    Account account,
    Id directorAccountId,
  ) async {
    if (account.kind != AccountKind.registered ||
        account.status != AccountStatus.active) {
      return null;
    }
    final available = account.email != null && account.emailVerified;
    return DirectoryMatch(
      entry: entry,
      email: available && entry.emailVisibleToDirectors ? account.email : null,
      emailAvailable: available,
      copiedProfileId: await _copiedProfile(directorAccountId, account.id),
    );
  }

  /// The profile of [directorAccountId] that [accountId] was copied to.
  Future<Id?> _copiedProfile(Id directorAccountId, Id accountId) async {
    final links = await repository.participantAccountLinkRepository
        .listForAccount(accountId);
    for (final link in links) {
      if (!_isDirectoryLink(link)) continue;
      final profile = await repository.participantProfileRepository.findById(
        link.participantProfileId,
      );
      if (profile != null && profile.ownerAccountId == directorAccountId) {
        return profile.id;
      }
    }
    return null;
  }

  Future<Account> _requireDirector(Id accountId) async {
    final account = await repository.accountRepository.findById(accountId);
    if (account == null) {
      throw EntityNotFoundError(entityType: 'Account', entityId: accountId);
    }
    if (account.kind != AccountKind.registered) {
      throw ForbiddenError(
        'registered_account_required',
        'only a signed-in account can look up pilots',
      );
    }
    return account;
  }
}
