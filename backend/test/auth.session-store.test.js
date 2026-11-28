import assert from 'node:assert/strict';
import { test } from 'node:test';

import { createSessionStore } from '../src/modules/auth/auth.session-store.js';

const user = { userId: 4, role: 'etudiant', passwordFingerprint: 'hash-fingerprint-for-test' };

test('le store émet des jetons aléatoires et expose uniquement les métadonnées de session', () => {
  const store = createSessionStore({ now: () => 1000 });
  const first = store.issue(user);
  const second = store.issue(user);
  assert.match(first.token, /^[A-Za-z0-9_-]{43}$/);
  assert.notEqual(first.token, second.token);
  assert.equal(first.expiresAt, 1000 + 8 * 60 * 60 * 1000);
  assert.deepEqual(store.get(first.token), { ...user, expiresAt: first.expiresAt });
  assert.equal(store.get('incorrect'), undefined);
  assert.equal(createSessionStore().get(first.token), undefined);
});

test('une session expire exactement à son échéance configurable', () => {
  let now = 10;
  const store = createSessionStore({ ttlMs: 100, now: () => now });
  const { token } = store.issue(user);
  now = 109;
  assert.ok(store.get(token));
  now = 110;
  assert.equal(store.get(token), undefined);
  assert.equal(store.revoke(token), false);
});

test('le store purge les sessions expirées à capacité maximale sans évincer les sessions valides', () => {
  let now = 10;
  const store = createSessionStore({ ttlMs: 100, maxSessions: 2, now: () => now });
  const first = store.issue(user);
  now = 20;
  const second = store.issue(user);
  assert.throws(() => store.issue(user), { code: 'AUTH_UNAVAILABLE' });
  now = 110;
  const third = store.issue(user);
  assert.equal(store.get(first.token), undefined);
  assert.ok(store.get(second.token));
  assert.ok(store.get(third.token));
});

test('la rotation libère la session précédente même à capacité maximale', () => {
  const store = createSessionStore({ maxSessions: 1 });
  const previous = store.issue(user);
  const rotated = store.issue(user, previous.token);
  assert.equal(store.get(previous.token), undefined);
  assert.ok(store.get(rotated.token));
});

test('la révocation est individuelle ou limitée au compte demandé', () => {
  const store = createSessionStore();
  const first = store.issue(user);
  const second = store.issue(user);
  const third = store.issue({ ...user, userId: 9 });
  assert.equal(store.revoke(first.token), true);
  assert.equal(store.revoke(first.token), false);
  assert.ok(store.get(second.token));
  store.revokeUser(user.userId);
  assert.equal(store.get(second.token), undefined);
  assert.ok(store.get(third.token));
});

test('le store refuse les configurations non positives ou non entières', () => {
  assert.throws(() => createSessionStore({ ttlMs: 0 }), RangeError);
  assert.throws(() => createSessionStore({ ttlMs: Infinity }), RangeError);
  assert.throws(() => createSessionStore({ maxSessions: 1.5 }), RangeError);
});
