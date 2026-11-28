import { loadPostgresConfig } from '../src/config/env.js';
import { createPool } from '../src/db/pool.js';

const failureMessages = new Map([
  ['ECONNREFUSED', 'Connexion PostgreSQL refusée. Vérifiez le service et le port.'],
  ['ENOTFOUND', 'Hôte PostgreSQL introuvable. Vérifiez PGHOST.'],
  ['ETIMEDOUT', 'Délai de connexion PostgreSQL dépassé.'],
  ['28000', 'Authentification PostgreSQL refusée. Vérifiez le rôle et son accès.'],
  ['28P01', 'Authentification PostgreSQL refusée. Vérifiez le rôle et son mot de passe.'],
  ['3D000', 'La base PostgreSQL configurée est introuvable. Vérifiez PGDATABASE.'],
  ['42501', 'Accès PostgreSQL refusé. Vérifiez les droits du rôle.'],
]);

async function queryPostgres(config) {
  const pool = createPool(config);
  try {
    const { rows } = await pool.query('SELECT 1 AS ok');
    return rows[0]?.ok;
  } finally {
    await pool.end();
  }
}

async function checkPostgres() {
  let config;
  try {
    config = loadPostgresConfig();
  } catch (error) {
    console.error(error.message);
    return 1;
  }

  if (!config) {
    console.error('Renseignez PGDATABASE, PGUSER et PGPASSWORD dans backend/.env.');
    return 1;
  }

  let value;
  try {
    value = await queryPostgres(config);
  } catch (error) {
    console.error(failureMessages.get(error?.code) ?? 'Échec du contrôle PostgreSQL. Vérifiez la configuration et la disponibilité du serveur.');
    return 1;
  }

  if (value !== 1) {
    console.error('La requête de vérification PostgreSQL a renvoyé un résultat inattendu.');
    return 1;
  }

  console.log('Connexion PostgreSQL vérifiée. SELECT 1 a renvoyé 1 et le pool est fermé.');
  return 0;
}

process.exitCode = await checkPostgres();
