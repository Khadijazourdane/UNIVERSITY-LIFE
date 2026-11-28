import assert from 'node:assert/strict';
import { spawn } from 'node:child_process';
import { once } from 'node:events';
import { readFile } from 'node:fs/promises';
import { request as requestHttp } from 'node:http';
import { request as requestHttps } from 'node:https';
import { createServer } from 'node:net';
import { randomBytes } from 'node:crypto';
import { after, test } from 'node:test';
import { fileURLToPath } from 'node:url';

import { fixtureAccounts, isLocalPostgres, TEST_DATABASE, TEST_ROLE } from './auth-fixture.js';
import { loadPostgresConfig } from '../src/config/env.js';
import { createPool } from '../src/db/pool.js';
import { createArgon2PasswordService } from '../src/modules/auth/auth.password.js';
import { createPostgresAuthRepository } from '../src/modules/auth/auth.repository.js';

const config = loadPostgresConfig();
if (!isLocalPostgres(config) || config.database !== TEST_DATABASE || config.user !== TEST_ROLE) {
  throw new Error('Ces tests utilisent uniquement la base Auth locale et son rôle applicatif dédié.');
}
const accounts = fixtureAccounts(process.env);
const [student] = accounts;
const passwords = await createArgon2PasswordService();
const pool = createPool(config);
const repository = createPostgresAuthRepository(pool);
after(() => pool.end());

const host = '127.0.0.1';

async function freePort() {
  const reservation = createServer().listen(0, host);
  await once(reservation, 'listening');
  const { port } = reservation.address();
  await new Promise((resolve, reject) => reservation.close((error) => error ? reject(error) : resolve()));
  return port;
}

async function startServer(t, overrides = {}) {
  const port = await freePort();
  const cert = process.env.TLS_CERT_FILE ? await readFile(process.env.TLS_CERT_FILE) : undefined;
  const origin = `https://${host}:${port}`;
  const child = spawn(process.execPath, [fileURLToPath(new URL('../src/server.js', import.meta.url))], {
    env: {
      ...process.env,
      HOST: host, PORT: String(port), TRUST_PROXY_IP: cert ? '' : host,
      AUTH_SESSION_TTL_SECONDS: '28800', AUTH_WEB_ORIGINS: origin,
      ...overrides,
    },
    windowsHide: true,
    stdio: ['ignore', 'pipe', 'ignore'],
  });
  t.after(async () => {
    if (child.exitCode !== null || child.signalCode !== null) return;
    const exited = once(child, 'close');
    child.kill();
    await exited;
  });
  await new Promise((resolve, reject) => {
    const timeout = setTimeout(() => reject(new Error('Le serveur Auth de test ne répond pas.')), 7000);
    child.once('close', () => {
      clearTimeout(timeout);
      reject(new Error('Le serveur Auth de test a quitté avant son démarrage.'));
    });
    child.once('error', () => {
      clearTimeout(timeout);
      reject(new Error('Le serveur Auth de test n’a pas pu démarrer.'));
    });
    child.stdout.setEncoding('utf8').on('data', (chunk) => {
      if (/Serveur HTTPS? démarré/.test(chunk)) {
        clearTimeout(timeout);
        resolve();
      }
    });
  });

  const call = (path, { method = 'GET', headers, body } = {}) => new Promise((resolve, reject) => {
    const send = cert ? requestHttps : requestHttp;
    const payload = body && JSON.stringify(body);
    const request = send({
      hostname: host, port, path, method, agent: false, ca: cert,
      headers: {
        ...(cert ? {} : { 'X-Forwarded-Proto': 'https' }),
        ...(payload ? { 'Content-Type': 'application/json' } : {}),
        ...headers,
      },
    }, async (response) => {
      try {
        response.setEncoding('utf8');
        let text = '';
        for await (const chunk of response) text += chunk;
        resolve({ status: response.statusCode, headers: response.headers, json: text ? JSON.parse(text) : null });
      } catch (error) {
        reject(error);
      }
    });
    request.setTimeout(7000, () => request.destroy(new Error('Délai HTTP de test dépassé.')));
    request.on('error', reject);
    request.end(payload);
  });
  return { call, origin };
}

test('les trois comptes Argon2id sont lisibles avec les seuls droits applicatifs attendus', async () => {
  const { rows: [grants] } = await pool.query(`
    SELECT has_table_privilege('public.utilisateur', 'SELECT') AS can_read,
      has_column_privilege('public.utilisateur', 'mot_de_passe', 'UPDATE') AS can_change_password,
      has_column_privilege('public.utilisateur', 'role', 'UPDATE') AS can_change_role,
      has_table_privilege('public.utilisateur', 'INSERT') AS can_insert,
      has_schema_privilege('public', 'CREATE') AS can_create,
      rolsuper FROM pg_roles WHERE rolname = current_user
  `);
  assert.deepEqual(grants, { can_read: true, can_change_password: true, can_change_role: false, can_insert: false, can_create: false, rolsuper: false });
  for (const account of accounts) {
    const record = await repository.findByEmail(account.email);
    assert.equal(record?.role, account.role);
    assert.equal((await repository.findById(account.id))?.id_utilisateur, account.id);
    assert.equal(await passwords.verify(account.password, record.mot_de_passe), true);
  }
  assert.ok(await repository.findByEmail("absent.d'essai@edu.uiz.ac.ma") === null);
});

test('PostgreSQL applique une seule mise à jour concurrente du même hash', async () => {
  const original = (await repository.findById(student.id)).mot_de_passe;
  const alternatives = await Promise.all([passwords.hash('concurrence-a'), passwords.hash('concurrence-b')]);
  try {
    const results = await Promise.all(alternatives.map((newHash) => repository.updatePassword({ userId: student.id, expectedHash: original, newHash })));
    assert.deepEqual(results.sort(), [false, true]);
    assert.ok(alternatives.includes((await repository.findById(student.id)).mot_de_passe));
  } finally {
    const current = (await repository.findById(student.id)).mot_de_passe;
    if (alternatives.includes(current)) {
      assert.ok(await repository.updatePassword({ userId: student.id, expectedHash: current, newHash: original }));
    }
  }
});

test('le serveur normal utilise PostgreSQL pour les trois rôles et révoque les sessions réelles', async (t) => {
  const { call, origin } = await startServer(t);
  const tls = Boolean(process.env.TLS_CERT_FILE);
  const post = (path, body, headers = {}) => call(`/api/auth/${path}`, {
    method: 'POST', body, headers: { 'X-Session-Transport': 'bearer', ...headers },
  });
  const bearer = (token) => ({ Authorization: `Bearer ${token}` });
  const login = (account, password = account.password) => post('login', { email: account.email.toUpperCase(), password });
  const me = (token) => call('/api/auth/me', { headers: bearer(token) });
  const original = (await repository.findById(student.id)).mot_de_passe;
  const newPassword = randomBytes(24).toString('base64url');
  let studentToken;
  try {
    assert.equal((await call('/health')).status, 200);
    for (const account of accounts) {
      const result = await login(account);
      assert.equal(result.status, 200);
      assert.equal(result.json.user.role, account.role);
      assert.ok(!Object.hasOwn(result.json.user, 'mot_de_passe'));
      assert.equal(result.headers['cache-control'], 'no-store');
      const token = result.json.accessToken;
      assert.ok(typeof token === 'string');
      const identity = await me(token);
      assert.equal(identity.status, 200);
      assert.equal(identity.json.user.id_utilisateur, account.id);
      assert.ok(!Object.hasOwn(identity.json, 'accessToken'));
      if (account === student) {
        studentToken = token;
      } else {
        assert.equal((await post('logout', undefined, bearer(token))).status, 204);
        assert.equal((await me(token)).status, 401);
      }
    }
    assert.equal((await login(student, 'mot-de-passe-errone-de-test')).status, 401);
    const concurrentSession = await login(student);
    assert.equal(concurrentSession.status, 200);
    const response = await post('change-password', { currentPassword: student.password, newPassword }, bearer(studentToken));
    assert.equal(response.status, 204);
    assert.equal((await me(studentToken)).status, 401);
    assert.equal((await me(concurrentSession.json.accessToken)).status, 401);
    assert.equal((await login(student)).status, 401);
    assert.equal((await login(student, newPassword)).status, 200);

    const web = { Origin: origin, 'X-Session-Transport': 'cookie' };
    const webLogin = await post('login', { email: student.email, password: newPassword }, web);
    assert.equal(webLogin.status, 200);
    assert.ok(!Object.hasOwn(webLogin.json, 'accessToken'));
    const [setCookie] = webLogin.headers['set-cookie'];
    assert.ok(setCookie.includes('HttpOnly') && setCookie.includes('Secure'));
    const [cookie] = setCookie.split(';');
    assert.equal((await call('/api/auth/me', { headers: { Cookie: cookie } })).status, 200);
    assert.equal((await post('logout', undefined, { ...web, Cookie: cookie })).status, 204);
    assert.equal((await call('/api/auth/me', { headers: { Cookie: cookie } })).status, 401);
    t.diagnostic(tls ? 'HTTPS direct avec vérification du certificat.' : 'Terminaison HTTPS simulée sur la boucle locale.');
  } finally {
    const current = (await repository.findById(student.id)).mot_de_passe;
    if (await passwords.verify(newPassword, current)) {
      assert.ok(await repository.updatePassword({ userId: student.id, expectedHash: current, newHash: original }));
    }
  }
});

test('le serveur reste joignable sans configuration ou quand PostgreSQL refuse la connexion', async (t) => {
  const unavailablePort = await freePort();
  for (const overrides of [
    { PGDATABASE: '', PGUSER: '', PGPASSWORD: '' },
    { PGHOST: host, PGPORT: String(unavailablePort) },
  ]) {
    const { call } = await startServer(t, overrides);
    assert.equal((await call('/health')).status, 200);
    const result = await call('/api/auth/login', {
      method: 'POST', headers: { 'X-Session-Transport': 'bearer' },
      body: { email: student.email, password: student.password },
    });
    assert.equal(result.status, 503);
    assert.deepEqual(result.json, {
      error: { code: 'AUTH_UNAVAILABLE', message: 'Service d’authentification temporairement indisponible.' },
    });
  }
});
