# NALVIUM — Store release checklist

Document de préparation uniquement. Les réponses finales doivent être vérifiées sur le comportement réellement livré et validées juridiquement.

## Google Play — à vérifier avant soumission

- [ ] Identité de l’éditeur, coordonnées de support, politique de confidentialité publique et CGU finalisées.
- [ ] Data Safety : médias (photos/vidéos), audio/transcription si activés, diagnostics, contenu utilisateur, identifiants d’installation, analytics, crash reporting et publicité déclarés selon la version réellement publiée.
- [ ] AdMob : publicités désactivées par défaut dans la première release ; si activation ultérieure, App ID et Ad Unit IDs de production validés et consentement UMP vérifié.
- [ ] Aucun identifiant publicitaire réel dans les tests, fixtures ou builds de développement.
- [ ] Formulaire de suppression de compte/données opérationnel avant d’affirmer une suppression effective.
- [ ] UGC : règles accessibles, signalement, modération, suppression de son contenu et contact support testés.
- [ ] APK/AAB signé avec un keystore de release conservé hors Git. La configuration actuelle utilise encore le debug signing : BLOQUANT.
- [ ] `NALVIUM_API_URL` de release pointe vers un backend HTTPS réel ; le guard refuse localhost/LAN.
- [ ] Permissions caméra, microphone, photos/médias et notifications justifiées et minimisées.
- [ ] Fiche store, classification de contenu, captures réelles et notes de test préparées.
- [ ] Si le réseau dépannage est activé : couverture réellement administrée, consentement et absence de promesse de disponibilité/prix final vérifiés.

## Apple App Store — à vérifier avant soumission

- [ ] App Privacy remplie selon les SDK effectivement embarqués et les flux réels.
- [ ] Descriptions caméra, microphone, photos et notifications cohérentes avec l’usage.
- [ ] Sign in with Apple et autres fournisseurs d’identité seulement s’ils sont réellement configurés.
- [ ] ATT évaluée avec l’intégration publicitaire réellement activée ; aucune demande inutile dans la première release sans publicité.
- [ ] Privacy Policy URL, support URL et CGU finalisées.
- [ ] Bundle identifier, signatures, provisioning, icônes et captures validés.

## Statut technique actuel

- `google_mobile_ads` est intégré derrière flags ; App Open, interstitial et rewarded sont préparés mais aucune publicité n’est affichée par défaut.
- Firebase/Google Analytics, Meta App Events, Crashlytics et FCM ne sont pas intégrés dans cette version et ne doivent pas être déclarés comme tels.
- Les données légales éditeur, durées de conservation, bases juridiques, sous-traitants et URLs publiques restent à compléter/valider.
- [READY - V1] Les recherches de matériel sont externes, génériques et sans
  boutique, panier, paiement ou promesse de disponibilité.
