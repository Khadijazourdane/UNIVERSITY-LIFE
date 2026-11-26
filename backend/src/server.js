import { once } from 'node:events';
import { createServer } from 'node:http';

import { createApp } from './app.js';
import { loadConfig } from './config/env.js';
import { createPool } from './db/pool.js';

async function startServer() {
  const { http, corsOrigins, postgres } = loadConfig();
  const server = createServer(createApp({ corsOrigins }));
  const pool = postgres ? createPool(postgres) : null;

  try {
    const listening = once(server, 'listening');
    server.listen(http.port, http.host);
    await listening;
  } catch (error) {
    await pool?.end();
    throw new Error(`Écoute HTTP impossible (${error.code ?? 'erreur inconnue'}).`);
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
  console.log(`Serveur HTTP démarré sur ${http.host}, port ${http.port}.`);
}

startServer().catch((error) => {
  console.error(`Démarrage impossible. ${error.message}`);
  process.exitCode = 1;
});
