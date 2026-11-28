import { isIP } from 'node:net';

function readPort(value, name) {
  const port = Number(value);
  if (!/^\d+$/.test(value) || port < 1 || port > 65535) {
    throw new Error(`${name} doit être un entier compris entre 1 et 65535.`);
  }
  return port;
}

function readHost(value, name) {
  const host = value.trim();
  if (!host) {
    throw new Error(`${name} doit contenir une adresse ou un nom d’hôte.`);
  }
  return host;
}

function readCorsOrigins(value, name = 'CORS_ORIGINS') {
  const entries = value.split(',').map((entry) => entry.trim()).filter(Boolean);
  return entries.map((entry) => {
    const url = URL.parse(entry);
    if (!url || !/^https?:\/\/[^/?#@%*\s\\]+\/?$/i.test(entry)) {
      throw new Error(`${name} doit contenir des origines HTTP(S) explicites séparées par des virgules.`);
    }
    return url.origin;
  });
}

export function loadPostgresConfig(env = process.env) {
  const credentials = {
    PGDATABASE: env.PGDATABASE?.trim() ?? '',
    PGUSER: env.PGUSER?.trim() ?? '',
    PGPASSWORD: env.PGPASSWORD ?? '',
  };
  const names = Object.keys(credentials);
  const missing = names.filter((name) => !credentials[name]);
  if (missing.length === names.length) {
    return null;
  }
  if (missing.length > 0) {
    throw new Error(`La configuration PostgreSQL requiert ${missing.join(', ')}.`);
  }

  return {
    host: readHost(env.PGHOST ?? 'localhost', 'PGHOST'),
    port: readPort(env.PGPORT ?? '5432', 'PGPORT'),
    database: credentials.PGDATABASE,
    user: credentials.PGUSER,
    password: credentials.PGPASSWORD,
  };
}

export function loadConfig(env = process.env) {
  return {
    http: {
      host: readHost(env.HOST ?? '127.0.0.1', 'HOST'),
      port: readPort(env.PORT ?? '3001', 'PORT'),
    },
    corsOrigins: readCorsOrigins(env.CORS_ORIGINS ?? ''),
    postgres: loadPostgresConfig(env),
  };
}
export function loadAuthConfig(env = process.env) {
  const duration = env.AUTH_SESSION_TTL_SECONDS ?? '28800';
  const ttlSeconds = Number(duration);
  if (!/^\d+$/.test(duration) || ttlSeconds < 1 || ttlSeconds > 2147483647) {
    throw new Error('AUTH_SESSION_TTL_SECONDS doit être un entier entre 1 et 2147483647.');
  }

  const webOrigins = readCorsOrigins(env.AUTH_WEB_ORIGINS ?? '', 'AUTH_WEB_ORIGINS');
  if (webOrigins.some((origin) => !origin.startsWith('https://'))) {
    throw new Error('AUTH_WEB_ORIGINS doit contenir uniquement des origines HTTPS.');
  }

  const trustProxyIp = env.TRUST_PROXY_IP?.trim();
  if (trustProxyIp && !isIP(trustProxyIp)) {
    throw new Error('TRUST_PROXY_IP doit désigner une adresse IP explicite.');
  }

  const keyFile = env.TLS_KEY_FILE?.trim();
  const certFile = env.TLS_CERT_FILE?.trim();
  if (Boolean(keyFile) !== Boolean(certFile)) {
    throw new Error('TLS_KEY_FILE et TLS_CERT_FILE doivent être renseignées ensemble.');
  }

  return {
    ttlMs: ttlSeconds * 1000,
    webOrigins,
    trustProxyIp: trustProxyIp || undefined,
    tls: keyFile ? { keyFile, certFile } : null,
  };
}
