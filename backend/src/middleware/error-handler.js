const bodyErrors = new Map([
  ['entity.parse.failed', { status: 400, message: 'Corps JSON invalide' }],
  ['request.aborted', { status: 400, message: 'Requête interrompue' }],
  ['request.size.invalid', { status: 400, message: 'Taille du corps invalide' }],
  ['entity.too.large', { status: 413, message: 'Corps JSON trop volumineux' }],
  ['charset.unsupported', { status: 415, message: 'Jeu de caractères non pris en charge' }],
  ['encoding.unsupported', { status: 415, message: 'Encodage du corps non pris en charge' }],
]);

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
