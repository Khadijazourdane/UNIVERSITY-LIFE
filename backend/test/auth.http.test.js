import assert from 'node:assert/strict';
import { once } from 'node:events';
import { request as httpRequest } from 'node:http';
import { test } from 'node:test';
import express from 'express';

import { createApp } from '../src/app.js';
import { authenticate } from '../src/middleware/authenticate.js';
import { authorize } from '../src/middleware/authorize.js';
import { authErrorHandler } from '../src/middleware/error-handler.js';
import { createPasswordService } from '../src/modules/auth/auth.password.js';
import { AuthRepositoryUnavailableError } from '../src/modules/auth/auth.repository.js';
import { createAuthRouter } from '../src/modules/auth/auth.routes.js';
import { createAuthService } from '../src/modules/auth/auth.service.js';
import { createSessionStore } from '../src/modules/auth/auth.session-store.js';
import { SESSION_COOKIE, sessionCookies } from '../src/modules/auth/auth.transport.js';

const origin = 'https://app.example.test';
const credentials = { email: 'test@edu.uiz.ac.ma', password: 'ancien-test' };
const webHeaders = { Origin: origin, 'X-Session-Transport': 'cookie' };
const nativeHeaders = { 'X-Session-Transport': 'bearer' };
const bearer = (token) => ({ Authorization: `Bearer ${token}` });

async function connect(t, app) {
  const server = app.listen(0, '127.0.0.1');
  t.after(() => new Promise((resolve, reject) => server.close((error) => error ? reject(error) : resolve())));
  await once(server, 'listening');
  const { port } = server.address();

  return (path, { method = 'GET', headers = {}, body, raw, secure = true } = {}) => {
    const payload = raw ?? (body === undefined ? undefined : JSON.stringify(body));
    return new Promise((resolve, reject) => {
      const request = httpRequest({
        host: '127.0.0.1', port, path, method, agent: false,
        headers: {
          ...(secure ? { 'X-Forwarded-Proto': 'https' } : {}),
          ...(payload === undefined ? {} : { 'Content-Type': 'application/json', 'Content-Length': Buffer.byteLength(payload) }),
          ...headers,
        },
      }, async (response) => {
        try {
          response.setEncoding('utf8');
          let text = '';
          for await (const chunk of response) text += chunk;
          const json = response.headers['content-type']?.startsWith('application/json') ? JSON.parse(text) : undefined;
          resolve({ status: response.statusCode, headers: response.headers, text, json });
        } catch (error) {
          reject(error);
        }
      });
      request.on('error', reject);
      request.end(payload);
    });
  };
}

async function fixture(t, { rateLimits, trustProxy = true } = {}) {
  const account = {
    id_utilisateur: 7, nom: 'Utilisateur', prenom: 'Test', email: credentials.email,
    mot_de_passe: `hash:${credentials.password}`, role: 'etudiant',
  };
  const repository = {
    async findByEmail(email) { return email === account.email ? { ...account } : null; },
    async findById(id) { return id === account.id_utilisateur ? { ...account } : null; },
    async updatePassword({ userId, expectedHash, newHash }) {
      if (userId !== account.id_utilisateur || account.mot_de_passe !== expectedHash) return false;
      account.mot_de_passe = newHash;
      return true;
    },
  };
  const passwords = createPasswordService({
    hash: async (value) => `hash:${value}`,
    verify: async (value, hash) => `hash:${value}` === hash,
    dummyHash: 'hash-factice-reserve-au-test',
  });
  const authService = createAuthService({ repository, passwords, sessions: createSessionStore() });
  const app = express();
  if (trustProxy) app.set('trust proxy', 'loopback');
  app.use('/api/auth', createAuthRouter({ authService, webOrigins: [origin], rateLimits }));
  app.get('/protected-test/admin', sessionCookies, authenticate(authService), authorize('admin'),
    (request, response) => response.json({ role: request.auth.user.role }));
  app.use(authErrorHandler);

  const call = await connect(t, app);
  const post = (path, options) => call(`/api/auth/${path}`, { method: 'POST', ...options });
  const login = (headers = nativeHeaders, body = credentials) => post('login', { headers, body });
  const me = (headers) => call('/api/auth/me', { headers });
  return { call, post, login, me, account, repository };
}

function assertError(result, status, code) {
  assert.equal(result.status, status);
  assert.equal(result.json.error.code, code);
  assert.equal(typeof result.json.error.message, 'string');
  assert.deepEqual(Object.keys(result.json.error).sort(), ['code', 'message']);
}

test('login Bearer et me exposent uniquement les champs publics et la durée attendue', async (t) => {
  const { login, me } = await fixture(t);
  const result = await login();
  assert.equal(result.status, 200);
  assert.equal(result.headers['cache-control'], 'no-store');
  assert.equal(result.headers['set-cookie'], undefined);
  const { accessToken, expiresAt, user } = result.json;
  assert.match(accessToken, /^[A-Za-z\d_-]{43}$/);
  assert.ok(Date.parse(expiresAt) > Date.now());
  assert.deepEqual(user, { id_utilisateur: 7, nom: 'Utilisateur', prenom: 'Test', email: credentials.email, role: 'etudiant' });
  assert.equal(result.text.includes(credentials.password), false);
  const profile = await me(bearer(accessToken));
  assert.equal(profile.status, 200);
  assert.deepEqual(profile.json, { user, expiresAt });
  assert.equal(profile.headers['cache-control'], 'no-store');
});

test('le login rend indiscernables compte absent, mot de passe erroné et rôle inconnu', async (t) => {
  const { login, account } = await fixture(t);
  const wrong = await login(nativeHeaders, { ...credentials, password: 'incorrect' });
  const missing = await login(nativeHeaders, { ...credentials, email: 'absent@edu.uiz.ac.ma' });
  account.role = 'administrator';
  const unknown = await login();
  assertError(wrong, 401, 'INVALID_CREDENTIALS');
  assert.deepEqual(wrong.json, missing.json);
  assert.deepEqual(wrong.json, unknown.json);
  assert.equal(wrong.headers['set-cookie'], undefined);
});

test('le cookie Web est Secure et HttpOnly, tourne au login et est effacé au logout idempotent', async (t) => {
  const { login, me, post } = await fixture(t);
  const first = await login(webHeaders);
  assert.equal(first.status, 200);
  assert.deepEqual(Object.keys(first.json).sort(), ['expiresAt', 'user']);
  assert.equal(first.headers['access-control-allow-origin'], origin);
  assert.equal(first.headers['access-control-allow-credentials'], 'true');
  const [setCookie] = first.headers['set-cookie'];
  const [cookie] = setCookie.split(';');
  assert.match(cookie, new RegExp(`^${SESSION_COOKIE}=[A-Za-z0-9_-]{43}$`));
  for (const attribute of ['Path=/', 'HttpOnly', 'Secure', 'SameSite=Lax']) {
    assert.ok(setCookie.split('; ').includes(attribute));
  }
  assert.doesNotMatch(setCookie, /Domain=/i);
  assert.equal(first.text.includes(cookie.split('=')[1]), false);
  assert.equal((await me({ Cookie: cookie })).status, 200);

  const second = await login({ ...webHeaders, Cookie: cookie });
  assert.equal(second.status, 200);
  const [rotatedCookie] = second.headers['set-cookie'][0].split(';');
  assert.notEqual(rotatedCookie, cookie);
  assertError(await me({ Cookie: cookie }), 401, 'SESSION_INVALID');
  for (const headers of [{ ...webHeaders, Cookie: rotatedCookie }, webHeaders]) {
    const logout = await post('logout', { headers });
    assert.equal(logout.status, 204);
    assert.equal(logout.text, '');
    assert.match(logout.headers['set-cookie'][0], /Expires=Thu, 01 Jan 1970/);
  }
  assertError(await me({ Cookie: rotatedCookie }), 401, 'SESSION_INVALID');
});

test('une terminaison TLS fiable est requise et un proxy non approuvé ne peut pas déclarer HTTPS', async (t) => {
  const { call } = await fixture(t, { trustProxy: false });
  for (const secure of [false, true]) {
    const result = await call('/api/auth/login', { method: 'POST', headers: webHeaders, body: credentials, secure });
    assertError(result, 403, 'HTTPS_REQUIRED');
    assert.equal(result.headers['set-cookie'], undefined);
  }
});

test('les POST Web bloquent les origines interdites, les formulaires et le contournement via Bearer', async (t) => {
  const { login, post, me } = await fixture(t);
  const nativeLogin = await login();
  const token = nativeLogin.json.accessToken;
  const webLogin = await login(webHeaders);
  const [cookie] = webLogin.headers['set-cookie'][0].split(';');

  assertError(await login({ ...webHeaders, Origin: 'https://blocked.example.test' }), 403, 'ORIGIN_FORBIDDEN');
  assertError(await login({ 'X-Session-Transport': 'cookie' }), 403, 'ORIGIN_FORBIDDEN');
  assertError(await post('login', { headers: { Origin: origin, 'Content-Type': 'application/x-www-form-urlencoded' }, raw: 'email=test' }), 400, 'INVALID_SESSION_TRANSPORT');

  for (const signals of [{ Origin: origin }, { Origin: 'null' }, { 'Sec-Fetch-Site': 'same-origin' }]) {
    assertError(await login({ ...nativeHeaders, ...signals }), 403, 'ORIGIN_FORBIDDEN');
    assertError(await post('logout', { headers: { ...nativeHeaders, ...signals, ...bearer(token) } }), 403, 'ORIGIN_FORBIDDEN');
  }
  assertError(await post('change-password', {
    headers: { ...nativeHeaders, Origin: origin, Cookie: cookie },
    body: { currentPassword: credentials.password, newPassword: 'autre-password' },
  }), 403, 'ORIGIN_FORBIDDEN');
  assertError(await me({ ...bearer(token), 'Sec-Fetch-Mode': 'cors' }), 403, 'ORIGIN_FORBIDDEN');
  assertError(await me({ ...bearer(token), Cookie: cookie }), 400, 'INVALID_SESSION_TRANSPORT');
  assert.equal((await me({ Cookie: cookie })).status, 200);
  assert.equal((await me(bearer(token))).status, 200);
});

test('les préflight CORS du Web n’autorisent que l’origine et les en-têtes prévus', async (t) => {
  const { call } = await fixture(t);
  const preflight = (requestOrigin) => call('/api/auth/login', {
    method: 'OPTIONS',
    headers: {
      Origin: requestOrigin, 'Access-Control-Request-Method': 'POST',
      'Access-Control-Request-Headers': 'content-type,x-session-transport,authorization',
    },
  });
  const allowed = await preflight(origin);
  assert.equal(allowed.status, 204);
  assert.equal(allowed.headers['access-control-allow-origin'], origin);
  assert.equal(allowed.headers['access-control-allow-credentials'], 'true');
  assert.equal(allowed.headers['access-control-allow-headers'].toLowerCase(), 'content-type,x-session-transport');
  assert.equal((await preflight('https://blocked.example.test')).headers['access-control-allow-origin'], undefined);
});

test('authenticate et authorize distinguent session invalide, rôle interdit et rôle accepté', async (t) => {
  const { login, call, account } = await fixture(t);
  const path = '/protected-test/admin';
  assertError(await call(path), 401, 'SESSION_INVALID');
  const { accessToken } = (await login()).json;
  assertError(await call(path, { headers: bearer(accessToken) }), 403, 'ROLE_FORBIDDEN');
  account.role = 'admin';
  assertError(await call(path, { headers: bearer(accessToken) }), 401, 'SESSION_INVALID');
  const current = (await login()).json.accessToken;
  const allowed = await call(path, { headers: bearer(current) });
  assert.equal(allowed.status, 200);
  assert.deepEqual(allowed.json, { role: 'admin' });
  assert.throws(() => authorize('administrator'), TypeError);
});

test('change-password efface le cookie Web et invalide aussi les sessions Android du compte', async (t) => {
  const { login, post, me } = await fixture(t);
  const { accessToken } = (await login()).json;
  const [cookie] = (await login(webHeaders)).headers['set-cookie'][0].split(';');
  const headers = { ...webHeaders, Cookie: cookie };
  const result = await post('change-password', {
    headers, body: { currentPassword: credentials.password, newPassword: 'nouveau-test' },
  });
  assert.equal(result.status, 204);
  assert.match(result.headers['set-cookie'][0], /Expires=Thu, 01 Jan 1970/);
  assertError(await me(bearer(accessToken)), 401, 'SESSION_INVALID');
  assertError(await me({ Cookie: cookie }), 401, 'SESSION_INVALID');
});

test('change-password distingue un mot de passe actuel incorrect et un conflit de mise à jour', async (t) => {
  const { login, post, repository } = await fixture(t);
  const token = (await login()).json.accessToken;
  const headers = { ...nativeHeaders, ...bearer(token) };
  const body = { currentPassword: credentials.password, newPassword: 'nouveau-test' };
  assertError(await post('change-password', { headers, body: { ...body, currentPassword: 'incorrect' } }), 422, 'CURRENT_PASSWORD_INVALID');
  repository.updatePassword = async () => false;
  assertError(await post('change-password', { headers, body }), 409, 'PASSWORD_UPDATE_CONFLICT');
});

test('logout Bearer révoque seulement la session présentée', async (t) => {
  const { login, post, me } = await fixture(t);
  const token = (await login()).json.accessToken;
  const otherToken = (await login()).json.accessToken;
  const logout = await post('logout', { headers: { ...nativeHeaders, ...bearer(token) } });
  assert.equal(logout.status, 204);
  assert.equal(logout.headers['set-cookie'], undefined);
  assertError(await me(bearer(token)), 401, 'SESSION_INVALID');
  assert.equal((await me(bearer(otherToken))).status, 200);
});

test('le login et le changement de mot de passe appliquent leurs limites avec Retry-After', async (t) => {
  const { login, post } = await fixture(t, {
    rateLimits: { loginIpLimit: 5, loginIdentityLimit: 2, passwordChangeLimit: 1 },
  });
  const session = await login();
  const bad = await login(nativeHeaders, { ...credentials, password: 'incorrect' });
  assertError(bad, 401, 'INVALID_CREDENTIALS');
  const identityLimit = await login(nativeHeaders, { ...credentials, email: credentials.email.toUpperCase() });
  assertError(identityLimit, 429, 'RATE_LIMITED');
  assert.ok(Number(identityLimit.headers['retry-after']) > 0);
  for (const email of ['other@edu.uiz.ac.ma', 'third@edu.uiz.ac.ma']) {
    assertError(await login(nativeHeaders, { ...credentials, email }), 401, 'INVALID_CREDENTIALS');
  }
  assertError(await login(nativeHeaders, { ...credentials, email: 'fourth@edu.uiz.ac.ma' }), 429, 'RATE_LIMITED');

  const request = {
    headers: { ...nativeHeaders, ...bearer(session.json.accessToken) },
    body: { currentPassword: 'incorrect', newPassword: 'nouveau-test' },
  };
  assertError(await post('change-password', { ...request, body: { ...request.body, newPassword: 'court' } }), 422, 'PASSWORD_POLICY');
  assertError(await post('change-password', request), 429, 'RATE_LIMITED');
});

test('les erreurs JSON, médias, stockage et erreurs inattendues ne divulguent pas de secrets', async (t) => {
  const { login, post, repository } = await fixture(t);
  assertError(await login(nativeHeaders, { ...credentials, role: 'admin' }), 400, 'INVALID_REQUEST');
  assertError(await login(nativeHeaders, { ...credentials, email: 'test@fake.edu.uiz.ac.ma' }), 400, 'INVALID_REQUEST');
  assertError(await post('login', { headers: nativeHeaders, raw: '{"password":"marqueur-test",' }), 400, 'INVALID_REQUEST');
  assertError(await post('login', { headers: nativeHeaders, raw: ' '.repeat(105 * 1024) }), 413, 'PAYLOAD_TOO_LARGE');
  assertError(await post('login', { headers: { ...nativeHeaders, 'Content-Type': 'text/plain' }, raw: 'marqueur-test' }), 415, 'UNSUPPORTED_MEDIA_TYPE');
  assertError(await post('login', { headers: { ...nativeHeaders, 'Content-Type': 'application/json; charset=iso-8859-1' }, raw: '{}' }), 415, 'UNSUPPORTED_MEDIA_TYPE');

  repository.findByEmail = async () => { throw new AuthRepositoryUnavailableError('marqueur-test'); };
  const unavailable = await login();
  assertError(unavailable, 503, 'AUTH_UNAVAILABLE');
  assert.equal(unavailable.text.includes('marqueur-test'), false);

  const log = t.mock.method(console, 'error', () => {});
  repository.findByEmail = async () => { throw new Error('marqueur-test'); };
  const unexpected = await login();
  assertError(unexpected, 500, 'INTERNAL_ERROR');
  assert.equal(unexpected.text.includes('marqueur-test'), false);
  assert.deepEqual(log.mock.calls[0].arguments, ['Erreur interne du module Auth.']);
});

test('le serveur sans PostgreSQL garde health et expose un 503 Auth explicite', async (t) => {
  const call = await connect(t, createApp());
  assert.equal((await call('/health', { secure: false })).status, 200);
  for (const [method, path] of [['POST', 'login'], ['GET', 'me'], ['POST', 'change-password'], ['POST', 'logout']]) {
    assertError(await call(`/api/auth/${path}`, { method, secure: false }), 503, 'AUTH_UNAVAILABLE');
  }
  assert.equal((await call('/api/auth/introuvable')).status, 404);
});
