import 'package:flutter/material.dart';
import 'package:soar_score_core/soar_score_core.dart';
import 'package:soar_score_data/soar_score_data.dart';

import '../../main.dart';
import '../../widgets/connectivity_status_indicator.dart';
import 'participant_editor.dart';

/// The reusable participant (pilot) manager.
///
/// Route: `/contest-administration/participants`
///
/// The director manages their local, reusable participant records from here.
/// The page lists existing participants, allows selecting one to edit, and
/// supports adding new participants. Contest-specific values (class, role,
/// team, start number, model) are not edited here; those live on the contest
/// participation row.
class ParticipantsPage extends StatefulWidget {
  const ParticipantsPage({super.key});

  @override
  State<ParticipantsPage> createState() => _ParticipantsPageState();
}

class _ParticipantsPageState extends State<ParticipantsPage> {
  PilotRepository? _repository;
  List<Pilot> _participants = <Pilot>[];
  Pilot? _selected;
  bool _loading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_repository == null) {
      _repository = PilotRepositoryWidget.ofRequired(context);
      _load();
    }
  }

  Future<void> _load() async {
    final repository = _repository;
    if (repository == null) return;
    final pilots = await repository.getPilots();
    if (!mounted) return;
    setState(() {
      _participants = pilots;
      // Preserve the current selection only if it still exists.
      _selected = _selected == null
          ? null
          : pilots.firstWhere(
                (p) => p.id == _selected!.id,
                orElse: () => pilots.first,
              );
      _loading = false;
    });
  }

  /// Opens the editor to add a new participant or edit [existing].
  Future<void> _openEditor({Pilot? existing}) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => ParticipantEditor(
        pilot: existing,
        onSave: (pilot) async {
          final repository = _repository;
          if (repository == null) return;
          await repository.savePilot(pilot);
          await _load();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  existing == null
                      ? 'Participant added.'
                      : 'Participant updated.',
                ),
              ),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Participants'),
        actions: [
          _ConnectivityIndicators(),
          IconButton(
            tooltip: 'Back to contest list',
            icon: const Icon(Icons.arrow_back),
            onPressed: () =>
                Navigator.of(context).pushNamed('/contest-administration/home'),
          ),
        ],
      ),
      floatingActionButton: Tooltip(
        message: 'Add participant',
        child: FloatingActionButton.extended(
          onPressed: () => _openEditor(),
          icon: const Icon(Icons.person_add),
          label: const Text('Add participant'),
        ),
      ),
      body: Column(
        children: [
          // Participant list surface.
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.white12 : Colors.black12,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _buildList(),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Action bar for the selected participant.
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  // Enabled once a participant is selected.
                  FilledButton.icon(
                    onPressed: _selected == null
                        ? null
                        : () => _openEditor(existing: _selected),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Edit selected'),
                  ),
                  TextButton(
                    onPressed: _selected == null ? null : _confirmDelete,
                    child: const Text('Delete selected'),
                  ),
                  // Selection status for accessibility and keyboard users.
                  if (_selected != null)
                    Text(
                      'Selected: ${_selected!.firstName} ${_selected!.lastName}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_participants.isEmpty) {
      return const _EmptyParticipantsState();
    }
    return ListView.builder(
      itemCount: _participants.length,
      itemBuilder: (context, index) {
        final pilot = _participants[index];
        final isSelected = _selected?.id == pilot.id;
        // Each row sits inside its own Material so the selection highlight and
        // ink splashes paint on the row rather than the surrounding surface.
        return Material(
          color: Colors.transparent,
          child: ListTile(
            selected: isSelected,
            onTap: () => setState(() => _selected = pilot),
            onLongPress: () => _openEditor(existing: pilot),
            title: Text(
              '${pilot.firstName} ${pilot.lastName}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: _participantSubtitle(pilot).isEmpty
                ? null
                : Text(_participantSubtitle(pilot)),
            leading: const Icon(Icons.person_outline),
            trailing: IconButton(
              tooltip: 'Edit participant',
              icon: const Icon(Icons.edit),
              onPressed: () => _openEditor(existing: pilot),
            ),
          ),
        );
      },
    );
  }

  /// Secondary line for a participant row, summarizing optional contact data.
  String _participantSubtitle(Pilot pilot) {
    final parts = <String>[
      if (pilot.club != null && pilot.club!.isNotEmpty) pilot.club!,
      if (pilot.country != null && pilot.country!.isNotEmpty) pilot.country!,
    ];
    return parts.isEmpty ? '' : parts.join(' · ');
  }

  Future<void> _confirmDelete() async {
    final pilot = _selected;
    if (pilot == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete participant?'),
        content: Text(
          'This removes the reusable local record for '
          '"${pilot.firstName} ${pilot.lastName}" from this device. '
          'Contest entries that reference it are unaffected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await _repository!.deletePilot(pilot.id);
    setState(() => _selected = null);
    await _load();
  }
}

/// Empty state shown when the director has no reusable participant records.
class _EmptyParticipantsState extends StatelessWidget {
  const _EmptyParticipantsState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.people_outline, size: 48),
          SizedBox(height: 16),
          Text('No participants yet.'),
          SizedBox(height: 8),
          Text('Add a participant to get started.'),
        ],
      ),
    );
  }
}

/// Displays the internet and API connectivity indicators in the app bar.
class _ConnectivityIndicators extends StatelessWidget {
  const _ConnectivityIndicators();

  @override
  Widget build(BuildContext context) {
    final connectivity = ConnectivityStateWidget.of(context);
    if (connectivity == null) {
      return const SizedBox.shrink();
    }
    return AnimatedBuilder(
      animation: connectivity,
      builder: (context, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConnectivityStatusIndicator(
            state: connectivity.internet,
            label: 'Internet',
            icon: Icons.wifi,
            connectivity: connectivity,
          ),
          ConnectivityStatusIndicator(
            state: connectivity.api,
            label: 'API',
            icon: Icons.cloud,
            connectivity: connectivity,
          ),
        ],
      ),
    );
  }
}