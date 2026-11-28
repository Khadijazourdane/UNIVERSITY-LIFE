import assert from 'node:assert/strict';
import { test } from 'node:test';

import { createPasswordService } from '../src/modules/auth/auth.password.js';
import { AuthRepositoryUnavailableError } from '../src/modules/auth/auth.repository.js';
import { createAuthService } from '../src/modules/auth/auth.service.js';
import { createSessionStore } from '../src/modules/auth/auth.session-store.js';

const email = 'compte-test@edu.uiz.ac.ma';
const password = 'ancien-test';
const newPassword = 'nouveau-test';
const dummyHash = 'hash-factice-reserve-au-test';

function fixture({ role = 'etudiant', beforeVerify, beforeUpdate, now } = {}) {
  const account = {
    id_utilisateur: 42, nom: 'Exemple', prenom: 'Compte', email, role, mot_de_passe: `hash:${password}`,
  };
  const comparisons = [];
  const repository = {
    async findByEmail(address) {
      return address === account.email ? { ...account } : null;
    },
    async findById(userId) {
      return userId === account.id_utilisateur ? { ...account } : null;
    },
    async updatePassword({ userId, expectedHash, newHash }) {
      await beforeUpdate?.();
      if (userId !== account.id_utilisateur || expectedHash !== account.mot_de_passe) return false;
      account.mot_de_passe = newHash;
      return true;
    },
  };
  const passwords = createPasswordService({
    dummyHash,
    async verify(value, hash) {
      comparisons.push(hash);
      await beforeVerify?.();
      return `hash:${value}` === hash;
    },
    async hash(value) {
      return `hash:${value}`;
    },
  });
  const auth = createAuthService({ repository, passwords, sessions: createSessionStore({ ttlMs: 10000, now }) });
  return { account, comparisons, repository, auth };
}

for (const role of ['etudiant', 'professeur', 'admin']) {
  test(`connexion et restauration avec le rôle officiel ${role}`, async () => {
    const { auth } = fixture({ role });
    const session = await auth.login({ email: ' Compte-Test@EDU.UIZ.AC.MA ', password });
    const profile = { id_utilisateur: 42, nom: 'Exemple', prenom: 'Compte', email, role };
    assert.deepEqual(session.user, profile);
    assert.deepEqual(await auth.me(session.token), { user: profile, expiresAt: session.expiresAt });
  });
}

test('un compte absent et un mauvais mot de passe utilisent le vérificateur et la même erreur publique', async () => {
  const { auth, comparisons } = fixture();
  await assert.rejects(auth.login({ email, password: 'incorrect' }), { code: 'INVALID_CREDENTIALS' });
  await assert.rejects(auth.login({ email: 'absent@edu.uiz.ac.ma', password }), { code: 'INVALID_CREDENTIALS' });
  assert.deepEqual(comparisons, [`hash:${password}`, dummyHash]);
});

test('un rôle inconnu est refusé et le rôle envoyé par le client est rejeté', async () => {
  const { auth } = fixture({ role: 'administrator' });
  await assert.rejects(auth.login({ email, password }), { code: 'INVALID_CREDENTIALS' });
  await assert.rejects(auth.login({ email, password, role: 'admin' }), { code: 'INVALID_REQUEST' });
});

test('un changement de rôle ou du hash en dehors du service invalide la session', async () => {
  const { auth, account } = fixture();
  const first = await auth.login({ email, password });
  account.role = 'professeur';
  await assert.rejects(auth.me(first.token), { code: 'SESSION_INVALID' });
  const second = await auth.login({ email, password });
  assert.equal(second.user.role, 'professeur');
  account.mot_de_passe = `hash:${newPassword}`;
  await assert.rejects(auth.me(second.token), { code: 'SESSION_INVALID' });
});

test('me refuse une session expirée ou révoquée et logout est idempotent', async () => {
  let now = 1000;
  const { auth } = fixture({ now: () => now });
  const expired = await auth.login({ email, password });
  now = 11000;
  await assert.rejects(auth.me(expired.token), { code: 'SESSION_INVALID' });
  const revoked = await auth.login({ email, password });
  const other = await auth.login({ email, password });
  auth.logout(revoked.token);
  auth.logout(revoked.token);
  await assert.rejects(auth.me(revoked.token), { code: 'SESSION_INVALID' });
  assert.equal((await auth.me(other.token)).user.id_utilisateur, 42);
});

test('le changement vérifie la règle de huit caractères et le mot de passe actuel', async () => {
  const { auth } = fixture();
  const first = await auth.login({ email, password });
  await assert.rejects(auth.changePassword(first.token, { currentPassword: password, newPassword: 'court' }), { code: 'PASSWORD_POLICY' });
  await assert.rejects(auth.changePassword(first.token, { currentPassword: password, newPassword: password }), { code: 'PASSWORD_POLICY' });
  await assert.rejects(auth.changePassword(first.token, { currentPassword: 'incorrect', newPassword }), { code: 'CURRENT_PASSWORD_INVALID' });
  await auth.changePassword(first.token, { currentPassword: password, newPassword: '12345678' });
  await assert.rejects(auth.me(first.token), { code: 'SESSION_INVALID' });
  assert.ok(await auth.login({ email, password: '12345678' }));
});

test('un changement réussi révoque toutes les sessions du compte', async () => {
  const { auth, account } = fixture();
  const first = await auth.login({ email, password });
  const second = await auth.login({ email, password });
  await auth.changePassword(first.token, { currentPassword: password, newPassword });
  assert.equal(account.mot_de_passe, `hash:${newPassword}`);
  await assert.rejects(auth.me(first.token), { code: 'SESSION_INVALID' });
  await assert.rejects(auth.me(second.token), { code: 'SESSION_INVALID' });
  await assert.rejects(auth.login({ email, password }), { code: 'INVALID_CREDENTIALS' });
});

test('une seule mise à jour concurrente du mot de passe aboutit', async () => {
  const bothWrites = Promise.withResolvers();
  let arrivals = 0;
  const { auth, account } = fixture({
    async beforeUpdate() {
      arrivals += 1;
      if (arrivals === 2) bothWrites.resolve();
      await bothWrites.promise;
    },
  });
  const { token } = await auth.login({ email, password });
  const [first, second] = await Promise.allSettled([
    auth.changePassword(token, { currentPassword: password, newPassword }),
    auth.changePassword(token, { currentPassword: password, newPassword: 'autre-mot-de-passe' }),
  ]);
  assert.deepEqual([first.status, second.status].sort(), ['fulfilled', 'rejected']);
  assert.equal((first.reason ?? second.reason).code, 'PASSWORD_UPDATE_CONFLICT');
  assert.ok(['hash:nouveau-test', 'hash:autre-mot-de-passe'].includes(account.mot_de_passe));
  await assert.rejects(auth.me(token), { code: 'SESSION_INVALID' });
});

test('une connexion en cours échoue si le hash change pendant la vérification', async () => {
  const started = Promise.withResolvers();
  const resume = Promise.withResolvers();
  const { auth, account } = fixture({
    async beforeVerify() {
      started.resolve();
      await resume.promise;
    },
  });
  const login = auth.login({ email, password });
  await started.promise;
  account.mot_de_passe = `hash:${newPassword}`;
  resume.resolve();
  await assert.rejects(login, { code: 'INVALID_CREDENTIALS' });
});

test('l’indisponibilité du dépôt devient une erreur Auth sans le message du pilote', async () => {
  const { auth, repository } = fixture();
  repository.findByEmail = async () => { throw new AuthRepositoryUnavailableError('secret-interne-de-test'); };
  await assert.rejects(auth.login({ email, password }), {
    code: 'AUTH_UNAVAILABLE', message: 'Service d’authentification temporairement indisponible.',
  });
});
