import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../api_client_provider.dart';
import '../router.dart';
import '../widgets/api_error_text.dart';
import '../widgets/message_view.dart';
import '../widgets/participant_search.dart';

/// The director's reusable participant list (system scope,
/// `plan/ui/contest-administration/participant-data.md`).
///
/// Rows open the editor; the delete action asks for confirmation and shows
/// the server's reason when a participant cannot be removed.
class ParticipantsPage extends StatefulWidget {
  const ParticipantsPage({super.key});

  @override
  State<ParticipantsPage> createState() => _ParticipantsPageState();
}

class _ParticipantsPageState extends State<ParticipantsPage> {
  Future<List<ParticipantProfile>>? _participants;
  String _search = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _participants ??= _load();
  }

  Future<List<ParticipantProfile>> _load() {
    final client = apiClientOf(context);
    if (client == null) {
      return Future.error(StateError('No API client is available.'));
    }
    return client.participants().then(_sorted);
  }

  /// The API lists profiles in creation order; the list shows them by last
  /// name, then first name, ignoring case.
  static List<ParticipantProfile> _sorted(List<ParticipantProfile> profiles) =>
      [...profiles]..sort((a, b) {
        final byLast = a.lastName.toLowerCase().compareTo(
          b.lastName.toLowerCase(),
        );
        return byLast != 0
            ? byLast
            : a.firstName.toLowerCase().compareTo(b.firstName.toLowerCase());
      });

  void _reload() {
    final participants = _load();
    setState(() {
      _participants = participants;
    });
  }

  Future<void> _delete(ParticipantProfile profile) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete participant?'),
        content: Text(
          '${profile.firstName} ${profile.lastName} will be removed from '
          'your participant list.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    try {
      await apiClientOf(context)!.deleteParticipant(profile.id);
      if (mounted) {
        _reload();
      }
    } on Object catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(apiErrorText(error))));
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Participants',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            FilledButton.icon(
              key: const ValueKey('add-participant'),
              onPressed: () => context.go(newParticipantPath),
              icon: const Icon(Icons.add),
              label: const Text('Add participant'),
            ),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: TextField(
          key: const ValueKey('participant-search'),
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'Search by name, email, FAI number or national ID',
          ),
          onChanged: (value) => setState(() => _search = value),
        ),
      ),
      Expanded(
        child: FutureBuilder<List<ParticipantProfile>>(
          future: _participants,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return MessageView(
                text: 'Participants could not be loaded.',
                detail: apiErrorText(snapshot.error!),
                onRetry: _reload,
              );
            }
            final all = snapshot.data;
            if (all == null) {
              return const Center(child: CircularProgressIndicator());
            }
            if (all.isEmpty) {
              return const MessageView(text: 'No participants yet.');
            }
            final participants = [
              for (final profile in all)
                if (matchesParticipantSearch(profile, _search)) profile,
            ];
            if (participants.isEmpty) {
              return const MessageView(text: 'No participants match.');
            }
            return ListView.separated(
              itemCount: participants.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final profile = participants[index];
                return ListTile(
                  title: _title(profile),
                  subtitle: Text(_subtitle(profile)),
                  onTap: () => context.go(participantPath(profile.id.value)),
                  trailing: IconButton(
                    tooltip: 'Delete ${profile.firstName} ${profile.lastName}',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _delete(profile),
                  ),
                );
              },
            );
          },
        ),
      ),
    ],
  );

  static Text _title(ParticipantProfile profile) {
    final email = profile.email;
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: '${profile.firstName} ${profile.lastName}'),
          if (email != null && email.isNotEmpty) ...[
            const WidgetSpan(child: SizedBox(width: 8)),
            TextSpan(
              text: email,
              style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  static String _subtitle(ParticipantProfile profile) {
    List<String> parts = [];
    if (profile.nationalOrgId != null && profile.nationalOrgId!.isNotEmpty) {
      parts.add("National ID: ${profile.nationalOrgId!}");
    }
    if (profile.faiNumber != null && profile.faiNumber!.isNotEmpty) {
      parts.add("FAI Number: ${profile.faiNumber!}");
    }

    return [
      ...parts,
      profile.club,
    ].whereType<String>().where((part) => part.isNotEmpty).join(' · ');
  }
}
