const bodyErrors = new Map([
  ['entity.parse.failed', { status: 400, message: 'Corps JSON invalide' }],
  ['request.aborted', { status: 400, message: 'Requête interrompue' }],
  ['request.size.invalid', { status: 400, message: 'Taille du corps invalide' }],
  ['entity.too.large', { status: 413, message: 'Corps JSON trop volumineux' }],
  ['charset.unsupported', { status: 415, message: 'Jeu de caractères non pris en charge' }],
  ['encoding.unsupported', { status: 415, message: 'Encodage du corps non pris en charge' }],
]);

const authErrors = new Map([
  ['INVALID_REQUEST', [400, 'Requête invalide.']],
  ['INVALID_SESSION_TRANSPORT', [400, 'Transport de session invalide ou ambigu.']],
  ['INVALID_CREDENTIALS', [401, 'Adresse ou mot de passe incorrect.']],
  ['SESSION_INVALID', [401, 'Session absente ou invalide.']],
  ['HTTPS_REQUIRED', [403, 'Une connexion HTTPS est requise.']],
  ['ORIGIN_FORBIDDEN', [403, 'Requête Web non autorisée.']],
  ['ROLE_FORBIDDEN', [403, 'Ce rôle ne permet pas cette opération.']],
  ['PASSWORD_UPDATE_CONFLICT', [409, 'Le mot de passe a déjà été modifié.']],
  ['PAYLOAD_TOO_LARGE', [413, 'Corps de requête trop volumineux.']],
  ['UNSUPPORTED_MEDIA_TYPE', [415, 'Le corps doit être un JSON pris en charge.']],
  ['CURRENT_PASSWORD_INVALID', [422, 'Mot de passe actuel incorrect.']],
  ['PASSWORD_POLICY', [422, 'Le nouveau mot de passe doit être différent et contenir entre 8 et 256 caractères Unicode.']],
  ['RATE_LIMITED', [429, 'Trop de tentatives. Réessayez plus tard.']],
  ['INTERNAL_ERROR', [500, 'Erreur interne du serveur.']],
  ['AUTH_UNAVAILABLE', [503, 'Service d’authentification temporairement indisponible.']],
]);

export class AuthError extends Error {
  constructor(code) {
    super(authErrors.get(code)?.[1]);
    this.code = code;
  }
}

export function authErrorHandler(error, _request, response, next) {
  if (response.headersSent) {
    return next(new Error('La réponse HTTP a été interrompue.'));
  }

  let code = 'INTERNAL_ERROR';
  if (error instanceof AuthError && authErrors.has(error.code)) {
    code = error.code;
  } else {
    const bodyError = bodyErrors.get(error?.type);
    if (bodyError) {
      code = { 400: 'INVALID_REQUEST', 413: 'PAYLOAD_TOO_LARGE', 415: 'UNSUPPORTED_MEDIA_TYPE' }[bodyError.status];
    } else {
      console.error('Erreur interne du module Auth.');
    }
  }

  const [status, message] = authErrors.get(code);
  return response.status(status).json({ error: { code, message } });
}

export function errorHandler(error, _request, response, next) {
  if (response.headersSent) {
    return next(new Error('La réponse HTTP a été interrompue.'));
  }

  const bodyError = bodyErrors.get(error.type);
  if (bodyError) {
    return response.status(bodyError.status).json({ error: bodyError.message });
  }

  console.error('Erreur HTTP interne.');
  return response.status(500).json({ error: 'Erreur interne du serveur' });
}
