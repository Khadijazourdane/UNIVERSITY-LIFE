import assert from 'node:assert/strict';
import { once } from 'node:events';
import { after, before, test } from 'node:test';

import { createApp } from '../src/app.js';
import { loadConfig } from '../src/config/env.js';
import { createPool } from '../src/db/pool.js';
import { errorHandler } from '../src/middleware/error-handler.js';

const allowedOrigin = 'http://localhost:8080';
let server;
let baseUrl;

before(async () => {
  const { corsOrigins } = loadConfig({ CORS_ORIGINS: allowedOrigin });
  server = createApp({ corsOrigins }).listen(0, '127.0.0.1');
  await once(server, 'listening');
  baseUrl = `http://127.0.0.1:${server.address().port}`;
});

after(async () => {
  if (server?.listening) {
    const closed = once(server, 'close');
    server.close();
    await closed;
  }
});

test('GET /health répond en JSON sans PostgreSQL et applique Helmet', async () => {
  const response = await fetch(`${baseUrl}/health`);
  assert.equal(response.status, 200);
  assert.match(response.headers.get('content-type'), /^application\/json\b/);
  assert.equal(response.headers.get('x-content-type-options'), 'nosniff');
  assert.deepEqual(await response.json(), { status: 'ok' });
});

test('un chemin inconnu renvoie un 404 JSON', async () => {
  const response = await fetch(`${baseUrl}/introuvable`);
  assert.equal(response.status, 404);
  assert.deepEqual(await response.json(), { error: 'Route introuvable' });
});

test('un corps JSON mal formé renvoie un 400 sans reprendre le contenu envoyé', async () => {
  const response = await fetch(`${baseUrl}/health`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: '{"marker":"test-only",',
  });
  assert.equal(response.status, 400);
  assert.deepEqual(await response.json(), { error: 'Corps JSON invalide' });
});

test('un corps JSON dépassant la limite renvoie un 413', async () => {
  const response = await fetch(`${baseUrl}/health`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ value: 'x'.repeat(100 * 1024) }),
  });
  assert.equal(response.status, 413);
  assert.deepEqual(await response.json(), { error: 'Corps JSON trop volumineux' });
});

test('un jeu de caractères JSON non pris en charge renvoie un 415', async () => {
  const response = await fetch(`${baseUrl}/health`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=iso-8859-1' },
    body: '{}',
  });
  assert.equal(response.status, 415);
  assert.deepEqual(await response.json(), { error: 'Jeu de caractères non pris en charge' });
});

test('une erreur inattendue produit une réponse et un journal génériques', (context) => {
  const log = context.mock.method(console, 'error', () => {});
  const response = {
    status(code) {
      assert.equal(code, 500);
      return this;
    },
    json(body) {
      return body;
    },
  };
  const body = errorHandler(new Error('test-only'), {}, response, assert.fail);
  assert.deepEqual(body, { error: 'Erreur interne du serveur' });
  assert.equal(log.mock.callCount(), 1);
  assert.deepEqual(log.mock.calls[0].arguments, ['Erreur HTTP interne.']);
});

test('une réponse commencée transmet uniquement une erreur générique à Express', () => {
  const next = (error) => assert.equal(error.message, 'La réponse HTTP a été interrompue.');
  errorHandler(new Error('test-only'), {}, { headersSent: true }, next);
});

test('CORS ajoute son en-tête uniquement pour une origine autorisée', async () => {
  const allowed = await fetch(`${baseUrl}/health`, { headers: { Origin: allowedOrigin } });
  assert.equal(allowed.headers.get('access-control-allow-origin'), allowedOrigin);
  await allowed.json();

  const other = await fetch(`${baseUrl}/health`, {
    headers: { Origin: 'https://unauthorized.example.test' },
  });
  assert.equal(other.headers.get('access-control-allow-origin'), null);
  await other.json();
});

test('la configuration HTTP par défaut fonctionne sans variables PostgreSQL', () => {
  assert.deepEqual(loadConfig({}), {
    http: { host: '127.0.0.1', port: 3001 },
    corsOrigins: [],
    postgres: null,
  });
  const explicit = loadConfig({
    HOST: 'localhost',
    PORT: '3002',
    PGHOST: 'localhost',
    PGPORT: '5432',
    PGDATABASE: '',
    PGUSER: '',
    PGPASSWORD: '',
  });
  assert.deepEqual(explicit.http, { host: 'localhost', port: 3002 });
  assert.equal(explicit.postgres, null);
});

test('un hôte HTTP vide et les ports HTTP invalides sont rejetés', () => {
  assert.throws(() => loadConfig({ HOST: ' ' }), /HOST/);
  for (const value of ['', '0', '65536', '3000.5', '3e3', 'abc']) {
    assert.throws(() => loadConfig({ PORT: value }), /PORT/);
  }
});

test('CORS valide et normalise les origines configurées', () => {
  const { corsOrigins } = loadConfig({ CORS_ORIGINS: ' http://localhost:8080, https://example.test:443/ ' });
  assert.deepEqual(corsOrigins, [allowedOrigin, 'https://example.test']);
  const invalidOrigins = [
    '*',
    'null',
    'https://*.example.test',
    'https://%2a.example.test',
    'ftp://example.test',
    'http://[',
    'https://example.test/path',
    'https://user@example.test',
    'https://example.test?query=yes',
  ];
  for (const origin of invalidOrigins) {
    assert.throws(() => loadConfig({ CORS_ORIGINS: origin }), /CORS_ORIGINS/);
  }
});

test('une configuration PostgreSQL partielle indique les variables manquantes', () => {
  assert.throws(
    () => loadConfig({ PGPASSWORD: 'test-only' }),
    { message: 'La configuration PostgreSQL requiert PGDATABASE, PGUSER.' },
  );
});

test('une configuration PostgreSQL complète prépare un pool sans connexion', async () => {
  const env = { PGDATABASE: 'database_test', PGUSER: 'user_test', PGPASSWORD: ' test-only ' };
  const { postgres } = loadConfig(env);
  assert.deepEqual(postgres, {
    host: 'localhost',
    port: 5432,
    database: 'database_test',
    user: 'user_test',
    password: ' test-only ',
  });
  assert.throws(() => loadConfig({ ...env, PGPORT: '65536' }), /PGPORT/);
  assert.throws(() => loadConfig({ ...env, PGHOST: ' ' }), /PGHOST/);

  const pool = createPool(postgres);
  try {
    assert.equal(pool.totalCount, 0);
  } finally {
    await pool.end();
  }
});
