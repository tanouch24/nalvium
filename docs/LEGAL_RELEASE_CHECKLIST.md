# Checklist juridique et store — NALVIUM

## Documents

- READY — brouillon Politique de confidentialité : `docs/PRIVACY_POLICY.md`.
- READY — brouillon CGU : `docs/TERMS_OF_USE.md`.
- READY — règles Communauté : `docs/COMMUNITY_GUIDELINES.md`.
- À COMPLÉTER — mentions légales éditeur, adresse, société, registre, hébergeurs.
- À VALIDER JURIDIQUEMENT — bases légales, durées, transferts internationaux, sous-traitants et rédaction finale.

## Données et consentements

- READY — médias privés par défaut, publication communautaire volontaire.
- READY — consentements professionnel et Communauté séparés dans les parcours concernés.
- À COMPLÉTER — écran persistant de gestion analytics/publicité avec stockage backend des retraits.
- À COMPLÉTER — suppression de compte multi-appareil liée à une identité authentifiée.
- À VALIDER JURIDIQUEMENT — registre des traitements et durées de rétention.

## SDK réellement présents ou préparés

- READY — `google_mobile_ads` est intégré techniquement, mais les publicités restent désactivées par défaut et aucune publicité n’est affichée dans les parcours sensibles.
- READY — UMP est appelé uniquement si la publicité est explicitement activée par configuration.
- À COMPLÉTER — Firebase/Google Analytics, Crashlytics, FCM et Meta App Events ne sont pas configurés dans le projet Flutter actuel ; ne pas les déclarer comme intégrés avant ajout réel.
- À VALIDER JURIDIQUEMENT — déclarations Google Play Data Safety et Apple App Privacy après choix définitif des SDK.

## UGC

- READY — signalement, modération déterministe de base, suppression de son contenu, règles accessibles.
- À COMPLÉTER — mécanisme de support public confirmé et dashboard complet de modération.

## Stores

- À COMPLÉTER — URLs publiques confidentialité/CGU/règles.
- À COMPLÉTER — identité éditeur, support, classification, Data Safety, App Privacy, âge et notes de review.
- À VALIDER JURIDIQUEMENT — textes et déclarations finales avant soumission.
