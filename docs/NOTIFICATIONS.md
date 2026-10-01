# Notifications

Le backend possède un cycle de vie minimal des tokens appareil : enregistrement, réactivation, désinscription et association à l’identité d’installation. Un token n’est jamais une identité utilisateur.

Routes préparées : `/v1/device-tokens`.

FCM n’est pas activé dans cette version : aucun fichier Firebase privé, aucun envoi push et aucune dépendance Firebase n’ont été ajoutés. Les contenus futurs devront rester génériques sur écran verrouillé : « Votre demande de dépannage a été mise à jour. »

Les événements prévus sont : demande reçue, assignation, rendez-vous, modification, intervention terminée, diagnostic à reprendre, entretien, garantie et réponses Communauté.
