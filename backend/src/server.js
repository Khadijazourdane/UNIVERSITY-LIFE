import { once } from 'node:events';
import { readFile } from 'node:fs/promises';
import { createServer } from 'node:http';
import { createServer as createHttpsServer } from 'node:https';

import { createApp } from './app.js';
import { loadAuthConfig, loadConfig } from './config/env.js';
import { createPool } from './db/pool.js';
import { createArgon2PasswordService } from './modules/auth/auth.password.js';
import { createPostgresAuthRepository } from './modules/auth/auth.repository.js';
import { createAuthService } from './modules/auth/auth.service.js';
import { createSessionStore } from './modules/auth/auth.session-store.js';

async function createListener(app, tls) {
  if (!tls) return createServer(app);
  try {
    const [key, cert] = await Promise.all([readFile(tls.keyFile), readFile(tls.certFile)]);
    return createHttpsServer({ key, cert }, app);
  } catch {
    throw new Error('Le certificat et la clé TLS doivent être valides et lisibles.');
  }
}

async function startServer() {
  const { http, corsOrigins, postgres } = loadConfig();
  const { ttlMs, webOrigins, trustProxyIp, tls } = loadAuthConfig();
  const pool = postgres ? createPool(postgres) : null;
  let server;

  try {
    const authService = pool ? createAuthService({
      repository: createPostgresAuthRepository(pool),
      passwords: await createArgon2PasswordService(),
      sessions: createSessionStore({ ttlMs }),
    }) : undefined;
    server = await createListener(createApp({ corsOrigins, webOrigins, authService, trustProxyIp }), tls);
    try {
      const listening = once(server, 'listening');
      server.listen(http.port, http.host);
      await listening;
    } catch (error) {
      throw new Error(`Écoute impossible (${error.code ?? 'erreur inconnue'}).`);
    }
  } catch (error) {
    await pool?.end();
    throw error;
  }

  let stopping = false;
  async function stopServer() {
    if (stopping) {
      return;
    }
    stopping = true;

    try {
      const closed = once(server, 'close');
      server.close();
      await closed;
    } finally {
      await pool?.end();
    }
  }

  function handleStopSignal() {
    stopServer().catch(() => {
      console.error('Impossible de terminer proprement le backend.');
      process.exitCode = 1;
    });
  }

  process.on('SIGINT', handleStopSignal);
  process.on('SIGTERM', handleStopSignal);
  console.log(`Serveur ${tls ? 'HTTPS' : 'HTTP'} démarré sur ${http.host}, port ${http.port}.`);
}

startServer().catch((error) => {
  console.error(`Démarrage impossible. ${error.message}`);
  process.exitCode = 1;
});
