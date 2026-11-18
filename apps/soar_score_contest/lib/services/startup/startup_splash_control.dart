/// The "show the startup screen" setting, kept on this device.
///
/// Native builds only: the web build has no local database to build, so it
/// has no splash and no setting.
abstract class StartupSplashControl {
  /// Whether the splash is shown at start.
  bool get enabled;

  Future<void> setEnabled(bool value);
}
