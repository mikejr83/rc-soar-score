/// A local web listener that receives Auth0's browser redirect while a
/// sign-in or sign-out is running (the "intermediary server" pattern of
/// `auth0_flutter` on Windows).
///
/// Auth0 sends the browser to the listener first. The listener shows a page
/// telling the person they may close the window and hands the callback on to
/// the app's custom URL scheme.
abstract interface class AuthCallbackListener {
  /// Starts listening. Throws an `AuthException` when the address cannot be
  /// used, for example because another program holds the port.
  Future<void> start();

  /// Stops listening and releases the port.
  Future<void> stop();
}
