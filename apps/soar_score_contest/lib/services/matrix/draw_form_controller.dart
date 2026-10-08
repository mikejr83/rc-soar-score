import 'package:flutter/widgets.dart';

/// The text the first-draw form holds, shared by the form and the page that
/// sends the draw. Values are kept as typed so a failed draw loses nothing.
class DrawFormController extends ChangeNotifier {
  DrawFormController({
    this.configuredRounds,
    this.configuredGroups,
    this.roundsSource = 'contest configuration',
    this.groupsSource = 'the New Contest wizard',
  }) : rounds = TextEditingController(text: configuredRounds?.toString()),
       groups = TextEditingController(text: configuredGroups?.toString()),
       seed = TextEditingController(),
       attempts = TextEditingController(text: '$defaultAttempts'),
       seedCount = TextEditingController(text: '$defaultSeedCount') {
    for (final controller in [rounds, groups, seed, attempts, seedCount]) {
      controller.addListener(notifyListeners);
    }
  }

  /// The server's defaults, shown so the director knows what blank means.
  static const int defaultAttempts = 50;
  static const int defaultSeedCount = 3;

  /// What the contest configuration holds, or `null` when it holds nothing.
  final int? configuredRounds;
  final int? configuredGroups;

  /// Where the defaults came from, for the note under each field.
  final String roundsSource;
  final String groupsSource;

  final TextEditingController rounds;
  final TextEditingController groups;
  final TextEditingController seed;
  final TextEditingController attempts;
  final TextEditingController seedCount;

  /// Set once the director has asked to draw, so empty fields are errors.
  bool get submitted => _submitted;
  bool _submitted = false;
  set submitted(bool value) {
    if (_submitted != value) {
      _submitted = value;
      notifyListeners();
    }
  }

  /// Whether [text] differs from [configured] (an empty field never does).
  static bool isEdited(String text, int? configured) =>
      configured != null &&
      text.trim().isNotEmpty &&
      text.trim() != '$configured';

  bool get roundsEdited => isEdited(rounds.text, configuredRounds);
  bool get groupsEdited => isEdited(groups.text, configuredGroups);

  /// The optional advanced number in [controller], or `null` when blank or
  /// not a whole number (the server then uses its default).
  static int? optionalNumber(TextEditingController controller) =>
      int.tryParse(controller.text.trim());

  @override
  void dispose() {
    for (final controller in [rounds, groups, seed, attempts, seedCount]) {
      controller.dispose();
    }
    super.dispose();
  }
}
