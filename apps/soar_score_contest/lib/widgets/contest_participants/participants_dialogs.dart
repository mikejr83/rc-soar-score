import 'package:flutter/material.dart';
import 'package:soar_score_core/soar_score_core.dart';

/// What the director chose when adding a person.
class AddChoice {
  const AddChoice(this.role);

  /// The role, or `null` for the system Pilot role.
  final Role? role;
}

/// Asks before adding [name] to a contest: which role (when the contest has
/// roles) and, after the draw, that a pilot added now is not in the matrix
/// yet. Non-flying roles are not placed in the matrix, so they skip that
/// warning. Returns `null` when the director cancels.
Future<AddChoice?> askAddParticipant(
  BuildContext context, {
  required String name,
  required List<Role>? roles,
  required bool drawn,
}) => showDialog<AddChoice>(
  context: context,
  builder: (context) => _AddDialog(name: name, roles: roles, drawn: drawn),
);

class _AddDialog extends StatefulWidget {
  const _AddDialog({
    required this.name,
    required this.roles,
    required this.drawn,
  });

  final String name;
  final List<Role>? roles;
  final bool drawn;

  @override
  State<_AddDialog> createState() => _AddDialogState();
}

class _AddDialogState extends State<_AddDialog> {
  Role? _role;

  @override
  void initState() {
    super.initState();
    _role = widget.roles
        ?.where((role) => role.id == SystemRoles.pilotId)
        .firstOrNull;
  }

  bool get _flies => _role == null || _role!.type == RoleType.pilot;

  @override
  Widget build(BuildContext context) {
    final roles = widget.roles;
    final late = widget.drawn && _flies;
    return AlertDialog(
      icon: const Icon(Icons.person_add),
      title: Text(late ? 'Add after the draw?' : 'Add ${widget.name}?'),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              late
                  ? 'The draw has already been made. ${widget.name} will be '
                        'added to the contest. Place them in a group from the '
                        'Matrix page. A redraw is also possible.'
                  : '${widget.name} will be added to the contest'
                        '${_role == null ? '' : ' as ${_role!.displayName}'}.',
              key: const ValueKey('add-participant-body'),
            ),
            if (roles != null) ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<Id>(
                key: const ValueKey('add-participant-role'),
                initialValue: _role?.id,
                decoration: const InputDecoration(
                  labelText: 'Role',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final role in roles)
                    DropdownMenuItem(
                      value: role.id,
                      child: Text(role.displayName),
                    ),
                ],
                onChanged: (id) => setState(
                  () => _role = roles.firstWhere((role) => role.id == id),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const ValueKey('add-participant-confirm'),
          onPressed: () => Navigator.of(context).pop(AddChoice(_role)),
          child: const Text('Add participant'),
        ),
      ],
    );
  }
}

/// After adding [name] to a drawn contest that has no scores yet: offers to
/// draw the matrix again with them in it. `true` redraws (the page opens the
/// Matrix page's redraw), `false` or dismissing keeps the matrix and puts
/// them in the last group of every round.
Future<bool> askRedrawWith(BuildContext context, {required String name}) async {
  final redraw = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      icon: const Icon(Icons.grid_view),
      title: Text('Redraw the matrix with $name?'),
      content: SizedBox(
        width: 460,
        child: Text(
          'No scores have been entered, so the matrix can be drawn again to '
          'include $name fairly. Or keep the matrix as it is: $name is then '
          'added to the last group of every round, within the contest’s '
          'group sizes and team protection.',
          key: const ValueKey('redraw-offer-body'),
        ),
      ),
      actions: [
        TextButton(
          key: const ValueKey('redraw-keep'),
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Keep the matrix'),
        ),
        FilledButton(
          key: const ValueKey('redraw-with'),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Redraw'),
        ),
      ],
    ),
  );
  return redraw ?? false;
}

/// Asks before a pilot becomes non-flying, which clears their class
/// ([classification] is blank when there is none) and, when they have places
/// in the draw ([inDraw]), takes those out of it.
Future<bool> confirmNonFlying(
  BuildContext context, {
  required String name,
  required String roleName,
  required String classification,
  bool inDraw = false,
  bool plural = false,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      icon: const Icon(Icons.badge),
      title: Text('Change $name to $roleName?'),
      content: Text(
        [
          '$roleName is a non-flying role, so $name ${plural ? 'get' : 'gets'} no score rows'
              '${classification.trim().isEmpty ? '' : ' and their class ($classification) is cleared'}.',
          if (inDraw)
            'Their places in the draw are removed when you save, and the '
                'draw will need redoing.',
          'You can still undo this before you save.',
        ].join(' '),
        key: const ValueKey('confirm-role-change-body'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const ValueKey('confirm-role-change'),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Change role'),
        ),
      ],
    ),
  );
  return ok ?? false;
}

/// Asks before removing [names] from the contest.
///
/// [inDraw] names those who have places in the draw: they leave it, and the
/// draw will need redoing.
Future<bool> confirmRemove(
  BuildContext context, {
  required List<String> names,
  required String contestName,
  List<String> inDraw = const [],
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      icon: const Icon(Icons.person_remove),
      title: Text(
        'Remove ${names.length} ${names.length == 1 ? 'person' : 'people'} '
        'from this contest?',
      ),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This removes them from $contestName only. Their saved '
              'profiles stay, and you can add them again later.',
            ),
            if (inDraw.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                '${_names(inDraw)} ${inDraw.length == 1 ? 'is' : 'are'} in '
                'the draw. Their places in it are removed too, and the draw '
                'will need redoing.',
                key: const ValueKey('confirm-remove-draw'),
              ),
            ],
            const SizedBox(height: 12),
            for (final name in names)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    const Icon(Icons.person_remove_outlined, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(name)),
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const ValueKey('confirm-remove'),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text('Remove ${names.length}'),
        ),
      ],
    ),
  );
  return ok ?? false;
}

String _names(List<String> names) => names.length < 2
    ? names.join()
    : '${names.sublist(0, names.length - 1).join(', ')} and ${names.last}';
