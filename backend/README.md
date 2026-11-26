# Backend University Life

Le backend commun utilise Node.js 22.16.0 ou plus récent et npm. Les commandes suivantes s’exécutent depuis la racine du dépôt, dans PowerShell.

```powershell
Set-Location backend
npm ci
npm test
npm start
```

Le serveur écoute par défaut sur `127.0.0.1:3001`. Pour redémarrer automatiquement après une modification du code, utiliser `npm run dev`. Arrêter le serveur avec `Ctrl+C`.

## Configuration locale

Le serveur peut démarrer directement avec ses valeurs par défaut. Pour les personnaliser, copier `.env.example` vers `.env` dans `backend/`. Les variables déjà présentes dans l’environnement ont priorité sur ce fichier. Le fichier `.env` est ignoré par Git et les secrets utilisés hors développement doivent être injectés dans l’environnement d’exécution.

| Variables | Usage |
| --- | --- |
| `HOST` et `PORT` | Adresse d’écoute et port HTTP. Les valeurs par défaut sont `127.0.0.1` et `3001`. |
| `CORS_ORIGINS` | Liste d’origines HTTP(S) séparées par des virgules. Inclure le port du client Web si nécessaire, par exemple `http://localhost:8080`. Une liste vide désactive les en-têtes CORS. |
| `PGHOST` et `PGPORT` | Adresse PostgreSQL. Les valeurs par défaut sont `localhost` et `5432`. |
| `PGDATABASE`, `PGUSER` et `PGPASSWORD` | Laisser les trois valeurs vides pour le mode HTTP seul. Lorsqu’une valeur est renseignée, les trois sont requises. Utiliser un rôle applicatif avec les droits convenus avec Ghizlane. |

Lorsque les trois identifiants sont renseignés, le serveur initialise le pool au démarrage. Le pool ouvre une connexion à sa première utilisation. La connexion réelle et la cible PostgreSQL seront vérifiées après validation de l’équipe.

## Vérification manuelle

Dans un autre terminal, vérifier le statut HTTP et le corps de la réponse.

```powershell
curl.exe -i http://127.0.0.1:3001/health
curl.exe -i http://127.0.0.1:3001/introuvable
'{' | curl.exe -i -H 'Content-Type: application/json' --data-binary '@-' http://127.0.0.1:3001/health
```

Les réponses attendues sont `200` avec `{"status":"ok"}`, `404` avec `{"error":"Route introuvable"}` et `400` avec `{"error":"Corps JSON invalide"}`.

Les tests automatisés utilisent `node:test`, un port HTTP temporaire et une configuration PostgreSQL fictive pour vérifier la création du pool sans ouvrir de connexion.
