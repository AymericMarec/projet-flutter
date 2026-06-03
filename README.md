# Application de gestion de projets

Une application Flutter de gestion de tâches et de projets développée avec une architecture hexagonale. Cette approche permet une séparation stricte entre la logique métier, l'infrastructure et l'interface utilisateur.

## Technologies utilisées

- **Architecture Hexagonale** : Choisie pour isoler le domaine métier de l'infrastructure, ce qui rend le code modulaire, indépendant des frameworks externes, et facilement testable.
- **Riverpod** : Sélectionné pour la gestion d'état et l'injection de dépendances. Il offre une sécurité à la compilation, évite les erreurs d'état, et s'intègre parfaitement pour relier les couches de l'architecture.
- **Freezed & JSON Serializable** : Utilisés pour créer des modèles de données immuables. Cela garantit l'intégrité des données dans l'application et simplifie la sérialisation.
- **AutoRoute** : Facilite la navigation avec un système de routage fortement typé et généré automatiquement, réduisant le code boilerplate.
- **SharedPreferences** : Solution simple et rapide pour la persistance locale des données de l'application (projets, tâches) et des préférences utilisateur (thèmes).

## Fonctionnalités notables

- **Mode Kanban** : Une vue dynamique permettant de visualiser et de gérer l'état d'avancement des projets via un tableau structuré (À faire, En cours, Terminé).
- **Thème dynamique** : Prise en charge des thèmes clair, sombre et système, ainsi qu'une personnalisation de la couleur d'accentuation de l'application.

## Comment démarrer

Assurez-vous d'avoir le SDK Flutter installé sur votre machine.

1. Installez les dépendances du projet :
```bash
flutter pub get
```

2. Générez les fichiers nécessaires au bon fonctionnement (modèles Freezed, routes AutoRoute, etc.) :
```bash
dart run build_runner build -d
```

3. Lancez l'application :
```bash
flutter run
```
