import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../data/self_score_scope.dart';
import '../l10n/app_localizations.dart';
import '../models/own_directory.dart';
import '../router.dart';

/// A one-line prompt on the contests page for a signed-in pilot who has no
/// directory entry yet (#652), opening the details page. Loads its own state,
/// so a failure here never takes the contests page with it; nothing shows
/// while loading, on a failure, or once the pilot has an entry.
class DirectoryPromptCard extends StatefulWidget {
  const DirectoryPromptCard({super.key});

  @override
  State<DirectoryPromptCard> createState() => _DirectoryPromptCardState();
}

class _DirectoryPromptCardState extends State<DirectoryPromptCard> {
  Future<OwnDirectory>? _future;
  Object? _repository;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final repository = context.repository;
    if (_repository != repository) {
      _repository = repository;
      _future = repository.ownDirectory();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return FutureBuilder<OwnDirectory>(
      future: _future,
      builder: (context, snapshot) {
        final directory = snapshot.data;
        if (directory == null || directory.hasEntry) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Card(
            key: const Key('directory-prompt'),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      l10n.detailsPromptTitle,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(l10n.detailsPromptBody),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FilledButton(
                      onPressed: () => context.go(detailsPath),
                      child: Text(l10n.detailsPromptAction),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
