# Workflow Git

## Branches

- `main` contient la version stable et intégrée du projet.
- `feature/auth` accueille le travail d'authentification du développeur A.
- `feature/student` accueille le travail sur l'espace étudiant et les notifications du développeur B.
- Créer les branches de travail à partir de `main`. Ne pas pousser de commits ni créer automatiquement de branches distantes.

## Commits et Pull Requests

- Faire des commits courts, cohérents et décrits par un message qui indique le changement.
- Ouvrir une Pull Request vers `main` quand un changement est prêt à être relu. Décrire le périmètre, les fichiers communs touchés et les vérifications effectuées.
- L'autre développeur relit les changements, en particulier les contrats partagés. Intégrer la Pull Request selon la procédure retenue par le binôme.

## Synchronisation avant intégration

Avant l'intégration, synchroniser la branche de travail avec la version la plus récente de `main`, résoudre les conflits sur sa branche, puis mettre à jour et faire relire la Pull Request. Ne pas intégrer une branche qui n'a pas été synchronisée.

## État initial

Ce document décrit le workflow prévu. Le dossier actuel n'est pas un dépôt Git initialisé ; la création du dépôt local et son éventuelle connexion distante restent à décider par le binôme.
