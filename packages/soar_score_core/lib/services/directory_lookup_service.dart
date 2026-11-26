import 'package:equatable/equatable.dart';
import 'package:logging/logging.dart';

import '../enums/account_kind.dart';
import '../enums/account_status.dart';
import '../enums/participant_link_origin.dart';
import '../enums/participant_link_status.dart';
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
  });

  final ParticipantDirectoryEntry entry;
  final String? email;
  final bool emailAvailable;

  @override
  List<Object?> get props => [entry, email, emailAvailable];
}

/// A director finds listed pilots in the directory and copies one into their
/// pilot list (#653). Backend only.
///
/// - Lookup is by exact key only (verified email, FAI number or national
///   organization ID); there is no name search and no listing. An unlisted
///   pilot, an account without an entry and a key nobody holds all answer
///   the same empty list.
/// - A stored email is returned only when the pilot made it visible; the
///   address a director typed is never logged.
/// - Copying links the pilot's account to the director's profile (see
///   [ParticipantLinkService.linkFromDirectory]); the profile itself is the
///   director's own and independent of the account. Any number of directors
///   can copy the same pilot, each to a profile of their own.
/// - A refresh returns the pilot's current details, only to the director
///   whose confirmed directory link is still in place, and only while the
///   entry is still listed. It never writes.
class DirectoryLookupService {
  DirectoryLookupService(this.repository, this.links);

  final Repository repository;
  final ParticipantLinkService links;

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
    final entries = repository.participantDirectoryEntryRepository;
    final found = switch (key) {
      DirectoryLookupKey.email => await _byEmail(text),
      DirectoryLookupKey.faiNumber => await entries.listListedByFaiNumber(text),
      DirectoryLookupKey.nationalOrgId =>
        await entries.listListedByNationalOrgId(text),
    };
    final matches = [for (final entry in found) await _match(entry)];
    _logger.info(
      'lookup director=${directorAccountId.value} key=${key.name} '
      'results=${matches.length}',
    );
    return [for (final m in matches) ?m];
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
    await links.linkFromDirectory(
      profileId: profileId,
      accountId: entry.accountId,
      directorAccountId: directorAccountId,
    );
    final match = await _match(entry);
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
    final match = await _match(entry);
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

  Future<List<ParticipantDirectoryEntry>> _byEmail(String email) async {
    final account = await repository.accountRepository.findByEmail(email);
    if (account == null || !account.emailVerified) return const [];
    final entry = await repository.participantDirectoryEntryRepository
        .findForAccount(account.id);
    return entry == null || !entry.isListed ? const [] : [entry];
  }

  /// The entry as a director may see it, or null when its account can no
  /// longer be found by directors (not an active registered account).
  Future<DirectoryMatch?> _match(ParticipantDirectoryEntry entry) async {
    final account = await repository.accountRepository.findById(
      entry.accountId,
    );
    if (account == null ||
        account.kind != AccountKind.registered ||
        account.status != AccountStatus.active) {
      return null;
    }
    final available = account.email != null && account.emailVerified;
    return DirectoryMatch(
      entry: entry,
      email: available && entry.emailVisibleToDirectors ? account.email : null,
      emailAvailable: available,
    );
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
