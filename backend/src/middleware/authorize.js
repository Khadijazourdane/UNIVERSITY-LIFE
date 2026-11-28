import { isAuthRole } from '../modules/auth/auth.validation.js';
import { AuthError } from './error-handler.js';

export function authorize(...allowedRoles) {
  if (allowedRoles.length === 0 || allowedRoles.some((role) => !isAuthRole(role))) {
    throw new TypeError('Indiquez au moins un rôle du dictionnaire officiel.');
  }

  return (request, _response, next) => {
    if (!request.auth) {
      throw new AuthError('SESSION_INVALID');
    }
    if (!allowedRoles.includes(request.auth.user.role)) {
      throw new AuthError('ROLE_FORBIDDEN');
    }
    next();
  };
}
