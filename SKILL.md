# NALVIUM — SKILL MAÎTRE

Version: 0.2 — Site public SEO intégré
Contact produit: contact@nalvium.com
Domaine principal: nalvium.com

## 1. Mission

NALVIUM est un assistant IA mobile gratuit pour les particuliers qui aide à comprendre et, lorsque cela peut être fait raisonnablement et sans danger, résoudre un problème domestique.

Parcours central :
PHOTO / VIDÉO / DESCRIPTION → ANALYSE → QUESTIONS CIBLÉES → ACTION GUIDÉE → VÉRIFICATION → RÉSOLU
ou
PHOTO / VIDÉO / DESCRIPTION → ANALYSE → RISQUE / ÉCHEC / BESOIN PRO → DEMANDE D’ARTISAN QUALIFIÉE

NALVIUM n’est pas un simple chatbot. Le produit doit observer, demander une preuve visuelle si utile, guider une action à la fois, vérifier le résultat et savoir arrêter.

## 2. Principes non négociables

1. Gratuit pour le particulier en V1.
2. Caméra/photo au centre de l’expérience.
3. Une seule action claire à la fois.
4. Ne jamais présenter une hypothèse IA comme une certitude.
5. La sécurité prime toujours sur la complétion d’une réparation.
6. Les cas dangereux doivent basculer vers STOP / mise en sécurité / professionnel ou service d’urgence approprié.
7. Les coordonnées et photos ne sont jamais transmises à un professionnel sans consentement explicite.
8. Les clés API et secrets restent côté serveur.
9. Aucune dépendance à un fournisseur ne doit être enfouie directement dans l’UI.
10. Aucun push Git, déploiement production, migration destructive, achat ou action irréversible sans GO explicite du propriétaire du projet.
11. Chaque chantier Codex commence par lire SKILL.md et les documents concernés dans docs/.
12. Ne pas réécrire une partie stable sans raison démontrée.
13. Toute modification importante doit être testée.
14. Mobile-first. Android V1, architecture compatible iOS.
15. Français V1, architecture i18n dès le départ.
16. Le site public fait partie du produit V1 et non d’une simple vitrine.
17. Le SEO doit privilégier la valeur réelle : aucune génération massive de pages locales pauvres ou dupliquées.
18. Les pages locales ne doivent jamais inventer la présence, disponibilité, avis ou intervention d’un professionnel.

## 3. Périmètre V1

Priorité :
- plomberie domestique simple ;
- électroménager ;
- bricolage domestique simple ;
- identification/orientation de certains problèmes électriques sans guider des manipulations dangereuses.

Exemples autorisés selon contexte :
- siphon qui fuit ;
- robinet qui goutte ;
- chasse d’eau qui coule ;
- évier lent/bouché avec méthodes sûres ;
- filtre de lave-linge ;
- code erreur d’un appareil ;
- fixation simple ;
- identification d’une pièce ou d’un consommable.

Exemples devant déclencher une forte prudence ou un STOP :
- odeur ou suspicion de gaz ;
- fumée/incendie ;
- conducteurs électriques exposés, brûlure électrique, tableau électrique ou intervention sous tension ;
- eau au contact d’une installation électrique ;
- risque structurel ;
- produit chimique dangereux ;
- appareil sous pression ou situation que le modèle ne comprend pas suffisamment ;
- toute action nécessitant une compétence réglementée ou présentant un risque sérieux.

## 4. Architecture cible

- App : Flutter.
- Backend API : FastAPI Python ou Node/TypeScript ; choix définitif documenté avant implémentation.
- DB : PostgreSQL.
- Stockage média : stockage objet privé avec URLs signées.
- IA : couche serveur abstraite pour modèle multimodal.
- Dashboard : application web d’administration/pros.
- Website : site public nalvium.com, acquisition organique, guides et SEO local/programmatique.
- Analytics : événements métier, sans collecter plus de données que nécessaire.
- Auth : l’utilisation du premier diagnostic doit pouvoir commencer sans création de compte si techniquement raisonnable.

## 5. Règles de développement

Avant modification :
1. Lire les docs applicables.
2. Inspecter l’existant.
3. Énoncer le plan.
4. Modifier le minimum nécessaire.
5. Exécuter format/lint/tests pertinents.
6. Rapporter fichiers modifiés, tests exécutés, limites et prochaines étapes.

Interdictions :
- ne pas supprimer des tests pour faire passer une build ;
- ne pas masquer une erreur avec un fallback trompeur ;
- ne pas hardcoder de secrets ;
- ne pas exposer de données personnelles dans les logs ;
- ne pas stocker une image publique par défaut ;
- ne pas inventer de prix, disponibilité ou qualification d’un artisan ;
- ne pas annoncer qu’un diagnostic est certain ;
- ne pas implémenter une fonctionnalité hors scope sans validation.

## 6. Contrat du moteur IA

Toute analyse doit produire une structure machine exploitable. Voir docs/AI_ENGINE.md.

Le moteur doit distinguer :
- observations visibles ;
- hypothèses ;
- informations manquantes ;
- risque ;
- action suivante ;
- conditions d’arrêt.

L’UI ne doit pas afficher une valeur de confiance brute comme une vérité scientifique. Elle sert surtout à la logique interne.

## 7. Definition of Done

Une fonctionnalité est terminée seulement si :
- parcours heureux fonctionnel ;
- erreurs gérées ;
- état loading/empty/error prévu ;
- sécurité évaluée ;
- analytics essentiels prévus ;
- tests pertinents passent ;
- aucune donnée sensible inutilement exposée ;
- documentation mise à jour si le comportement produit change.

## 8. Source de vérité documentaire

Ordre :
1. SKILL.md
2. docs/SAFETY.md pour toute question de sécurité
3. docs/PRODUCT.md
4. docs/UX_UI.md
5. docs/AI_ENGINE.md
6. autres documents spécialisés

En cas de contradiction, ne pas improviser : signaler la contradiction avant une modification importante.
