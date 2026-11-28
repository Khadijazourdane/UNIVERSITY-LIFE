import { createHash, createHmac, pbkdf2Sync, randomBytes } from 'node:crypto';
import { readFile, writeFile } from 'node:fs/promises';

import { AUTH_ROLES, fixtureAccounts, isLocalPostgres, TEST_DATABASE, TEST_ROLE } from '../integration/auth-fixture.js';
import { loadPostgresConfig } from '../src/config/env.js';
import { createPool } from '../src/db/pool.js';
import { createArgon2PasswordService } from '../src/modules/auth/auth.password.js';

// PostgreSQL accepte le vérificateur SCRAM directement dans CREATE ROLE.
function scramVerifier(password) {
  const salt = randomBytes(16);
  const iterations = 4096;
  const salted = pbkdf2Sync(password, salt, iterations, 32, 'sha256');
  const key = (label) => createHmac('sha256', salted).update(label).digest();
  const stored = createHash('sha256').update(key('Client Key')).digest('base64');
  return `SCRAM-SHA-256$${iterations}:${salt.toString('base64')}$${stored}:${key('Server Key').toString('base64')}`;
}

async function setup() {
  const config = loadPostgresConfig();
  if (!isLocalPostgres(config)) {
    throw new Error('Le script requiert une configuration PostgreSQL locale dans .env.');
  }
  const definition = await readFile(new URL('../test/fixtures/auth/schema.sql', import.meta.url), 'utf8');
  const adminPool = createPool({ ...config, database: 'template1' });
  let fixturePool;
  try {
    const { rows: [status] } = await adminPool.query(`
      SELECT rolsuper,
        EXISTS (SELECT FROM pg_database WHERE datname = $1) AS db_exists,
        EXISTS (SELECT FROM pg_roles WHERE rolname = $2) AS role_exists
      FROM pg_roles WHERE rolname = current_user
    `, [TEST_DATABASE, TEST_ROLE]);
    if (!status.rolsuper) throw new Error('Un administrateur PostgreSQL local doit préparer les fixtures.');
    if (status.db_exists || status.role_exists) {
      throw new Error('La base ou le rôle de test existe déjà. Consultez la procédure de réutilisation ou de nettoyage.');
    }

    const env = {
      PGHOST: config.host, PGPORT: config.port, PGDATABASE: TEST_DATABASE, PGUSER: TEST_ROLE,
      PGPASSWORD: randomBytes(32).toString('base64url'),
    };
    for (const role of AUTH_ROLES) {
      const key = `AUTH_TEST_${role.toUpperCase()}`;
      env[`${key}_EMAIL`] = `auth-test-${role}-${randomBytes(6).toString('hex')}@edu.uiz.ac.ma`;
      env[`${key}_PASSWORD`] = randomBytes(24).toString('base64url');
    }
    const credentialsFile = new URL('../.env.auth-test', import.meta.url);
    const dotenv = Object.entries(env).map(([name, value]) => `${name}=${value}`).join('\n');
    await writeFile(credentialsFile, `${dotenv}\n`, { flag: 'wx', mode: 0o600 });

    const admin = await adminPool.connect();
    try {
      // Le vérificateur du rôle ne doit pas figurer dans le journal des instructions.
      await admin.query("SET log_statement = 'none'");
      await admin.query("SET log_min_error_statement = 'panic'");
      await admin.query(`CREATE ROLE ${TEST_ROLE} LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT PASSWORD '${scramVerifier(env.PGPASSWORD)}'`);
      await admin.query(`CREATE DATABASE ${TEST_DATABASE} TEMPLATE template0`);
      await admin.query(`REVOKE ALL ON DATABASE ${TEST_DATABASE} FROM PUBLIC`);
      await admin.query(`GRANT CONNECT ON DATABASE ${TEST_DATABASE} TO ${TEST_ROLE}`);
    } finally {
      admin.release();
    }

    fixturePool = createPool({ ...config, database: TEST_DATABASE });
    const passwords = await createArgon2PasswordService();
    const connection = await fixturePool.connect();
    try {
      await connection.query('BEGIN');
      await connection.query("SET LOCAL log_statement = 'none'");
      await connection.query("SET LOCAL log_min_error_statement = 'panic'");
      await connection.query(definition);
      for (const account of fixtureAccounts(env)) {
        await connection.query(
          'INSERT INTO public.utilisateur (id_utilisateur, nom, prenom, email, mot_de_passe, role) VALUES ($1, $2, $3, $4, $5, $6)',
          [account.id, 'Fixture', 'Auth', account.email, await passwords.hash(account.password), account.role],
        );
      }
      await connection.query('COMMIT');
    } catch (error) {
      await connection.query('ROLLBACK');
      throw error;
    } finally {
      connection.release();
    }
  } finally {
    try {
      await fixturePool?.end();
    } finally {
      await adminPool.end();
    }
  }
}

try {
  await setup();
  console.log('Base Auth isolée, rôle applicatif et trois comptes de test prêts. Identifiants dans .env.auth-test.');
} catch {
  console.error('Préparation Auth interrompue. Vérifiez le compte local, les noms réservés et la présence de .env.auth-test.');
  process.exitCode = 1;
}
