import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../auth/auth_scope.dart';
import '../data/self_score_repository.dart';
import '../data/self_score_scope.dart';
import '../l10n/app_localizations.dart';
import '../models/own_directory.dart';
import '../router.dart';
import '../widgets/loadable_scaffold.dart';
import '../widgets/self_score_app_bar.dart';

/// Where a signed-in pilot says what contest directors may find (#652): their
/// name, "Let contest directors find me" and "Keep my email private", both
/// ticked until they say otherwise, and a few optional details. A pilot with
/// no entry yet arrives here once after signing in; continuing always makes
/// the entry, listed or not.
class DetailsPage extends StatelessWidget {
  const DetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final auth = context.auth;
    if (!auth.isSignedIn) {
      if (!auth.isInitializing) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) context.go(homePath);
        });
      }
      return Scaffold(
        appBar: SelfScoreAppBar(title: l10n.detailsTitle, showAccount: false),
      );
    }
    final repository = context.repository;
    return LoadableScaffold<OwnDirectory>(
      load: repository.ownDirectory,
      reloadKey: repository,
      appBar: (context, data) => SelfScoreAppBar(title: l10n.detailsTitle),
      builder: (context, data) => _DetailsForm(directory: data),
    );
  }
}

class _DetailsForm extends StatefulWidget {
  const _DetailsForm({required this.directory});

  final OwnDirectory directory;

  @override
  State<_DetailsForm> createState() => _DetailsFormState();
}

class _DetailsFormState extends State<_DetailsForm> {
  final _formKey = GlobalKey<FormState>();
  late final _first = TextEditingController(
    text: widget.directory.initial.firstName,
  );
  late final _last = TextEditingController(
    text: widget.directory.initial.lastName,
  );
  late final _fai = TextEditingController(
    text: widget.directory.initial.faiNumber,
  );
  late final _national = TextEditingController(
    text: widget.directory.initial.nationalOrgId,
  );
  late final _club = TextEditingController(text: widget.directory.initial.club);
  late final _country = TextEditingController(
    text: widget.directory.initial.country,
  );
  late bool _listed = widget.directory.initial.isListed;
  late bool _emailPrivate = !widget.directory.initial.emailVisibleToDirectors;
  bool _saving = false;
  bool _failed = false;

  @override
  void dispose() {
    for (final controller in [
      _first,
      _last,
      _fai,
      _national,
      _club,
      _country,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _continue() async {
    if (_saving || !(_formKey.currentState?.validate() ?? false)) return;
    final repository = context.repository;
    final router = GoRouter.of(context);
    setState(() {
      _saving = true;
      _failed = false;
    });
    try {
      await repository.saveOwnDirectory(
        DirectoryDetails(
          firstName: _first.text.trim(),
          lastName: _last.text.trim(),
          club: _club.text.trim(),
          faiNumber: _fai.text.trim(),
          nationalOrgId: _national.text.trim(),
          country: _country.text.trim(),
          isListed: _listed,
          emailVisibleToDirectors: !_emailPrivate,
        ),
      );
      router.go(contestsPath);
    } on SelfScoreLoadException {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    String? required(String? value) =>
        (value ?? '').trim().isEmpty ? l10n.detailsNameRequired : null;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                l10n.detailsIntro,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('details-first-name'),
                controller: _first,
                textCapitalization: TextCapitalization.words,
                autofillHints: const [AutofillHints.givenName],
                decoration: InputDecoration(labelText: l10n.detailsFirstName),
                validator: required,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('details-last-name'),
                controller: _last,
                textCapitalization: TextCapitalization.words,
                autofillHints: const [AutofillHints.familyName],
                decoration: InputDecoration(labelText: l10n.detailsLastName),
                validator: required,
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                key: const Key('details-listed'),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: _listed,
                onChanged: (value) => setState(() => _listed = value ?? true),
                title: Text(l10n.detailsListedTitle),
                subtitle: Text(l10n.detailsListedHelp),
              ),
              CheckboxListTile(
                key: const Key('details-email-private'),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: _emailPrivate,
                onChanged: (value) =>
                    setState(() => _emailPrivate = value ?? true),
                title: Text(l10n.detailsEmailPrivateTitle),
                subtitle: Text(l10n.detailsEmailPrivateHelp),
              ),
              ExpansionTile(
                key: const Key('details-more'),
                tilePadding: EdgeInsets.zero,
                title: Text(l10n.detailsMoreHeading),
                childrenPadding: const EdgeInsets.only(bottom: 12),
                children: [
                  TextFormField(
                    key: const Key('details-fai'),
                    controller: _fai,
                    decoration: InputDecoration(
                      labelText: l10n.detailsFaiNumber,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('details-national-id'),
                    controller: _national,
                    decoration: InputDecoration(
                      labelText: l10n.detailsNationalId,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('details-club'),
                    controller: _club,
                    decoration: InputDecoration(labelText: l10n.detailsClub),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('details-country'),
                    controller: _country,
                    decoration: InputDecoration(labelText: l10n.detailsCountry),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_failed) ...[
                Text(
                  l10n.detailsSaveFailed,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              FilledButton(
                key: const Key('details-continue'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: _saving ? null : _continue,
                child: Text(l10n.detailsContinue),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
