# NALVIUM — ARCHITECTURE

## Monorepo cible

```text
nalvium/
  SKILL.md
  docs/
  app/
  backend/
  website/
  dashboard/
  infra/
```

## App

Flutter.
Modules :
- core
- camera
- diagnostics
- repair
- professionals
- history
- settings/privacy

Gestion d’état : choisir une solution standard et cohérente, documenter le choix.

## Backend

API stateless autant que possible.

Services :
- auth/session
- media
- diagnostics
- ai_orchestrator
- safety
- leads
- professionals
- analytics

## IA

Créer une interface fournisseur :

```text
MultimodalProvider
  analyze(...)
  continue_session(...)
  summarize_for_professional(...)
```

Le provider externe n’est jamais appelé directement depuis Flutter.

Le backend applique :
1. validation input ;
2. safety pre-check ;
3. prompt/version ;
4. parsing JSON strict ;
5. validation schéma ;
6. safety post-check ;
7. persistance ;
8. réponse app.

## Média

- bucket privé ;
- upload signé ;
- compression côté app raisonnable ;
- suppression ;
- pas d’URL publique permanente ;
- métadonnées EXIF sensibles supprimées si non nécessaires.

## Auth

V1 :
- démarrage invité ;
- création de compte facultative pour historique multi-appareil ;
- vérification téléphone uniquement lorsqu’un lead nécessite un contact, si retenu.

## Website public / SEO

Le site public `nalvium.com` est un composant V1 à part entière.

Objectifs :
- acquisition organique ;
- pages guides/problèmes ;
- pages métiers ;
- pages locales utiles ;
- conversion vers le diagnostic NALVIUM ou une demande de professionnel.

Le framework web doit supporter SSR/SSG, metadata par page, sitemap, canonical, robots, données structurées et excellentes performances. Le choix concret sera documenté avant implémentation.

Le contenu programmatique doit provenir de données structurées mais chaque URL indexable doit apporter une valeur propre. Ne pas publier automatiquement toutes les combinaisons ville × métier × problème.

Voir `SEO_WEBSITE.md`.

## Dashboard

Web :
- authentification admin/pro ;
- leads ;
- diagnostics anonymisés lorsque nécessaire ;
- professionnels ;
- statuts ;
- métriques.

## Environnements

- local
- staging
- production

Secrets séparés.
Aucune clé prod dans le repo.

## Observabilité

- logs structurés ;
- request id ;
- erreurs backend ;
- latence IA ;
- coûts IA ;
- pas de contenu image dans logs.

## Performance

Objectif UX :
- feedback immédiat après capture ;
- upload compressé ;
- affichage d’un état réel pendant analyse ;
- timeout/retry contrôlés.

## Déploiement

Choix fournisseur reporté. Ne pas lier le domaine ou pousser en production sans GO explicite.
