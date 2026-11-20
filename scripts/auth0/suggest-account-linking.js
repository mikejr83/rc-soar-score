const LINKING_CLAIM = 'https://rcsoarscore.com/account_linking_available';
const SUPPORTED_PROVIDERS = new Set(['auth0', 'google-oauth2', 'facebook']);
const REQUEST_TIMEOUT_MS = 3000;

function supportedUser(id) {
  return typeof id === 'string' && SUPPORTED_PROVIDERS.has(id.split('|')[0]);
}

async function managementToken(origin, secrets, api) {
  const cacheKey = 'soar-score-account-linking-read-token';
  const cached = api.cache.get(cacheKey);
  if (cached?.value) {
    return cached.value;
  }

  const response = await fetch(new URL('/oauth/token', origin), {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      grant_type: 'client_credentials',
      client_id: secrets.MANAGEMENT_CLIENT_ID,
      client_secret: secrets.MANAGEMENT_CLIENT_SECRET,
      audience: new URL('/api/v2/', origin).href,
    }),
    signal: AbortSignal.timeout(REQUEST_TIMEOUT_MS),
    redirect: 'error',
  });
  if (!response.ok) {
    throw new Error('Management API token request failed');
  }

  const { access_token: token, expires_in: expiresIn } = await response.json();
  if (typeof token !== 'string' || !token) {
    throw new Error('Management API response was missing a token');
  }

  const ttl = Math.min((expiresIn - 60) * 1000, 60 * 60 * 1000);
  if (ttl > 0) {
    api.cache.set(cacheKey, token, { ttl });
  }
  return token;
}

exports.onExecutePostLogin = async (event, api) => {
  if (
    event.transaction?.protocol === 'oauth2-refresh-token' ||
    event.user.email_verified !== true ||
    !event.user.email ||
    !supportedUser(event.user.user_id)
  ) {
    return;
  }

  const {
    SOAR_SCORE_CLIENT_IDS: clientIds,
    MANAGEMENT_DOMAIN: domain,
    MANAGEMENT_CLIENT_ID: managementClientId,
    MANAGEMENT_CLIENT_SECRET: managementClientSecret,
  } = event.secrets;
  const allowedClients = clientIds?.split(',').map((id) => id.trim());
  if (!allowedClients?.includes(event.client.client_id)) {
    return;
  }

  try {
    if (!domain || !managementClientId || !managementClientSecret) {
      throw new Error('Missing Management API configuration');
    }

    const origin = new URL(`https://${domain}`);
    if (
      origin.origin !== `https://${domain}` ||
      origin.href !== `https://${domain}/`
    ) {
      throw new Error('Expected a Management API hostname');
    }
    const token = await managementToken(origin, event.secrets, api);
    const url = new URL('/api/v2/users-by-email', origin);
    url.searchParams.set('email', event.user.email);
    url.searchParams.set('fields', 'user_id,email,email_verified');
    url.searchParams.set('include_fields', 'true');
    const response = await fetch(url, {
      headers: { Authorization: `Bearer ${token}` },
      signal: AbortSignal.timeout(REQUEST_TIMEOUT_MS),
      redirect: 'error',
    });
    if (!response.ok) {
      throw new Error('Management API account lookup failed');
    }

    const users = await response.json();
    const hasMatch = users.some(
      (user) =>
        user.user_id !== event.user.user_id &&
        supportedUser(user.user_id) &&
        user.email_verified === true &&
        user.email === event.user.email,
    );
    if (hasMatch) {
      api.idToken.setCustomClaim(LINKING_CLAIM, true);
    }
  } catch {
    // Sign-in can continue when Auth0's Management API is unavailable.
    console.log('Soar Score account linking check could not complete.');
  }
};
