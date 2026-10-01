# NALVIUM App

Flutter Android/iOS V1. Le prototype local couvre onboarding, accueil, diagnostic mock, guidage une action à la fois, succès et safety stop. Aucune clé IA n'est embarquée.

## Test Android sur appareil réel

L'adresse `10.0.2.2` est réservée à l'émulateur Android. Pour tester sur un
téléphone connecté au même réseau que le backend local, lancer l'application
avec l'adresse LAN de l'ordinateur :

```sh
flutter run --dart-define=NALVIUM_API_URL=http://<IP_LAN_DU_PC>:8000
```

La galerie utilise le Photo Picker Android et ne nécessite pas de permission
de stockage. La permission caméra est demandée uniquement lors de la capture.
