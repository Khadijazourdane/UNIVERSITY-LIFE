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

function readCorsOrigins(value) {
  const entries = value.split(',').map((entry) => entry.trim()).filter(Boolean);
  return entries.map((entry) => {
    const url = URL.parse(entry);
    if (!url || !/^https?:\/\/[^/?#@%*\s\\]+\/?$/i.test(entry)) {
      throw new Error('CORS_ORIGINS doit contenir des origines HTTP(S) explicites séparées par des virgules.');
    }
    return url.origin;
  });
}

function readPostgres(env) {
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
    postgres: readPostgres(env),
  };
}
