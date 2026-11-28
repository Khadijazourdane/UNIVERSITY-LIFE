import { createHash, randomBytes } from 'node:crypto';

import { AuthError } from '../../middleware/error-handler.js';

export function fingerprint(value) {
  return createHash('sha256').update(value).digest('base64url');
}

function tokenKey(token) {
  if (typeof token === 'string' && /^[A-Za-z\d_-]{43}$/.test(token)) {
    return fingerprint(token);
  }
  return undefined;
}

export function createSessionStore({ ttlMs = 8 * 60 * 60 * 1000, maxSessions = 10000, now = Date.now } = {}) {
  if (!Number.isSafeInteger(ttlMs) || ttlMs <= 0 || ttlMs > 2147483647000
      || !Number.isSafeInteger(maxSessions) || maxSessions <= 0) {
    throw new RangeError('ttlMs et maxSessions doivent être des entiers positifs compatibles avec les cookies.');
  }

  const sessions = new Map();

  function purgeExpired(timestamp) {
    for (const [key, session] of sessions) {
      if (session.expiresAt <= timestamp) {
        sessions.delete(key);
      }
    }
  }

  function issue({ userId, role, passwordFingerprint }, previousToken) {
    const timestamp = now();
    const previousKey = tokenKey(previousToken);
    if (sessions.size >= maxSessions) {
      purgeExpired(timestamp);
      if (sessions.size >= maxSessions && !sessions.has(previousKey)) {
        throw new AuthError('AUTH_UNAVAILABLE');
      }
    }

    const token = randomBytes(32).toString('base64url');
    const expiresAt = timestamp + ttlMs;
    sessions.delete(previousKey);
    sessions.set(fingerprint(token), Object.freeze({ userId, role, passwordFingerprint, expiresAt }));
    return { token, expiresAt };
  }

  function get(token) {
    const key = tokenKey(token);
    const session = sessions.get(key);
    if (session && session.expiresAt <= now()) {
      sessions.delete(key);
      return undefined;
    }
    return session;
  }

  function revoke(token) {
    return sessions.delete(tokenKey(token));
  }

  function revokeUser(userId) {
    for (const [key, session] of sessions) {
      if (session.userId === userId) {
        sessions.delete(key);
      }
    }
  }

  return { issue, get, revoke, revokeUser };
}
