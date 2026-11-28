import { clearSessionCookie, readSessionCredential, setSessionCookie } from './auth.transport.js';

export function createAuthController(authService) {
  return {
    async login(request, response) {
      const previousToken = readSessionCredential(request)?.token;
      const { user, expiresAt, token } = await authService.login(request.body, previousToken);
      const session = { user, expiresAt: new Date(expiresAt).toISOString() };
      if (request.sessionTransport === 'cookie') {
        setSessionCookie(response, token, expiresAt);
        return response.status(200).json(session);
      }
      return response.status(200).json({ ...session, accessToken: token });
    },

    me(request, response) {
      const { user, expiresAt } = request.auth;
      return response.status(200).json({ user, expiresAt: new Date(expiresAt).toISOString() });
    },

    async changePassword(request, response) {
      await authService.changePassword(readSessionCredential(request)?.token, request.body);
      if (request.sessionTransport === 'cookie') {
        clearSessionCookie(response);
      }
      return response.status(204).end();
    },

    logout(request, response) {
      authService.logout(readSessionCredential(request)?.token);
      if (request.sessionTransport === 'cookie') {
        clearSessionCookie(response);
      }
      return response.status(204).end();
    },
  };
}
