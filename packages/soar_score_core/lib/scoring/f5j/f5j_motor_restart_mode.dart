/// How a motor restart is handled (`motor_restart_mode` option).
///
/// [json] is the stored text in `plan/data-model/examples/disciplines/f5j.md`.
enum F5jMotorRestartMode {
  /// A restart scores zero for the round, and the round can be dropped.
  allowed('allowed'),

  /// A restart scores zero, and the round can never be dropped.
  nonDroppable('non_droppable'),

  /// The entry schema omits the restart status. This configures the screens;
  /// it is not enforcement of the physical contest rule.
  notAllowed('not_allowed');

  const F5jMotorRestartMode(this.json);

  final String json;
}
