# Architecture de University Life

## État de l’application

Le dépôt contient le squelette Flutter commun, le thème et les écrans
d’authentification. La connexion, la récupération et le changement de mot de
passe effectuent uniquement leurs validations locales. Aucun appel
d’authentification n’est envoyé à un serveur.

Le backend Node.js/Express, son contrat HTTP et le schéma PostgreSQL ne sont
pas présents dans ce dépôt. Les valeurs de réponse, le mécanisme de session et
les chemins d’API ne sont donc pas définis ici.

## Point d’entrée et assemblage

- `lib/main.dart` appelle `runApp(const UniversityLifeApp())`.
- `lib/app.dart` crée le `AuthProvider`, le `GoRouter` et le
  `MaterialApp.router` avec `AppTheme.light`.
- `lib/core/navigation/app_routes.dart` centralise les noms et chemins des
  routes Flutter.
- `lib/core/navigation/app_router.dart` configure les écrans d’authentification,
  les redirections selon l’état de session, les routes protégées et la route
  inconnue.

Le fournisseur et le routeur vivent pendant celle de l’application et sont
libérés dans `dispose()`. La connexion n’est pas considérée comme réussie
parce que le formulaire est valide : seul un résultat ultérieur confirmé par
le service d’authentification pourra placer l’état en `authenticated`.

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

- `lib/features/auth/screens/` contient les écrans de connexion, récupération
  et changement de mot de passe.
- `lib/features/auth/validators/university_email_validator.dart` partage les
  règles de validation de l’adresse universitaire.
- `lib/features/auth/models/auth_session.dart` définit les rôles métier
  Étudiant, Professeur et Administrateur, sans mapping JSON.
- `lib/features/auth/providers/auth_provider.dart` expose les états
  `initializing`, `unauthenticated`, `authenticating`, `authenticated` et
  `error`.
- `lib/features/auth/services/auth_service.dart` définit le port applicatif des
  opérations d’authentification, sans chemins HTTP ni format de données.

`AuthSession` contient actuellement le rôle métier confirmé uniquement. Elle ne
contient ni jeton ni mot de passe. `AuthProvider` démarre en état
`initializing`; aucune fonction de production ne crée une session. Les états
authentifiés utilisés par les tests sont injectés dans les tests seulement.

`clearLocalSession()` efface uniquement l’état en mémoire. La révocation d’une
session côté serveur et l’action de déconnexion dans l’interface restent à
connecter au contrat backend et à un écran de profil commun.

## Navigation et espaces de rôle

Les routes sont déclarées dans `app_router.dart` : connexion, récupération,
changement de mot de passe et les chemins des trois espaces. Les routes de rôle
sont protégées : un utilisateur non authentifié est redirigé vers la connexion;
un rôle ne peut pas accéder à l’espace d’un autre rôle. Le changement de mot de
passe est autorisé pour les trois rôles authentifiés. Une route inconnue affiche
une page explicite.

Les espaces étudiant, professeur et administrateur n’ont pas encore d’écrans
dans ce dépôt. Le routeur affiche donc une page d’attente indiquant que l’écran
métier doit être intégré; aucun tableau de bord fictif n’est présenté. L’accès
au changement de mot de passe est enregistré comme route protégée, mais son
entrée depuis un profil reste à intégrer lorsque l’écran commun de profil sera
disponible.

Les routes ne remplacent pas les contrôles d’autorisation backend. La valeur du
rôle doit venir d’une réponse réelle et validée du serveur, jamais d’un choix
sur l’écran de connexion.

## Réseau et contrat backend

- `lib/core/config/app_config.dart` lit `API_BASE_URL` à la compilation. Aucune
  URL de serveur n’est codée en dur.
- `lib/core/network/api_client.dart` configure Dio et des délais bornés. Il
  n’enregistre aucun intercepteur de journalisation et ne définit aucun
  endpoint. Il conserve les réponses en texte brut par défaut afin de ne pas
  imposer un format JSON avant confirmation du contrat.
- `lib/core/network/api_exception.dart` distingue transport, délai dépassé,
  réponse HTTP, annulation et erreur inconnue sans inclure le contenu de la
  requête ou de la réponse.
- `AuthService` est une interface applicative; aucun service HTTP concret
  n’existe encore.
- `flutter_secure_storage` est installé mais n’est pas utilisé. Aucun jeton ou
  mécanisme de session n’étant défini, aucun stockage n’est créé.

La configuration HTTP devient utilisable lorsque l’URL de base est fournie via
`--dart-define=API_BASE_URL=...`. Ce paramètre ne détermine pas les chemins,
méthodes ou formats des opérations.

Avant une intégration réelle, l’équipe backend doit fournir : les routes et
méthodes, les champs et réponses, les erreurs métier, les valeurs de rôles, le
mécanisme et la durée de session, le renouvellement/révocation, le parcours de
récupération de compte et un environnement de test. Le client Flutter ne se
connecte jamais directement à PostgreSQL.

## Répartition de l’équipe

- Le Membre 1 travaille principalement sur `core/`, `shared/`, `features/auth/`,
  `features/profile/`, `main.dart` et `app.dart`.
- Le Membre 2 est propriétaire de `features/student/` et
  `features/notifications/`.

Les dossiers étudiant et notifications restent réservés au Membre 2. Les
dossiers professeur, administrateur et profil n’ont pas encore d’écrans métier.
Toute modification d’une frontière commune doit être relue et validée par les
deux membres.

## Références

- `docs/design/University_Life_Design_UX_UI.pdf` : charte et maquettes UX/UI V2.
- `docs/git_workflow.md` : conventions Git du projet.
- Le cahier des charges, le dictionnaire PostgreSQL et le contrat API ne sont
  pas présents dans le dépôt à ce jour.
