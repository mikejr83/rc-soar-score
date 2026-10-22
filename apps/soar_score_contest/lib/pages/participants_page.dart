import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../api_client_provider.dart';
import '../router.dart';
import '../widgets/api_error_text.dart';
import '../widgets/master_detail.dart';
import '../widgets/page_states/page_states.dart';
import '../widgets/participant_detail_pane.dart';
import '../widgets/participant_list_pane.dart';

/// The director's reusable participant list and detail (system scope,
/// `plan/ui/contest-administration/participant-data.md`).
///
/// Wide windows show the list beside the selected participant's detail;
/// narrow ones show the list, then the detail with a way back. Edit opens
/// the editor; Delete asks for confirmation and shows the server's reason
/// when a participant cannot be removed. Adding is the shell rail's action.
class ParticipantsPage extends StatefulWidget {
  const ParticipantsPage({super.key});

  @override
  State<ParticipantsPage> createState() => _ParticipantsPageState();
}

class _ParticipantsPageState extends State<ParticipantsPage> {
  Future<List<ParticipantProfile>>? _participants;
  String _search = '';
  Id? _selectedId;
  bool _showDetail = false;

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
        setState(() {
          _selectedId = null;
          _showDetail = false;
        });
        _reload();
      }
    } on Object catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(apiErrorText(error))));
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<ParticipantProfile>>(
    future: _participants,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return loadFailedView(
          snapshot.error!,
          title: 'Participants could not be loaded.',
          onRetry: _reload,
        );
      }
      final all = snapshot.data;
      if (all == null) {
        return const PageStateView.loading(label: 'Loading participants');
      }
      if (all.isEmpty) {
        return const PageStateView.empty(title: 'No participants yet.');
      }
      // The first participant is selected until one is chosen (or when the
      // chosen one is gone).
      final selected = all.firstWhere(
        (profile) => profile.id == _selectedId,
        orElse: () => all.first,
      );
      return MasterDetail(
        showDetail: _showDetail,
        list: (context, wide) => ParticipantListPane(
          participants: all,
          search: _search,
          onSearch: (value) => setState(() => _search = value),
          selectedId: selected.id,
          highlight: wide,
          onSelect: (profile) => setState(() {
            _selectedId = profile.id;
            _showDetail = true;
          }),
        ),
        detail: (context, wide) => ParticipantDetailPane(
          profile: selected,
          onBack: wide ? null : () => setState(() => _showDetail = false),
          onEdit: () => context.go(participantPath(selected.id.value)),
          onDelete: () => _delete(selected),
        ),
      );
    },
  );
}
