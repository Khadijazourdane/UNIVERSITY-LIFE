# Architecture de University Life

## Périmètre

Ce document prépare l'organisation du code Flutter. Les fichiers Dart listés ci-dessous sont prévus, mais ne sont pas créés tant que leur implémentation n'est pas définie. Les `.gitkeep` ne servent qu'à conserver les dossiers préparés dans Git. Aucun contrat d'API, schéma de base de données, modèle de données ou dépendance supplémentaire n'est défini ici.

Le projet Flutter de démarrage contient déjà `lib/main.dart`. Il est conservé tel quel ; l'intégration de `app.dart` et le remplacement de l'écran de démonstration seront faits lors d'une décision d'implémentation dédiée.

## Responsabilités des couches

- `lib/core/` regroupe les fondations techniques communes : configuration, thème, navigation, réseau et stockage. Cette couche ne porte pas les règles métier d'une fonctionnalité.
- `lib/shared/` regroupe les modèles et widgets réellement réutilisés à travers plusieurs fonctionnalités. Un élément propre à une fonctionnalité reste dans son dossier `features/`.
- `lib/features/` organise le code par domaine fonctionnel. Chaque domaine garde ses écrans, modèles, services et fournisseurs d'état ensemble. Les espaces professeur (`teacher/`) et administrateur (`admin/`) restent réservés et ne reçoivent aucune implémentation dans le périmètre actuel.

## Répartition du binôme

- **Développeur A** : `core/`, `shared/`, `features/auth/`, `features/profile/`, `main.dart` et `app.dart`.
- **Développeur B** : `features/student/` et `features/notifications/`.

Cette répartition attribue la responsabilité des fichiers ; elle ne vaut pas validation de leur contrat technique ou métier.

## Conventions et coordination

- Les noms de fichiers sont en `snake_case`, avec l'extension adaptée, par exemple `login_screen.dart` ou `architecture.md`.
- Avant d'ajouter un widget ou un service, rechercher s'il existe déjà dans `shared/`, `core/` ou la fonctionnalité concernée. Un composant commun a un propriétaire et une seule définition ; les fonctionnalités le réutilisent au lieu d'en créer une copie.
- Avant toute modification d'un fichier commun ou d'une frontière entre couches, les deux développeurs s'accordent sur le besoin, le propriétaire et la signature attendue. La proposition est décrite dans la Pull Request et relue par l'autre développeur avant intégration.
- Tant que les décisions de contrat ne sont pas prises, conserver les dossiers et ne pas inventer de classes, méthodes, attributs, endpoints ou réponses.

## Fichiers Dart prévus, non créés

Les chemins ci-dessous documentent les emplacements réservés pour la suite du développement.

```text
lib/app.dart
lib/core/config/app_config.dart
lib/core/theme/app_colors.dart
lib/core/theme/app_text_styles.dart
lib/core/theme/app_theme.dart
lib/core/navigation/app_router.dart
lib/core/network/api_client.dart
lib/core/network/api_exception.dart
lib/core/storage/secure_storage_service.dart
lib/shared/models/user_model.dart
lib/shared/widgets/app_button.dart
lib/shared/widgets/app_text_field.dart
lib/shared/widgets/app_card.dart
lib/shared/widgets/app_bottom_nav.dart
lib/shared/widgets/status_badge.dart
lib/shared/widgets/loading_view.dart
lib/shared/widgets/error_view.dart
lib/features/auth/models/auth_session.dart
lib/features/auth/services/auth_service.dart
lib/features/auth/providers/auth_provider.dart
lib/features/auth/screens/login_screen.dart
lib/features/auth/screens/forgot_password_screen.dart
lib/features/auth/screens/change_password_screen.dart
lib/features/student/student_shell.dart
lib/features/student/dashboard/screens/dashboard_screen.dart
lib/features/student/dashboard/services/dashboard_service.dart
lib/features/student/dashboard/providers/dashboard_provider.dart
lib/features/student/timetable/models/session_model.dart
lib/features/student/timetable/services/timetable_service.dart
lib/features/student/timetable/providers/timetable_provider.dart
lib/features/student/timetable/screens/timetable_screen.dart
lib/features/student/timetable/widgets/session_card.dart
lib/features/student/grades/models/grade_model.dart
lib/features/student/grades/services/grade_service.dart
lib/features/student/grades/providers/grade_provider.dart
lib/features/student/grades/screens/grades_screen.dart
lib/features/student/absences/models/absence_model.dart
lib/features/student/absences/services/absence_service.dart
lib/features/student/absences/providers/absence_provider.dart
lib/features/student/absences/screens/absences_screen.dart
lib/features/student/courses/models/course_model.dart
lib/features/student/courses/services/course_service.dart
lib/features/student/courses/providers/course_provider.dart
lib/features/student/courses/screens/courses_screen.dart
lib/features/student/courses/screens/pdf_viewer_screen.dart
lib/features/student/attestations/models/attestation_request_model.dart
lib/features/student/attestations/services/attestation_service.dart
lib/features/student/attestations/screens/attestations_screen.dart
lib/features/student/attestations/screens/new_request_screen.dart
lib/features/notifications/models/notification_model.dart
lib/features/notifications/services/notification_service.dart
lib/features/notifications/screens/notifications_screen.dart
lib/features/profile/screens/profile_screen.dart
```

## Décisions à valider avant l'implémentation

- Les contrats et attributs des modèles, ainsi que les endpoints et formats de réponse du futur backend.
- Le choix des solutions de gestion d'état, de routage, de stockage sécurisé et de client réseau, avant toute nouvelle dépendance.
- La correspondance entre les maquettes University Life V2 et les écrans, y compris les éléments graphiques à fournir dans `assets/`.
- L'initialisation du dépôt Git local et la connexion à un dépôt distant, car aucun dépôt Git n'est présent dans le dossier actuel.
