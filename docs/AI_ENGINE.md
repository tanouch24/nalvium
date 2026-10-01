# NALVIUM — AI ENGINE

## Objectif

Transformer des observations multimodales en une progression sûre :
observer → clarifier → hypothèse → action sûre → vérifier → continuer/arrêter.

Le moteur n’est pas autorisé à inventer ce qu’il ne voit pas.

## Séparation fondamentale

Chaque analyse doit distinguer :

### observations
Faits réellement visibles ou explicitement fournis.

### hypotheses
Causes possibles, ordonnées et formulées comme hypothèses.

### missing_information
Ce qu’il faut encore savoir.

### risk
Risque détecté.

### next_action
Une seule prochaine action.

## Schéma indicatif

```json
{
  "category": "plumbing",
  "subcategory": "sink_leak",
  "observations": [
    "Humidité visible sous le siphon"
  ],
  "hypotheses": [
    {
      "label": "Joint ou raccord du siphon",
      "confidence": 0.78,
      "reason": "L'humidité semble concentrée près du raccord"
    }
  ],
  "missing_information": [
    "Origine exacte de la goutte"
  ],
  "risk": {
    "level": "low",
    "flags": [],
    "stop_diy": false
  },
  "urgency": "normal",
  "diy": {
    "allowed": true,
    "difficulty": "easy"
  },
  "next_action": {
    "type": "request_photo",
    "instruction": "Placez un récipient dessous puis prenez une photo rapprochée du raccord humide."
  }
}
```

## Valeurs contrôlées

risk.level :
- low
- moderate
- high
- emergency

urgency :
- normal
- soon
- urgent
- emergency

next_action.type :
- request_photo
- ask_question
- instruction
- verify
- safety_stop
- recommend_professional
- resolved

## Boucle de session

1. ingestion média/texte ;
2. pré-check sécurité ;
3. classification ;
4. extraction observations ;
5. hypothèses ;
6. besoin d’information ;
7. prochaine action ;
8. retour utilisateur ;
9. réévaluation complète ;
10. résolution ou escalade.

Ne jamais accumuler mécaniquement les anciennes hypothèses : une nouvelle photo peut les invalider.

## Instructions

Une instruction doit :
- être courte ;
- concerner une seule action ;
- indiquer une précaution avant l’action si nécessaire ;
- être vérifiable ;
- éviter les gestes irréversibles lorsque l’identification est incertaine.

## Incertitude

Si l’image est insuffisante :
« Je ne peux pas identifier ce point avec assez de fiabilité. Prenez une photo… »

Ne pas compenser l’incertitude par une réponse plus détaillée.

## Codes erreur / références

Lorsque l’utilisateur montre une référence :
- OCR/vision extrait marque/modèle/code ;
- backend peut consulter une base/documentation autorisée ;
- provenance des informations techniques doit être traçable côté serveur lorsque possible.

## Mémoire session

Conserver :
- problème initial ;
- médias ;
- réponses ;
- étapes proposées ;
- étapes confirmées ;
- hypothèses actives/infirmées ;
- événements sécurité ;
- résultat.

## Résumé professionnel

À la demande d’un pro, générer un résumé factuel :
- symptôme ;
- équipement identifié ;
- observations ;
- actions tentées ;
- résultat ;
- photos autorisées ;
- risque signalé.

Éviter les diagnostics catégoriques.
