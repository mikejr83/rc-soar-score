import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../api_client_provider.dart';
import '../router.dart';
import '../widgets/api_error_text.dart';
import '../widgets/master_detail.dart';
import '../widgets/page_states/page_states.dart';
import '../widgets/roles/role_detail_pane.dart';
import '../widgets/roles/role_list_pane.dart';
import '../widgets/roles/role_name_dialog.dart';
import '../widgets/sync/reload_on_sync.dart';

/// The director's roles: the system roles and their own non-flier roles
/// (system scope, `plan/ui/contest-administration/main-page.md`).
///
/// Wide windows show the list beside the selected role's detail; narrow ones
/// show the list, then the detail with a way back. The shell's `New role`
/// action opens this page with [createRequested] set, which opens the name
/// dialog. The Pilot and other system roles have no Rename or Delete and the
/// detail says why; a role that contests use cannot be deleted and the
/// detail shows where it is used.
class RolesPage extends StatefulWidget {
  const RolesPage({super.key, this.createRequested = false});

  final bool createRequested;

  @override
  State<RolesPage> createState() => _RolesPageState();
}

class _RolesPageState extends State<RolesPage> {
  Future<List<Role>>? _roles;
  Future<List<RoleUsage>>? _usage;
  Id? _usageFor;
  Id? _selectedId;
  bool _showDetail = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final first = _roles == null;
    _roles ??= _load();
    if (first && widget.createRequested) {
      _requestCreate();
    }
  }

  @override
  void didUpdateWidget(RolesPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.createRequested && !oldWidget.createRequested) {
      _requestCreate();
    }
  }

  /// Opens the dialog once the page is built, then clears the request.
  void _requestCreate() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted) {
      _create();
    }
  });

  Future<List<Role>> _load() {
    final client = apiClientOf(context);
    if (client == null) {
      return Future.error(StateError('No API client is available.'));
    }
    return client.roles().then(_sorted);
  }

  /// The system roles first, then the director's, each by name.
  static List<Role> _sorted(List<Role> roles) => [...roles]
    ..sort((a, b) {
      if (a.isSystem != b.isSystem) {
        return a.isSystem ? -1 : 1;
      }
      return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
    });

  void _reload() {
    final roles = _load();
    setState(() {
      _roles = roles;
      _usageFor = null;
    });
  }

  /// The usage of [role], loaded once per selected role.
  Future<List<RoleUsage>> _usageOf(Role role) {
    if (_usageFor != role.id || _usage == null) {
      _usageFor = role.id;
      _usage = role.isSystem
          ? Future.value(const <RoleUsage>[])
          : apiClientOf(context)!.roleUsage(role.id);
    }
    return _usage!;
  }

  void _reloadUsage() => setState(() => _usageFor = null);

  Future<void> _create() async {
    final client = apiClientOf(context)!;
    final id = Id.create();
    final created = await showRoleNameDialog(
      context,
      title: 'New role',
      confirmLabel: 'Create',
      onSubmit: (name) async {
        await client.createRole(CreateRoleRequest(id: id, displayName: name));
      },
    );
    if (!mounted) {
      return;
    }
    // Drop the request from the address so another tap on the action opens
    // the dialog again.
    context.go(rolesPath);
    if (created == true) {
      setState(() {
        _selectedId = id;
        _showDetail = true;
      });
      _reload();
    }
  }

  Future<void> _rename(Role role) async {
    final client = apiClientOf(context)!;
    final renamed = await showRoleNameDialog(
      context,
      title: 'Rename role',
      confirmLabel: 'Rename',
      initialName: role.displayName,
      onSubmit: (name) async {
        await client.renameRole(
          role.id,
          RenameRoleRequest(baseRevision: role.revision, displayName: name),
        );
      },
    );
    if (renamed == true && mounted) {
      _reload();
    }
  }

  Future<void> _delete(Role role) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete role?'),
        content: Text(
          '${role.displayName} will be removed from your roles. Contests '
          'are not affected.',
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
      await apiClientOf(context)!.deleteRole(role.id);
      if (mounted) {
        setState(() {
          _selectedId = null;
          _showDetail = false;
        });
        _reload();
      }
    } on Object catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(apiErrorText(error))));
      // The role may have been taken into use since the page loaded.
      if (mounted) {
        _reloadUsage();
      }
    }
  }

  @override
  Widget build(BuildContext context) =>
      ReloadOnSync.account(onSynced: _reload, child: _content(context));

  Widget _content(BuildContext context) => FutureBuilder<List<Role>>(
    future: _roles,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return loadFailedView(
          snapshot.error!,
          title: 'Roles could not be loaded.',
          onRetry: _reload,
        );
      }
      final all = snapshot.data;
      if (all == null) {
        return const PageStateView.loading(label: 'Loading roles');
      }
      // The first role is selected until one is chosen (or when the chosen
      // one is gone).
      final selected = all.firstWhere(
        (role) => role.id == _selectedId,
        orElse: () => all.first,
      );
      return MasterDetail(
        showDetail: _showDetail,
        list: (context, wide) => RoleListPane(
          roles: all,
          selectedId: selected.id,
          highlight: wide,
          onSelect: (role) => setState(() {
            _selectedId = role.id;
            _showDetail = true;
          }),
        ),
        detail: (context, wide) => RoleDetailPane(
          role: selected,
          usage: _usageOf(selected),
          onRetryUsage: _reloadUsage,
          onBack: wide ? null : () => setState(() => _showDetail = false),
          onRename: () => _rename(selected),
          onDelete: () => _delete(selected),
        ),
      );
    },
  );
}
