import assert from 'node:assert/strict';
import { test } from 'node:test';

import { loadAuthConfig } from '../src/config/env.js';
import { createArgon2PasswordService } from '../src/modules/auth/auth.password.js';
import { createPostgresAuthRepository, AuthRepositoryUnavailableError } from '../src/modules/auth/auth.repository.js';
import { validateLogin, validatePasswordChange } from '../src/modules/auth/auth.validation.js';

test('Argon2id vérifie le mot de passe et utilise un sel aléatoire par hash', async () => {
  const { hash, verify } = await createArgon2PasswordService();
  const password = 'mot de passe de test';
  const first = await hash(password);
  const second = await hash(password);
  assert.match(first, /^\$argon2id\$v=19\$m=19456,t=2,p=1\$/);
  assert.ok(first.length <= 255);
  assert.ok(first !== second);
  assert.equal(await verify(password, first), true);
  assert.equal(await verify('incorrect', first), false);
});

test('Argon2id refuse les hashes absents, mal formés ou incompatibles', async () => {
  const { hash, verify } = await createArgon2PasswordService();
  const password = 'valeur de test';
  const encoded = await hash(password);
  for (const candidate of [undefined, 'invalide', encoded.replace('argon2id', 'argon2i'), encoded.replace('19456', '999999999')]) {
    assert.equal(await verify(password, candidate), false);
  }
});

test('la longueur maximale des mots de passe compte les points de code Unicode', async () => {
  const { hash, verify } = await createArgon2PasswordService();
  const password = 'é'.repeat(128) + '🙂'.repeat(128);
  assert.equal(await verify(password, await hash(password)), true);
  await assert.rejects(hash(`${password}a`), RangeError);
  await assert.rejects(hash('🙂'.repeat(7)), RangeError);
  assert.throws(() => validateLogin({ email: 'compte@edu.uiz.ac.ma', password: `${password}a` }), { code: 'INVALID_REQUEST' });
  assert.throws(() => validatePasswordChange({ currentPassword: 'ancien', newPassword: `${password}a` }), { code: 'PASSWORD_POLICY' });
});

test('l’adresse normalisée est en minuscules et le mot de passe reste inchangé', () => {
  assert.deepEqual(validateLogin({ email: ' Compte.Test@EDU.UIZ.AC.MA ', password: ' exemple ' }), {
    email: 'compte.test@edu.uiz.ac.ma', password: ' exemple ',
  });
  assert.throws(() => validateLogin({ email: 'compte@evil.edu.uiz.ac.ma', password: 'exemple' }), { code: 'INVALID_REQUEST' });
});

test('le dépôt paramètre les deux lectures et compare le hash précédent dans la mise à jour', async () => {
  const calls = [];
  const user = { id_utilisateur: 18, role: 'admin' };
  let updated = true;
  const repository = createPostgresAuthRepository({
    async query(text, values) {
      calls.push({ text, values });
      return { rows: values[0] === 18 ? [user] : [], rowCount: updated ? 1 : 0 };
    },
  });
  const email = "nom.d'essai@edu.uiz.ac.ma";
  assert.equal(await repository.findByEmail(email), null);
  assert.equal(await repository.findById(18), user);
  const change = { userId: 18, expectedHash: 'avant', newHash: 'après' };
  assert.equal(await repository.updatePassword(change), true);
  updated = false;
  assert.equal(await repository.updatePassword(change), false);
  assert.match(calls[0].text, /FROM public\.utilisateur WHERE email = \$1$/);
  assert.equal(calls[0].text.includes(email), false);
  assert.deepEqual(calls[0].values, [email]);
  assert.match(calls[1].text, /WHERE id_utilisateur = \$1$/);
  assert.deepEqual(calls[1].values, [18]);
  assert.match(calls[2].text, /SET mot_de_passe = \$3 WHERE id_utilisateur = \$1 AND mot_de_passe = \$2$/);
  assert.deepEqual(calls[2].values, [18, 'avant', 'après']);
});

test('une erreur du pilote PostgreSQL ne traverse pas le dépôt', async () => {
  const repository = createPostgresAuthRepository({
    async query() { throw new Error('mot-de-passe-et-message-interne'); },
  });
  await assert.rejects(repository.findById(18), (error) => (
    error instanceof AuthRepositoryUnavailableError
    && error.message === 'Le stockage PostgreSQL Auth est indisponible.'
    && error.cause === undefined
  ));
});

test('la configuration Auth impose HTTPS pour les origines et les deux fichiers TLS', () => {
  assert.deepEqual(loadAuthConfig({}), { ttlMs: 28800000, webOrigins: [], trustProxyIp: undefined, tls: null });
  assert.deepEqual(loadAuthConfig({
    AUTH_SESSION_TTL_SECONDS: '600', AUTH_WEB_ORIGINS: ' https://localhost:8443/ ',
    TRUST_PROXY_IP: '127.0.0.1', TLS_KEY_FILE: 'local.key', TLS_CERT_FILE: 'local.pem',
  }), {
    ttlMs: 600000, webOrigins: ['https://localhost:8443'], trustProxyIp: '127.0.0.1',
    tls: { keyFile: 'local.key', certFile: 'local.pem' },
  });
  assert.throws(() => loadAuthConfig({ AUTH_SESSION_TTL_SECONDS: '0' }), /AUTH_SESSION_TTL_SECONDS/);
  assert.throws(() => loadAuthConfig({ AUTH_WEB_ORIGINS: 'http://localhost:8443' }), /AUTH_WEB_ORIGINS/);
  assert.throws(() => loadAuthConfig({ TRUST_PROXY_IP: 'true' }), /TRUST_PROXY_IP/);
  assert.throws(() => loadAuthConfig({ TLS_KEY_FILE: 'local.key' }), /TLS_CERT_FILE/);
});
