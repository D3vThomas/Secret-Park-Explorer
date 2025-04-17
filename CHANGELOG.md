# Changelog

## [v0.4.0] - 2025-04-17

### Changements importants

-   **Ajout de la fonctionnalité photo par lieu secret** :

    -   Il est désormais possible de **prendre une photo** à un emplacement secret et de l’associer au marqueur correspondant.
    -   Les photos sont **stockées localement** sur l’appareil (aucune donnée n’est envoyée en ligne).
    -   Si une photo est déjà liée à un marqueur, un bouton **"Voir la photo"** permet de la consulter dans une pop-up.

-   **Utilisation de la caméra** :
    -   Intégration de `image_picker`, `path_provider` et `shared_preferences`.
    -   Sauvegarde des chemins d'accès aux photos dans `SharedPreferences` pour un accès persistant.

### Autres améliorations

-   Préparation du code pour la **suppression ou le remplacement de photo** dans une future version.
-   Petits ajustements UI dans la gestion des filtres et des pop-ups.

---

## [v0.3.0] - 2025-04-10

### Changements importants

-   **Modification des noms** : Tous les noms d’attractions, zones, restaurants et boutiques ont été modifiés pour garantir la conformité avec les lois sur les droits d’auteur et les marques déposées.
-   Des noms alternatifs plus génériques et thématiques ont été adoptés, tout en maintenant l'esprit et l’expérience de l’application.

### Autres améliorations

-   Correction de quelques **bugs mineurs de performance**.
-   **Amélioration de la réactivité de l’interface** pour une navigation plus fluide.

---

## [v0.2.0] - 2025-03-30

### Nouveautés

-   **Ajout de photos aux points d’intérêt (POI)** : Chaque point d’intérêt dispose désormais d’une image associée, visible lors du clic sur le marqueur sur la carte.
-   **Popup avec photo** : Une nouvelle option "Photo" dans les pop-ups permet d'afficher l'image associée à chaque point d’intérêt.
-   **Affichage amélioré des points d’intérêt** : Possibilité de filtrer les secrets par zone thématique (Main Street, Adventureland, Fantasyland, Discoveryland, Studios).

### Améliorations

-   **Optimisation de la performance** pour une expérience utilisateur plus fluide.
-   **Amélioration de l’interface utilisateur** pour intégrer l'affichage des photos sans nuire à la navigation.

---

## [v0.1.0] - 2025-03-15

### Fonctionnalités principales

-   Affichage des secrets et points d'intérêt (POI) via une carte interactive.
-   **Filtrage des secrets par zone thématique** (Main Street, Adventureland, Fantasyland, Discoveryland, Studios).
-   **Cartographie interactive** avec zoom et possibilité de navigation.
-   Détails des secrets via pop-up lors du clic sur les points d'intérêt.
-   Intégration de **Google Maps** pour la localisation en temps réel.

### Nouveautés de cette version

-   **Déploiement initial** avec une carte affichant les points d’intérêt et des marqueurs distincts pour chaque catégorie.
-   **Filtrage par zone thématique** pour personnaliser l'expérience de l’utilisateur.
