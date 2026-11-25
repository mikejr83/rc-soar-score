import 'package:equatable/equatable.dart';

import '../enums/account_kind.dart';
import '../errors/entity_not_found_error.dart';
import '../errors/forbidden_error.dart';
import '../models/accounts/account.dart';
import '../models/accounts/participant_directory_entry.dart';
import '../models/id.dart';
import '../repositories/repository.dart';

/// What a person offers directors about themselves (#652): the entry, or
/// none yet, with the account's own name to start from and whether it has an
/// email directors could be given.
///
/// [emailAvailable] is only a fact about the account. The address itself is
/// never part of the entry or of this view.
class OwnDirectoryEntry extends Equatable {
  const OwnDirectoryEntry({
    required this.entry,
    required this.suggestedFirstName,
    required this.suggestedLastName,
    required this.emailAvailable,
  });

  /// Null until the account has made one.
  final ParticipantDirectoryEntry? entry;

  /// The account's own name, for a person who has no entry yet.
  final String suggestedFirstName;
  final String suggestedLastName;
  final bool emailAvailable;

  @override
  List<Object?> get props => [
    entry,
    suggestedFirstName,
    suggestedLastName,
    emailAvailable,
  ];
}

/// The details a signed-in account offers directors; one entry per account,
/// registered accounts only. Backend only.
class DirectoryEntryService {
  DirectoryEntryService(Repository repository, {DateTime Function()? clock})
    : _repository = repository,
      _clock = clock ?? DateTime.now;

  final Repository _repository;
  final DateTime Function() _clock;

  /// The view of [accountId]'s entry; its `entry` is null when it has none.
  ///
  /// Throws [ForbiddenError] (`registered_account_required`) for a guest,
  /// local or deleted account and [EntityNotFoundError] for an unknown one.
  Future<OwnDirectoryEntry> get(Id accountId) async {
    final account = await _registered(accountId);
    final entry = await _repository.participantDirectoryEntryRepository
        .findForAccount(accountId);
    return _view(entry, account);
  }

  /// Creates the entry of [accountId], or replaces its details, and returns
  /// it. Repeating a request changes nothing; the id and creation time of an
  /// existing entry are kept. Blank optional details are stored as none.
  ///
  /// A blank name is an [ArgumentError].
  Future<OwnDirectoryEntry> put({
    required Id accountId,
    required String firstName,
    required String lastName,
    String? club,
    String? faiNumber,
    String? nationalOrgId,
    String? city,
    String? state,
    String? country,
    required bool isListed,
    required bool emailVisibleToDirectors,
  }) async {
    final account = await _registered(accountId);
    final repository = _repository.participantDirectoryEntryRepository;
    final existing = await repository.findForAccount(accountId);
    final now = _clock().toUtc();
    final entry = ParticipantDirectoryEntry(
      id: existing?.id ?? Id.create(),
      accountId: accountId,
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      club: _clean(club),
      faiNumber: _clean(faiNumber),
      nationalOrgId: _clean(nationalOrgId),
      city: _clean(city),
      state: _clean(state),
      country: _clean(country),
      isListed: isListed,
      emailVisibleToDirectors: emailVisibleToDirectors,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );
    if (existing != null && _sameDetails(existing, entry)) {
      return _view(existing, account);
    }
    return _view(await repository.save(entry), account);
  }

  /// Removes the entry of [accountId]; whether it had one.
  Future<bool> delete(Id accountId) async {
    await _registered(accountId);
    final repository = _repository.participantDirectoryEntryRepository;
    final existing = await repository.findForAccount(accountId);
    if (existing == null) return false;
    return repository.remove(existing.id);
  }

  Future<Account> _registered(Id accountId) async {
    final account = await _repository.accountRepository.findById(accountId);
    if (account == null) {
      throw EntityNotFoundError(entityType: 'Account', entityId: accountId);
    }
    if (account.kind != AccountKind.registered) {
      throw ForbiddenError(
        'registered_account_required',
        'only a signed-in account can offer details to directors',
      );
    }
    return account;
  }

  OwnDirectoryEntry _view(ParticipantDirectoryEntry? entry, Account account) =>
      OwnDirectoryEntry(
        entry: entry,
        suggestedFirstName: account.firstName,
        suggestedLastName: account.lastName,
        emailAvailable: account.email != null && account.emailVerified,
      );

  static String? _clean(String? text) {
    final trimmed = text?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  /// Equal but for the timestamps: nothing to write.
  static bool _sameDetails(
    ParticipantDirectoryEntry a,
    ParticipantDirectoryEntry b,
  ) =>
      a.firstName == b.firstName &&
      a.lastName == b.lastName &&
      a.club == b.club &&
      a.faiNumber == b.faiNumber &&
      a.nationalOrgId == b.nationalOrgId &&
      a.city == b.city &&
      a.state == b.state &&
      a.country == b.country &&
      a.isListed == b.isListed &&
      a.emailVisibleToDirectors == b.emailVisibleToDirectors;
}
