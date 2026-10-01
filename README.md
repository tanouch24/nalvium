# NALVIUM

NALVIUM est un assistant intelligent de dépannage domestique : **montrez le problème, Nalvium vous guide**. V1 locale en français, gratuite pour les particuliers, avec priorité à la sécurité et une seule action à la fois.

## Architecture

- `app/` : Flutter Android/iOS, onboarding, caméra/galerie, preview, upload, analyse, guidage, résolution, historique local et safety stop.
- `backend/` : FastAPI/Pydantic, sessions invitées, PostgreSQL avec fallback mémoire explicite, provider IA OpenAI/mock, safety pré/post, médias privés et leads.
- `website/` : site public SEO statique rapide, pages problème et locale, metadata, canonical, robots, sitemap et maillage interne.
- `dashboard/` : console locale d'administration sobre pour métriques, leads et professionnels.
- `infra/` : PostgreSQL local via Docker Compose.

Le contrat IA sépare observations, hypothèses, risques et prochaine action. Le provider réel n'est jamais appelé depuis Flutter. L'implémentation locale utilise `MockMultimodalProvider` tant que `NALVIUM_AI_PROVIDER` n'est pas remplacé.

## Prérequis

Python 3.11+, Flutter/Dart, Node.js 20+, npm et Docker si PostgreSQL est nécessaire.

## Lancement

Backend : `cd backend && python3 -m venv .venv && source .venv/bin/activate && pip install -e '.[test]' && uvicorn app.main:app --reload --port 8000`.

Avec `OPENAI_API_KEY` absent, le backend utilise automatiquement le mock. Avec une clé présente, il utilise l'adaptateur OpenAI Responses API et les sorties structurées JSON Schema. La clé ne doit jamais être fournie à Flutter.

Base locale : `docker compose -f infra/docker-compose.yml up -d`, puis appliquer `backend/migrations/001_initial.sql` avec un outil de migration versionné avant usage PostgreSQL.

App : `cd app && flutter pub get && flutter run`.

Website : `cd website && npm start` (port 4173), ou `npm run generate` pour inspecter les pages indexables depuis `website/content/catalog.json`. Dashboard : `cd dashboard && npm start` (port 4174), puis saisir le token admin local dans l'interface.

Tests : `cd backend && python3 -m pytest -q`, `cd website && npm test`, `cd dashboard && npm test`, puis `cd app && flutter analyze && flutter test`.

## Configuration

Copier `backend/.env.example` pour le backend et `.env.example` à la racine. Ne jamais commiter de `.env` réel, clé IA ou token admin réel. Les informations juridiques NB Consulting, les fournisseurs cloud, le provider IA réel, la rétention et l'authentification dashboard restent à configurer avant publication (`TODO_PRODUCTION_CONFIGURATION`).

## Sécurité et confidentialité

Les règles déterministes de `backend/app/safety.py` arrêtent le DIY pour gaz, fumée, électricité exposée, eau proche d'électricité, chimie dangereuse, pression, risque structurel et fuite incontrôlable. Les médias sont enregistrés localement hors du dossier public, avec MIME et taille contrôlés. Un lead sans consentement explicite est refusé.

Cette version est un socle local de recette, pas un service de production : aucune transmission réelle de lead, aucune disponibilité artisan promise et aucun diagnostic professionnel garanti.
