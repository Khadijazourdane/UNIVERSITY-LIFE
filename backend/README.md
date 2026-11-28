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
| `AUTH_WEB_ORIGINS` | Origines HTTPS autorisées pour Auth sur Flutter Web, séparées par des virgules. Renseigner aussi l’origine du site si le frontend et l’API partagent la même origine. Android n’en a pas besoin. |
| `AUTH_SESSION_TTL_SECONDS` | Durée absolue d’une session. Valeur par défaut de `28800` secondes, soit 8 heures. |
| `TLS_CERT_FILE` et `TLS_KEY_FILE` | Chemins du certificat et de la clé PEM pour que Node écoute directement en HTTPS. Renseigner les deux ensemble. |
| `TRUST_PROXY_IP` | Adresse IP du proxy de confiance quand il termine TLS. Laisser vide pour une connexion directe à Node. |
| `PGHOST` et `PGPORT` | Adresse PostgreSQL. Les valeurs par défaut sont `localhost` et `5432`. |
| `PGDATABASE`, `PGUSER` et `PGPASSWORD` | Laisser les trois valeurs vides pour le mode HTTP seul. Lorsqu’une valeur est renseignée, les trois sont requises. Utiliser un rôle applicatif avec les droits convenus avec Ghizlane. |

Lorsque les trois identifiants sont renseignés, le serveur initialise le pool au démarrage. Le pool ouvre une connexion à sa première utilisation.

## Vérifier PostgreSQL

Depuis `backend/`, créez la configuration locale si le fichier est absent, puis ouvrez-la dans un éditeur.

```powershell
if (-not (Test-Path -LiteralPath .env)) {
  Copy-Item -LiteralPath .env.example -Destination .env
}
git check-ignore -v -- .env
notepad .env
```

Conservez `PGHOST=localhost` et `PGPORT=5432` pour le serveur local. Renseignez `PGDATABASE` avec le nom d’une base existante, et `PGUSER` et `PGPASSWORD` avec les identifiants du rôle autorisé. Saisissez ces valeurs dans le fichier local. Pour un mot de passe contenant `#` ou des espaces en début ou fin de valeur, entourez la valeur de guillemets.

Proposition à valider avec Ghizlane. Utiliser un rôle dédié avec `LOGIN` et `CONNECT` sur la base cible, sans privilèges de superutilisateur, de création de bases ou de création de rôles. Vérifier aussi les droits effectifs hérités de `PUBLIC` et des autres rôles. `SELECT 1` lit une constante et ne requiert aucun droit sur les tables. Toute création de rôle ou modification de privilèges nécessite une validation préalable.

```powershell
npm run db:check
$LASTEXITCODE
```

La commande utilise la configuration et le pool du backend. Elle exécute `SELECT 1 AS ok` sur la base existante et attend la fermeture du pool avant de terminer. Le statut `0` indique que la requête a renvoyé `1` et que le pool est fermé. Le statut `1` indique un échec et le diagnostic exclut les valeurs de configuration et les erreurs brutes du pilote. Ce contrôle fonctionne indépendamment du serveur HTTP. `GET /health` vérifie la disponibilité d’Express.

## Vérification manuelle

Dans un autre terminal, vérifier le statut HTTP et le corps de la réponse.

```powershell
curl.exe -i http://127.0.0.1:3001/health
curl.exe -i http://127.0.0.1:3001/introuvable
'{' | curl.exe -i -H 'Content-Type: application/json' --data-binary '@-' http://127.0.0.1:3001/health
```

Les réponses attendues sont `200` avec `{"status":"ok"}`, `404` avec `{"error":"Route introuvable"}` et `400` avec `{"error":"Corps JSON invalide"}`.

Les tests automatisés utilisent `node:test`, un port HTTP temporaire et une configuration PostgreSQL fictive pour vérifier la création du pool sans ouvrir de connexion.

## Authentification

Le serveur normal monte les quatre routes `/api/auth` et partage un seul service Auth et un seul magasin de sessions, accessibles via `app.locals.authService`. Avec une configuration PostgreSQL complète, le service réutilise le pool du serveur. Pour l’exploitation, configurer un rôle applicatif dédié. Réserver le compte d’administration locale à la préparation des fixtures. Si les trois identifiants PostgreSQL sont absents, `GET /health` reste disponible et les quatre opérations Auth renvoient `503 AUTH_UNAVAILABLE`. Une configuration partielle continue de produire une erreur de démarrage.

`createSessionStore({ ttlMs, maxSessions })` configure la durée absolue et la capacité. Les valeurs par défaut sont 8 heures et 10 000 sessions. Les jetons sont générés avec `node:crypto` et le magasin conserve leur empreinte SHA-256. Une session expirée est supprimée à la lecture. Une insertion à capacité maximale purge les entrées expirées, puis renvoie `503` si le magasin reste plein. Les sessions sont locales à un seul processus Node et sont perdues au redémarrage. Toute mise en service sur plusieurs processus nécessite un stockage partagé.

Le dépôt PostgreSQL isole les requêtes dans `src/modules/auth/auth.repository.js`. Il lit `id_utilisateur`, `nom`, `prenom`, `email`, `mot_de_passe` et `role` dans `public.utilisateur`. `updatePassword({ userId, expectedHash, newHash })` utilise un `UPDATE` paramétré qui compare le hash précédent dans sa clause `WHERE`. Le dictionnaire complet est absent du dépôt. L’implémentation suit le schéma de référence communiqué pour le lot 2. Si les migrations officielles utilisent un autre schéma physique, adapter le dépôt et vérifier l’unicité des emails normalisés avant le raccordement.

### Décisions de cette version

Le dépôt suit les noms de champs et les trois valeurs de rôle du schéma transmis. Le format Argon2id, la normalisation intégrale de l’email en minuscules, la politique des mots de passe et les sessions en mémoire sont des décisions d’équipe pour cette version.

Pour créer un compte via le futur module Admin, instancier une fois `await createArgon2PasswordService()` depuis `auth.password.js` et appeler `await passwords.hash(motDePasse)` avant l’enregistrement. Utiliser `normalizeAcademicEmail(email)` depuis `auth.validation.js` pour normaliser l’adresse avant l’écriture. Cette fonction retire les espaces aux extrémités, passe l’adresse entière en minuscules et impose le domaine exact `edu.uiz.ac.ma`. Le dépôt effectue la recherche sur l’adresse canonique. Si des adresses historiques existent, vérifier les doublons de casse avant de les normaliser.

Le hachage asynchrone utilise Argon2id version 19, 19 Mio de mémoire, deux itérations et un degré de parallélisme. Un hash de comparaison généré au démarrage sert pour les comptes absents et les hashes incompatibles. Le format accepté correspond aux paramètres émis par cette version. Les nouveaux mots de passe comptent entre 8 et 256 points de code Unicode. Les mots de passe saisis sont traités tels quels. Le changement est facultatif et le nouveau mot de passe doit différer de l’actuel. Les réponses et journaux applicatifs excluent mots de passe, hashes et diagnostics SQL bruts. Garder la journalisation des paramètres sensibles désactivée côté PostgreSQL.

### Contrats HTTP

Les réponses Auth portent `Cache-Control: no-store`. Les `POST` requièrent l’en-tête `X-Session-Transport: bearer` sur Android ou `X-Session-Transport: cookie` sur le Web. Les corps JSON utilisent `Content-Type: application/json`.

| Opération | Requête | Réponse |
| --- | --- | --- |
| `POST /api/auth/login` | `{"email":"…","password":"…"}` | `200` avec `user` et `expiresAt` en UTC. Android reçoit aussi `accessToken`. Le Web reçoit le cookie via `Set-Cookie`. |
| `GET /api/auth/me` | Bearer Android ou cookie Web | `200` avec `user` et `expiresAt`. |
| `POST /api/auth/change-password` | Session valide et `{"currentPassword":"…","newPassword":"…"}` | `204`. Toutes les sessions du compte sont révoquées et le cookie Web est effacé. |
| `POST /api/auth/logout` | Session présentée, sans corps | `204`, y compris si la session est déjà absente. Seule la session présentée est révoquée. |

`user` contient `id_utilisateur`, `nom`, `prenom`, `email` et `role`. Les valeurs SQL et JSON `etudiant`, `professeur` et `admin` correspondent respectivement à `UserRole.student`, `UserRole.teacher` et `UserRole.administrator` dans Flutter.

Les erreurs ont la forme `{"error":{"code":"SESSION_INVALID","message":"Session absente ou invalide."}}`. `400` signale une requête ou un transport invalide. `401` signale des identifiants incorrects ou une session invalide. `403` couvre `ROLE_FORBIDDEN`, `ORIGIN_FORBIDDEN` et `HTTPS_REQUIRED`. `409 PASSWORD_UPDATE_CONFLICT` signale une mise à jour concurrente. `413` et `415` couvrent la taille ou le format du corps. `422` indique un mauvais mot de passe actuel ou un nouveau mot de passe hors politique. `429` inclut `Retry-After`. `500 INTERNAL_ERROR` signale un défaut interne et `503 AUTH_UNAVAILABLE` indique un stockage indisponible ou une capacité de sessions atteinte.

### Protéger une route de module

Monter le parseur de cookies avant `authenticate(authService)`. Utiliser `authorize(...roles)` après l’authentification avec `etudiant`, `professeur` ou `admin`. Le gestionnaire `authErrorHandler` se place après les routes qui utilisent ces middlewares.

```js
import { authenticate } from '../../middleware/authenticate.js';
import { authorize } from '../../middleware/authorize.js';
import { protectSessionWrites } from '../../middleware/csrf-protection.js';
import { authErrorHandler } from '../../middleware/error-handler.js';
import { sessionCookies } from '../auth/auth.transport.js';

router.use(sessionCookies);
router.get(cheminDeLecture, authenticate(authService), authorize('etudiant'), lireRessource);
router.post(
  cheminDeModification,
  protectSessionWrites(webOrigins),
  authenticate(authService),
  authorize('etudiant'),
  modifierRessource,
);
router.use(authErrorHandler);
```

Lire `request.auth.user.id_utilisateur` pour déterminer l’utilisateur authentifié. Pour les données étudiantes privées, filtrer chaque requête métier par le profil lié à cet utilisateur via `etudiant.id_utilisateur`. Le contrôle du rôle devra être complété par ce filtre dans les futures requêtes métier.

### Vérifier HTTPS et les transports

Pour HTTPS direct, renseigner `TLS_CERT_FILE` et `TLS_KEY_FILE`, puis démarrer le serveur. Le certificat doit couvrir l’hôte utilisé et être approuvé par le client. Pour une terminaison TLS par proxy, renseigner `TRUST_PROXY_IP`, limiter l’accès réseau à Express à ce proxy et lui faire écraser `X-Forwarded-Proto` et les autres en-têtes de transfert. En HTTP direct avec PostgreSQL configuré, Auth renvoie `403 HTTPS_REQUIRED`.

Pour le Web, fournir l’origine HTTPS dans `AUTH_WEB_ORIGINS`. Les `POST` envoient `X-Session-Transport: cookie`, avec l’origine autorisée et les cookies gérés par le navigateur. Pour une API sur une origine différente du même site, activer l’envoi des cookies dans Dio Web. Le cookie `__Host-ul_session` porte `Secure`, `HttpOnly`, `SameSite=Lax` et `Path=/`. Sur Android, utiliser une `API_BASE_URL` HTTPS, conserver le jeton dans `flutter_secure_storage` et envoyer `Authorization: Bearer …` sur les opérations protégées. L’application doit confirmer la restauration avec `me` avant d’afficher un espace privé. Après le `204` de déconnexion ou de changement de mot de passe, effacer le jeton Android local. Express refuse le transport Bearer si la requête porte des en-têtes de contexte navigateur.

`express-rate-limit` applique des compteurs en mémoire pour le login par IP et par couple IP–email, et pour le changement de mot de passe par utilisateur. Les paramètres initiaux sont 40, 8 et 8 tentatives par fenêtre de 15 minutes, ajustables via `rateLimits`. `cookie-parser` lit les cookies entrants. `argon2` fournit le hachage et la vérification réels.

### Tests PostgreSQL isolés

Depuis `backend/`, après autorisation de créer la base et le rôle, utiliser un administrateur PostgreSQL local dans `.env` pour la préparation. Le script s’adresse à `template1` pour les opérations de création et installe la fixture dans `university_life_auth_test`. Il refuse les noms déjà utilisés et écrit les identifiants générés dans `.env.auth-test`, ignoré par Git. La fixture utilise uniquement `public.utilisateur`. Le rôle `university_life_auth_test_app` reçoit la lecture de cette table et la mise à jour de `mot_de_passe`.

```powershell
npm test
npm run db:auth-test:setup
npm run test:auth:postgres
```

Une fois la fixture créée, relancer seulement `npm run test:auth:postgres`. La suite utilise le vrai serveur et le vrai rôle applicatif, vérifie les trois rôles et restaure le hash de test après chaque modification. Par défaut elle simule une terminaison TLS sur la boucle locale. Pour l’exécuter en HTTPS direct, fournir `TLS_CERT_FILE` et `TLS_KEY_FILE` au processus de test avec un certificat local couvrant `127.0.0.1`. Pour un essai manuel sur cette base, lancer `node --env-file=.env.auth-test src/server.js` après avoir configuré HTTPS. Les variables PostgreSQL déjà présentes dans le terminal ont priorité sur le fichier. Vérifier la configuration du terminal avant le lancement.

Pour nettoyer après autorisation, arrêter les processus utilisant la fixture et se connecter au serveur local en tant qu’administrateur via `template1`. Exécuter les deux commandes suivantes, puis supprimer uniquement `backend/.env.auth-test`. La fixture est en dehors des migrations officielles.

```sql
DROP DATABASE university_life_auth_test;
DROP ROLE university_life_auth_test_app;
```
