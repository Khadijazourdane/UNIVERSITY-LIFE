import { ipKeyGenerator, rateLimit } from 'express-rate-limit';

import { fingerprint } from '../modules/auth/auth.session-store.js';
import { AuthError } from './error-handler.js';

export function createAuthRateLimits({
  windowMs = 15 * 60 * 1000,
  loginIpLimit = 40,
  loginIdentityLimit = 8,
  passwordChangeLimit = 8,
} = {}) {
  const common = {
    windowMs,
    standardHeaders: 'draft-7',
    legacyHeaders: false,
    handler: (_request, _response, next) => next(new AuthError('RATE_LIMITED')),
  };

  return {
    loginByIp: rateLimit({ ...common, limit: loginIpLimit }),
    loginByIdentity: rateLimit({
      ...common,
      limit: loginIdentityLimit,
      skip: (request) => typeof request.body?.email !== 'string',
      keyGenerator: (request) => `${ipKeyGenerator(request.ip)}:${fingerprint(request.body.email.trim().toLowerCase())}`,
    }),
    changePassword: rateLimit({
      ...common,
      limit: passwordChangeLimit,
      keyGenerator: (request) => String(request.auth.user.id_utilisateur),
    }),
  };
}
