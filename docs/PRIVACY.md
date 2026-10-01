# NALVIUM — PRIVACY / RGPD

Document produit/technique initial, à faire relire juridiquement avant lancement public.

## Principes

- minimisation ;
- finalité explicite ;
- consentement pour transmission à un professionnel ;
- suppression accessible ;
- sécurité par défaut ;
- médias privés.

## Données possibles

- photos/vidéos du problème ;
- texte/voix transcrite ;
- historique diagnostic ;
- téléphone/prénom pour lead ;
- ville/code postal ;
- données techniques app.

## Risque particulier des photos

Une photo domestique peut contenir :
- personnes ;
- documents ;
- adresse ;
- objets personnels.

L’app doit conseiller de cadrer uniquement le problème.
Prévoir suppression des métadonnées de localisation EXIF lorsque non nécessaires.

## Consentement artisan

Avant transmission, écran récapitulatif :
« Voici ce qui sera transmis : … »

Aucune transmission implicite parce que l’utilisateur a cliqué sur « Trouver un professionnel ».

## Droits

Prévoir techniquement :
- export si applicable ;
- suppression compte ;
- suppression historique/médias ;
- retrait de consentement lorsque pertinent.

## IA tierce

La politique publique doit expliquer les catégories de données envoyées au fournisseur IA et les garanties contractuelles retenues.

## Rétention

À définir avant prod avec besoins métier/juridiques.
Le code doit permettre des jobs de suppression.

## Analytics

Pas de contenu diagnostic complet dans un outil analytics tiers.
Événements avec identifiants pseudonymes et propriétés minimales.

## Contact

contact@nalvium.com
