# NALVIUM — PRODUCT UPGRADE V2

## Implémenté

- Navigation mobile à trois espaces : Accueil, Ma maison, Activité.
- Carnet local des diagnostics résolus, organisé par catégorie.
- Dossier de réparation backend `repair_records`.
- Photo avant conservée localement lorsqu’elle existe encore dans la session.
- Photo après facultative, uploadée comme média privé de la session.
- Présentation avant/après sans promesse de conformité ou de sécurité certifiée.
- Consentement explicite au partage anonyme.
- Table `shared_cases` séparée des médias privés.
- Les cas partagés ne publient aucun média : les références publiques restent nulles
  tant qu’un pipeline de dérivation contrôlé n’est pas configuré.

## Préparé pour plus tard

- Dérivation de copies publiques nettoyées et modérées des médias.
- Recherche de cas similaires par catégorie, sous-catégorie et tags.
- Affichage de cas réellement partagés.
- Types média `video` et `audio` dans le contrat média.
- Inventaire plus détaillé de la maison.

## Limites assumées

- Le carnet Flutter utilise encore le stockage local de l’historique existant
  pour fonctionner sans compte.
- Le dossier backend est créé à la résolution, mais l’association complète aux
  médias avant/après dépend de la continuité de session et de la configuration
  de stockage.
- Le partage est un consentement enregistré, pas une publication publique.
