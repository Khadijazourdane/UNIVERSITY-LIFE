import { Pool } from 'pg';

export function createPool(config) {
  const pool = new Pool({
    ...config,
    max: 10,
    connectionTimeoutMillis: 3000,
    idleTimeoutMillis: 10000,
    statement_timeout: 5000,
    query_timeout: 6000,
  });

  pool.on('error', () => {
    console.error('Une connexion inactive du pool PostgreSQL a échoué.');
  });

  return pool;
}
