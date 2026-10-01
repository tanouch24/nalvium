# Signature Android release

L’AAB peut être compilé localement, mais la configuration actuelle ne doit pas être publiée : elle utilise encore le signing debug.

Avant Play Store :

1. créer ou récupérer le keystore release dans un coffre sécurisé ;
2. créer `app/android/key.properties` localement, jamais dans Git ;
3. ajouter `storeFile`, `storePassword`, `keyAlias` et `keyPassword` via variables protégées ;
4. modifier `app/android/app/build.gradle.kts` pour utiliser la signing release ;
5. vérifier que `.gitignore` exclut `key.properties`, `.jks`, `.keystore` et les mots de passe ;
6. produire l’AAB avec l’URL backend HTTPS et les IDs AdMob de l’environnement voulu ;
7. vérifier la signature avec `apksigner verify --verbose`.

NALVIUM ne génère, n’affiche et ne committe aucune clé privée.
