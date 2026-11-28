import { assertAuthHttps, readSessionCredential } from '../modules/auth/auth.transport.js';

export function authenticate(authService) {
  return async (request, _response, next) => {
    assertAuthHttps(request);
    const credential = readSessionCredential(request);
    request.auth = await authService.me(credential?.token);
    next();
  };
}
