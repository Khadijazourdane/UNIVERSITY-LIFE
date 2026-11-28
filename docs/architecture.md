# Architecture de University Life

## État de l’application

Flutter utilise les routes Auth du backend Express pour la connexion, la
restauration de session, le changement de mot de passe et la déconnexion. Les
écrans métier et leurs clients restent sous la responsabilité de leurs modules.
L’écran de récupération indique que le parcours en ligne est en préparation.

## Point d’entrée et assemblage

- `lib/main.dart` appelle `runApp(const UniversityLifeApp())`.
- `lib/app.dart` crée le `AuthProvider`, le `GoRouter` et le
  `MaterialApp.router` avec `AppTheme.light`.
- `lib/core/navigation/app_routes.dart` centralise les noms et chemins des
  routes Flutter.
- `lib/core/navigation/app_router.dart` configure les écrans d’authentification,
  les redirections selon l’état de session, les routes protégées et la route
  inconnue.

`UniversityLifeApp` injecte le service Auth HTTP et lance la restauration au
démarrage. Le fournisseur, le routeur et le client Dio qu’elle crée sont
libérés dans `dispose()`. Le passage à `authenticated` exige une réponse
valide du serveur.

## Couches

- `lib/core/` contient les fondations techniques : configuration, thème,
  navigation, réseau et stockage.
- `lib/shared/` contient les éléments effectivement réutilisés par plusieurs
  fonctionnalités.
- `lib/features/` organise l’application par domaine fonctionnel. Les écrans,
  modèles et états propres à un domaine restent dans sa fonctionnalité.

Les widgets communs implémentés sont :

- `lib/shared/widgets/app_button.dart` : bouton principal ou secondaire,
  désactivé ou en chargement.
- `lib/shared/widgets/app_text_field.dart` : libellé, champ Material, validateur
  et sémantique accessible partagés par les formulaires.

Les variantes particulières, comme la bascule Voir/Masquer, restent configurées
par la fonctionnalité qui les utilise.

## Thème

Le thème clair Material 3 est défini dans `lib/core/theme/` :

- `app_colors.dart` : palette University Life.
- `app_text_styles.dart` : DejaVu Sans locale et styles typographiques.
- `app_dimensions.dart` : espacements, rayons, tailles de contrôles et marges.
- `app_theme.dart` : assemblage de `ThemeData`.

Les fichiers DejaVu Sans et leur licence se trouvent dans
`assets/fonts/`. Le thème utilise ces ressources déclarées dans `pubspec.yaml`.

## Authentification et session

| Fichier | Responsabilité |
| --- | --- |
| `lib/features/auth/services/auth_service.dart` | Interface consommée par le provider. |
| `lib/features/auth/services/http_auth_service.dart` | Appels aux quatre routes Auth via le Dio commun. Les requêtes JSON Auth sont configurées localement et le comportement par défaut d’`ApiClient` reste en texte brut. |
| `lib/core/network/auth_platform*.dart` | Adaptateur natif et certificat de développement en debug. Adaptateur Web avec envoi des cookies. |
| `lib/core/storage/session_token_store.dart` | Stockage sécurisé du Bearer natif avec une clé par origine API. |
| `lib/features/auth/models/auth_session.dart` | Rôle confirmé et date d’expiration. Les identifiants de session restent dans la couche transport. |
| `lib/features/auth/providers/auth_provider.dart` | Restauration, sérialisation des opérations, invalidation et messages à afficher. |
| `lib/features/auth/screens/` | Formulaires existants, validation et retours d’état. |
| `lib/features/auth/widgets/authenticated_space.dart` | Menu Compte commun avec changement de mot de passe et déconnexion. |

Le Bearer est envoyé vers l’origine HTTPS fixée à la construction du service.
Les redirections sont désactivées sur le client natif. Sur le Web, le navigateur
gère le cookie `HttpOnly`. Le seul indicateur d’Auth en `localStorage` est un
marqueur non sensible qui suspend la restauration après une fermeture locale.

La restauration passe par `GET /api/auth/me` avant tout accès à un espace privé.
Un refus confirmé ferme la session locale. Une panne réseau garde le jeton
pour permettre de réessayer. À l’échéance locale, le routeur ferme l’accès aux
espaces privés. Une révocation distante est détectée à la prochaine opération
Auth protégée ou restauration. Les sessions du backend restent en mémoire et
disparaissent au redémarrage d’Express.

Le bouton de déconnexion Admin existant passe par le provider commun. Une erreur
de révocation affiche une action de fermeture locale distincte avec un message
qui indique que la révocation distante reste à confirmer. Après un changement
de mot de passe réussi, le backend invalide toutes les sessions du compte et
Flutter redirige vers la connexion.

## Navigation et contrat backend

| Rôle JSON | Rôle Flutter | Route |
| --- | --- | --- |
| `etudiant` | `UserRole.student` | `/student` |
| `professeur` | `UserRole.teacher` | `/teacher` |
| `admin` | `UserRole.administrator` | `/administrator` |

`AppRouter` refuse les espaces privés sans session et redirige un rôle vers son
espace. Les trois tableaux de bord existants conservent leur contenu. Chaque
route métier du serveur doit appliquer les middlewares et le filtre de propriété
appropriés. Pour un étudiant, ce filtre part de l’identité authentifiée et du
profil lié via `etudiant.id_utilisateur`.

Se reporter au [contrat Auth et guide des middlewares](../backend/README.md#contrats-http)
pour les requêtes, les erreurs JSON, Argon2id, les variables backend et les
droits PostgreSQL. Le dépôt suppose `public.utilisateur` selon le schéma transmis.
L’adaptateur et l’unicité des adresses normalisées devront être vérifiés avec les
migrations officielles avant le raccordement à la base métier.

## Développement HTTPS Android

La permission `INTERNET` est déclarée dans le manifeste principal. Il faut les
outils Android du SDK et un appareil visible via `flutter devices` ou un AVD
configuré. Le SDK Flutter du projet utilise Android 36 et le NDK
`28.2.13676358`. Installer la plateforme Android 36, les Build Tools et les
Platform-Tools avec le SDK Manager officiel. Les dépendances JNI requièrent
aussi la plateforme Android 35 et CMake 3.22.1. Dans Android Studio, afficher
les détails des paquets **NDK (Side by side)** pour sélectionner la version
requise.
L’installation du NDK est complète lorsque son répertoire contient notamment
`source.properties` et `toolchains`. En cas de `CXX1101`, conserver une copie
du dossier incomplet et réinstaller la même version avant de relancer le build.
Si le journal JVM indique un manque de mémoire, arrêter l’émulateur le temps
de compiler, puis le relancer pour les essais.

Pour un émulateur, créer un appareil dans **Device Manager** avec une image
Android 36 x86_64 sur un PC compatible et relever son identifiant
avec `flutter devices`. Pour un téléphone, activer le débogage USB, le brancher
et accepter l’autorisation ADB. `adb devices` doit l’afficher avec l’état
`device`. Les commandes ci-dessous supposent que les Platform-Tools sont dans
le `PATH` du terminal.

Pour une connexion locale, préparer le certificat public et sa clé hors du
dépôt. Depuis PowerShell, avec OpenSSL disponible.

```powershell
$ulTls = Join-Path $env:TEMP 'university-life-auth-tls'
New-Item -ItemType Directory -Force -Path $ulTls | Out-Null
$env:MSYS2_ARG_CONV_EXCL = '*'
$ulCert = Join-Path $ulTls 'auth-dev.pem'
$ulKey = Join-Path $ulTls 'auth-dev-key.pem'
openssl req -x509 -newkey rsa:2048 -nodes -days 7 -subj '/CN=University Life DEV' -addext 'subjectAltName=IP:127.0.0.1,IP:10.0.2.2,DNS:localhost' -keyout $ulKey -out $ulCert
```

Dans un terminal ouvert à la racine, démarrer Express avec la fixture déjà
provisionnée. Les variables `PG*` héritées du terminal ont priorité sur le
fichier. Utiliser un terminal où elles ne pointent pas vers une autre base.

```powershell
$ulTls = Join-Path $env:TEMP 'university-life-auth-tls'
$env:HOST = '127.0.0.1'
$env:PORT = '3001'
$env:TLS_CERT_FILE = Join-Path $ulTls 'auth-dev.pem'
$env:TLS_KEY_FILE = Join-Path $ulTls 'auth-dev-key.pem'
Set-Location backend
node --env-file=.env.auth-test src/server.js
```

Dans un second terminal à la racine. Remplacer l’identifiant par celui indiqué
par `flutter devices`.

```powershell
$ulCert = Join-Path $env:TEMP 'university-life-auth-tls/auth-dev.pem'
$ulPublicCert = [Convert]::ToBase64String([IO.File]::ReadAllBytes($ulCert))
flutter run -d emulator-5554 --dart-define=API_BASE_URL=https://10.0.2.2:3001 "--dart-define=AUTH_DEBUG_CA_BASE64=$ulPublicCert"
```

`10.0.2.2` désigne la boucle locale de l’hôte depuis l’émulateur. Pour un
téléphone physique sur le même réseau privé, inclure l’IP locale du PC dans le
SAN du certificat, configurer `HOST` sur cette IP, puis utiliser cette IP dans
`API_BASE_URL`. Le certificat public est approuvé uniquement par le client Auth
natif en debug. La vérification du nom et de la chaîne reste active. En release,
utiliser un certificat reconnu par le système.

Pour tester un téléphone connecté en USB sans exposer le backend sur le réseau,
laisser Express écouter sur `127.0.0.1` et rediriger le port avec ADB. Le
certificat généré ci-dessus couvre déjà `127.0.0.1`.

```powershell
adb devices -l
$ulDevice = Read-Host 'Identifiant du téléphone dans adb devices'
adb -s $ulDevice reverse tcp:3001 tcp:3001
flutter run -d $ulDevice --dart-define=API_BASE_URL=https://127.0.0.1:3001 "--dart-define=AUTH_DEBUG_CA_BASE64=$ulPublicCert"
```

Pour le Web local, servir Flutter et l’API en HTTPS sur la même origine ou sur
deux ports du même site. Par exemple, avec `https://localhost:8443` pour Flutter
et `https://localhost:3001` pour Express, configurer
`AUTH_WEB_ORIGINS=https://localhost:8443` dans le terminal backend. Le navigateur
doit approuver le certificat local. Dio envoie ensuite les cookies avec les
requêtes Auth. Le paramètre debug de confiance native ne s’applique pas au Web.

```powershell
$ulTls = Join-Path $env:TEMP 'university-life-auth-tls'
$ulCert = Join-Path $ulTls 'auth-dev.pem'
$ulKey = Join-Path $ulTls 'auth-dev-key.pem'
flutter run -d chrome --web-hostname=localhost --web-port=8443 "--web-tls-cert-path=$ulCert" "--web-tls-cert-key-path=$ulKey" --dart-define=API_BASE_URL=https://localhost:3001
```

### Vérifications

```powershell
flutter analyze --no-pub
flutter test --no-pub
flutter build web --no-pub
flutter build apk --debug --no-pub
```

Pour le test Flutter sur le PC, démarrer Express en HTTPS comme ci-dessus.
Exécuter ensuite depuis la racine avec le certificat public encodé. Ce test lit
les comptes de `backend/.env.auth-test`, vérifie les trois rôles et restaure le
mot de passe initial après le changement. Le stockage natif est remplacé par un
stockage en mémoire dans ce test hôte.

```powershell
flutter test --no-pub tool/auth_live_test.dart --dart-define=API_BASE_URL=https://127.0.0.1:3001 "--dart-define=AUTH_DEBUG_CA_BASE64=$ulPublicCert"
```

Les tests backend se lancent depuis `backend/` avec `npm test` et
`npm run test:auth:postgres`. Exécuter les suites qui modifient la fixture l’une
après l’autre.

Sur Android, utiliser les trois comptes de la fixture isolée. Vérifier les
trois destinations de connexion, puis arrêter l’application et la rouvrir
pendant que le même serveur Express tourne pour tester la restauration. Après
une déconnexion ou un changement de mot de passe, vérifier que l’ancien accès
est refusé. Pour tester une panne, interrompre temporairement l’instance de
test, puis vérifier le message et l’action de réessai. Redémarrer Express fait
expirer ses sessions en mémoire. Restaurer ensuite le mot de passe initial du
compte fictif utilisé pour le changement.

## Répartition de l’équipe

- Le Membre 1 travaille principalement sur `core/`, `shared/`, `features/auth/`,
  `features/profile/`, `main.dart` et `app.dart`.
- Le Membre 2 est propriétaire de `features/student/` et
  `features/notifications/`.

Les clients et écrans métier Étudiant, Professeur et Admin gardent leurs
responsables. Toute modification des contrats communs ou de la protection des
données métier doit être coordonnée avec les membres concernés.

## Références

- `docs/design/University_Life_Design_UX_UI.pdf` : charte et maquettes UX/UI V2.
- `docs/git_workflow.md` : conventions Git du projet.
- Le dictionnaire PostgreSQL complet est absent du dépôt. Le contrat API et la
  procédure de test Auth sont documentés dans `backend/README.md`.
