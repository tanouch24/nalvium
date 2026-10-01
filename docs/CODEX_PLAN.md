# NALVIUM — PLAN CODEX

Codex doit lire SKILL.md avant chaque chantier.

## Prompt 0 — Audit de spécification
Lire tous les documents. Ne coder rien.
Produire :
- contradictions ;
- décisions techniques manquantes ;
- risques ;
- architecture proposée ;
- plan d’implémentation.
Attendre GO.

## Prompt 1 — Fondation monorepo
Créer app/backend/dashboard/infra.
Flutter + backend + PostgreSQL local + conventions + env examples + lint/tests.
Aucun cloud prod.

## Prompt 2 — Flutter UX foundation
Navigation, thème, onboarding, accueil, caméra/galerie, états permissions, composants communs.

## Prompt 3 — Backend sessions/media
Sessions invitées, upload média privé, schéma DB, migrations, endpoints, tests.

## Prompt 4 — AI orchestrator
Provider abstraction, schémas JSON, validation, prompts versionnés, mocks, safety pre/post checks.

## Prompt 5 — Diagnostic flow E2E
Photo → analyse → question → diagnostic/orientation dans app.

## Prompt 6 — Repair session
Étapes, confirmation, nouvelle photo, réévaluation, résolution/échec.

## Prompt 7 — Safety hardening
Implémenter et tester les règles SAFETY.md. Ajouter suite de régression.

## Prompt 8 — Leads
Consentement, coordonnées, résumé, création lead, sélection photos, statut.

## Prompt 9 — Dashboard
Admin + professionnels + leads + statuts + zones.

## Prompt 10 — Privacy/analytics
Suppression, rétention technique, analytics, logs, consentements.

## Prompt 11 — Recette Android
Build, permissions, erreurs, performance, tests E2E, corrections.

## Prompt 12 — Audit final
Sécurité, secrets, dépendances, tests, UX, DB, régressions. Aucun push/deploy sans GO.

## Format de rapport obligatoire après chaque prompt

- Résumé
- Fichiers créés/modifiés
- Commandes/tests exécutés
- Résultats
- Points non terminés
- Risques
- Git status
- Aucun push effectué
