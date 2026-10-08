import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../api_client_provider.dart';
import '../router.dart';
import '../widgets/api_error_text.dart';
import '../widgets/landings/landing_detail_pane.dart';
import '../widgets/landings/landing_list_pane.dart';
import '../widgets/master_detail.dart';
import '../widgets/message_view.dart';

/// The director's landing tables beside the system ones (system scope,
/// `plan/ui/contest-administration/main-page.md`).
///
/// System tables are read-only. A table never changes: "Create copy" opens
/// the form pre-filled, and Delete is available only while no contest uses
/// the table. Adding is the shell rail's action.
class LandingsPage extends StatefulWidget {
  const LandingsPage({super.key});

  @override
  State<LandingsPage> createState() => _LandingsPageState();
}

class _LandingsPageState extends State<LandingsPage> {
  Future<List<LandingTableView>>? _tables;
  Id? _selectedId;
  bool _showDetail = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _tables ??= _load();
  }

  Future<List<LandingTableView>> _load() {
    final client = apiClientOf(context);
    if (client == null) {
      return Future.error(StateError('No API client is available.'));
    }
    return client.landingTables().then(_ordered);
  }

  /// The director's tables first, then the system ones, each by name.
  static List<LandingTableView> _ordered(List<LandingTableView> tables) =>
      [...tables]..sort((a, b) {
        if (a.table.isSystem != b.table.isSystem) {
          return a.table.isSystem ? 1 : -1;
        }
        return a.table.name.toLowerCase().compareTo(b.table.name.toLowerCase());
      });

  void _reload() {
    final tables = _load();
    setState(() {
      _tables = tables;
    });
  }

  Future<void> _delete(LandingTableView view) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete landing table?'),
        content: Text('${view.table.name} will be removed.'),
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
      await apiClientOf(context)!.deleteLandingTable(view.table.id);
    } on Object catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(apiErrorText(error))));
      // The table may have become locked since the list was loaded.
      if (mounted) {
        _reload();
      }
      return;
    }
    if (mounted) {
      setState(() {
        _selectedId = null;
        _showDetail = false;
      });
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<LandingTableView>>(
    future: _tables,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return MessageView(
          text: 'Landing tables could not be loaded.',
          detail: apiErrorText(snapshot.error!),
          onRetry: _reload,
        );
      }
      final all = snapshot.data;
      if (all == null) {
        return const Center(child: CircularProgressIndicator());
      }
      if (all.isEmpty) {
        return const MessageView(text: 'No landing tables yet.');
      }
      final selected = all.firstWhere(
        (view) => view.table.id == _selectedId,
        orElse: () => all.first,
      );
      return MasterDetail(
        showDetail: _showDetail,
        list: (context, wide) => LandingListPane(
          tables: all,
          selectedId: selected.table.id,
          highlight: wide,
          onSelect: (view) => setState(() {
            _selectedId = view.table.id;
            _showDetail = true;
          }),
        ),
        detail: (context, wide) => LandingDetailPane(
          view: selected,
          onBack: wide ? null : () => setState(() => _showDetail = false),
          onCopy: () => context.go(newLandingPath, extra: selected),
          onDelete: () => _delete(selected),
        ),
      );
    },
  );
}
