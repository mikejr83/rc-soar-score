/// Whether a failed access token renewal means the Auth0 session is over.
///
/// [code] and [details] are those of Auth0's `WebException`. A missing
/// refresh token, a required login or an invalid grant end the session; a
/// timeout or a dropped connection does not, so the pilot stays signed in and
/// the next call tries to renew again. Kept apart from `Auth0WebSession`
/// because that class only compiles for the web, and this is tested on the VM.
bool renewalEndsSession(String code, Map<String, dynamic> details) {
  if (code == 'MISSING_REFRESH_TOKEN' || code == 'MFA_REQUIRED') return true;
  return const {
    'login_required',
    'consent_required',
    'interaction_required',
    'invalid_grant',
    'missing_refresh_token',
  }.contains(details['code']);
}
