import { describe, expect, it } from 'vitest';

import {
  apiRequestHeaders,
  apiTarget,
  forwardedClientHeader,
  proxySecretHeader,
  visitorAddress,
} from './api-proxy';

const secret = 'proxy-secret-proxy-secret-proxy-secret';

describe('visitorAddress', () => {
  it('prefers the Vercel header and takes its first entry', () => {
    expect(
      visitorAddress(
        new Headers({
          'x-vercel-forwarded-for': '203.0.113.7, 10.0.0.1',
          'x-real-ip': '198.51.100.1',
        }),
      ),
    ).toBe('203.0.113.7');
    expect(visitorAddress(new Headers({ 'x-real-ip': '198.51.100.1' }))).toBe(
      '198.51.100.1',
    );
  });

  it('ignores x-forwarded-for, which a visitor can write', () => {
    expect(
      visitorAddress(new Headers({ 'x-forwarded-for': '1.2.3.4' })),
    ).toBeUndefined();
  });
});

describe('apiRequestHeaders', () => {
  const vercel = new Headers({
    'x-vercel-forwarded-for': '203.0.113.7',
    accept: 'application/json',
  });

  it('adds the visitor address and the secret', () => {
    const headers = apiRequestHeaders(vercel, secret);
    expect(headers.get(forwardedClientHeader)).toBe('203.0.113.7');
    expect(headers.get(proxySecretHeader)).toBe(secret);
    expect(headers.get('accept')).toBe('application/json');
  });

  it('drops what the visitor sent in those headers', () => {
    const forged = new Headers({
      [forwardedClientHeader]: '6.6.6.6',
      [proxySecretHeader]: 'guess',
    });
    for (const s of [secret, undefined]) {
      const headers = apiRequestHeaders(forged, s);
      expect(headers.get(forwardedClientHeader)).toBeNull();
      expect(headers.get(proxySecretHeader)).toBeNull();
    }
  });

  it('adds nothing without a secret or without an address', () => {
    for (const headers of [
      apiRequestHeaders(vercel, undefined),
      apiRequestHeaders(vercel, ''),
      apiRequestHeaders(new Headers(), secret),
    ]) {
      expect(headers.get(forwardedClientHeader)).toBeNull();
      expect(headers.get(proxySecretHeader)).toBeNull();
    }
  });
});

describe('apiTarget', () => {
  it('drops one /api prefix and keeps the query', () => {
    expect(
      apiTarget('/api/public/publications', '?a=1', 'https://api.rcsoarscore.com/'),
    ).toBe('https://api.rcsoarscore.com/public/publications?a=1');
  });

  it('reaches the route the API mounts for opening a link', () => {
    // The server mounts it at /api/v1/self-scoring, so through the site it is
    // /api/api/v1/self-scoring/invitations/resolve.
    expect(
      apiTarget(
        '/api/api/v1/self-scoring/invitations/resolve',
        '',
        'https://api.rcsoarscore.com',
      ),
    ).toBe(
      'https://api.rcsoarscore.com/api/v1/self-scoring/invitations/resolve',
    );
  });

  it('defaults to the local server', () => {
    expect(apiTarget('/api/health', '')).toBe('http://localhost:8080/health');
  });
});
