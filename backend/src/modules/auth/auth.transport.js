import cookieParser from 'cookie-parser';

import { AuthError } from '../../middleware/error-handler.js';

export const SESSION_COOKIE = '__Host-ul_session';
export const sessionCookies = cookieParser();

const cookieOptions = { httpOnly: true, secure: true, sameSite: 'lax', path: '/' };

export function isBrowserRequest(request) {
  return ['Origin', 'Sec-Fetch-Site', 'Sec-Fetch-Mode', 'Sec-Fetch-Dest']
    .some((header) => request.get(header) !== undefined);
}

export function assertAuthHttps(request) {
  if (!request.secure) {
    throw new AuthError('HTTPS_REQUIRED');
  }
}

export function readSessionCredential(request) {
  const authorization = request.get('Authorization');
  const cookie = request.cookies?.[SESSION_COOKIE];
  if (authorization !== undefined && cookie !== undefined) {
    throw new AuthError('INVALID_SESSION_TRANSPORT');
  }
  if (authorization !== undefined) {
    if (isBrowserRequest(request)) {
      throw new AuthError('ORIGIN_FORBIDDEN');
    }
    return { transport: 'bearer', token: /^Bearer ([^\s,]+)$/i.exec(authorization)?.[1] };
  }
  if (cookie !== undefined) {
    return { transport: 'cookie', token: typeof cookie === 'string' ? cookie : undefined };
  }
  return undefined;
}

export function setSessionCookie(response, token, expiresAt) {
  response.cookie(SESSION_COOKIE, token, { ...cookieOptions, expires: new Date(expiresAt) });
}

export function clearSessionCookie(response) {
  response.clearCookie(SESSION_COOKIE, cookieOptions);
}
