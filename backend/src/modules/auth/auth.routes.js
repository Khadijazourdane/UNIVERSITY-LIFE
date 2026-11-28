import cors from 'cors';
import express from 'express';

import { createAuthRateLimits } from '../../middleware/auth-rate-limit.js';
import { authenticate } from '../../middleware/authenticate.js';
import { protectSessionWrites } from '../../middleware/csrf-protection.js';
import { AuthError, authErrorHandler } from '../../middleware/error-handler.js';
import { createAuthController } from './auth.controller.js';
import { assertAuthHttps, sessionCookies } from './auth.transport.js';

function requireJson(request, _response, next) {
  const type = request.get('Content-Type')?.split(';', 1)[0].trim().toLowerCase();
  if (type !== 'application/json') {
    throw new AuthError('UNSUPPORTED_MEDIA_TYPE');
  }
  next();
}

export function createAuthRouter({ authService, webOrigins = [], rateLimits } = {}) {
  const router = express.Router();
  const controller = createAuthController(authService);
  const requireSession = authenticate(authService);
  const protectWrite = protectSessionWrites(webOrigins);
  const limit = createAuthRateLimits(rateLimits);
  const parseJson = express.json({ limit: '100kb' });

  router.use((_request, response, next) => {
    response.set('Cache-Control', 'no-store');
    next();
  });
  router.use(cors({
    origin: webOrigins,
    credentials: true,
    methods: ['GET', 'POST'],
    allowedHeaders: ['Content-Type', 'X-Session-Transport'],
    exposedHeaders: ['Retry-After'],
  }));
  function requireAvailableOverHttps(request, _response, next) {
    if (!authService) throw new AuthError('AUTH_UNAVAILABLE');
    assertAuthHttps(request);
    next();
  }
  router.use(sessionCookies);

  router.post('/login', requireAvailableOverHttps, protectWrite, limit.loginByIp, requireJson, parseJson, limit.loginByIdentity, controller.login);
  router.get('/me', requireAvailableOverHttps, requireSession, controller.me);
  router.post('/change-password', requireAvailableOverHttps, protectWrite, requireSession, limit.changePassword, requireJson, parseJson, controller.changePassword);
  router.post('/logout', requireAvailableOverHttps, protectWrite, controller.logout);
  router.use(authErrorHandler);
  return router;
}
