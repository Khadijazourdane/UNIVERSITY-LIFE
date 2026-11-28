import { isBrowserRequest, readSessionCredential } from '../modules/auth/auth.transport.js';
import { AuthError } from './error-handler.js';

export function protectSessionWrites(webOrigins) {
  if (webOrigins.some((origin) => typeof origin !== 'string' || !origin.startsWith('https://')
      || origin.includes('*') || URL.parse(origin)?.origin !== origin)) {
    throw new TypeError('Les origines Web Auth doivent être des origines HTTPS explicites.');
  }
  const allowedOrigins = new Set(webOrigins);

  return (request, _response, next) => {
    const transport = request.get('X-Session-Transport');
    if (transport !== 'cookie' && transport !== 'bearer') {
      throw new AuthError('INVALID_SESSION_TRANSPORT');
    }
    if (transport === 'cookie' && !allowedOrigins.has(request.get('Origin'))) {
      throw new AuthError('ORIGIN_FORBIDDEN');
    }
    if (transport === 'bearer' && isBrowserRequest(request)) {
      throw new AuthError('ORIGIN_FORBIDDEN');
    }

    const credential = readSessionCredential(request);
    if (credential && credential.transport !== transport) {
      throw new AuthError('INVALID_SESSION_TRANSPORT');
    }
    request.sessionTransport = transport;
    next();
  };
}
