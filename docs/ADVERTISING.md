# Publicité NALVIUM — configuration contrôlée

- La publicité est désactivée par défaut via `NALVIUM_ADS_ENABLED=false`.
- En développement, seuls les IDs de test Google officiels sont utilisés.
- App Open, interstitiel et rewarded sont préparés derrière `AdsService` et ne sont jamais appelés dans Diagnostic, Safety, Assistant actif, guidage ou dossier professionnel.
- UMP gère la demande de consentement uniquement lorsque la publicité est explicitement activée.
- Production exige `--dart-define=NALVIUM_ADS_ENABLED=true`, `NALVIUM_ENV=production`, les trois ad unit IDs et un App ID AdMob de release injecté via `-P ADMOB_APP_ID=...`.
- Aucun vrai ad unit ID ne doit être utilisé dans les tests automatisés ou sur l’environnement de développement.

Les valeurs de production ne sont pas présentes dans le dépôt.
