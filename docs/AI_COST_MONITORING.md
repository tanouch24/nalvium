# Monitoring coût IA

`ai_usage_events` conserve uniquement des métriques techniques minimisées : provider, modèle, opération, tokens disponibles, nombre d’images/frames, durée audio, coût estimé et référence technique.

Le prompt, la réponse, les photos, l’audio, la transcription, les documents et les coordonnées ne sont pas enregistrés dans cette table.

Le coût est `estimated`, jamais une facture fournisseur. Les tarifs fournisseur ne sont pas codés en dur. Les appels de diagnostic sont comptabilisés sans interrompre le parcours si le monitoring échoue.

Les budgets `AI_DAILY_SOFT_BUDGET_EUR` et `AI_DAILY_HARD_BUDGET_EUR` sont réservés à une activation future : aucune valeur de production arbitraire n’est définie dans ce lot. Le safety engine reste prioritaire dans tout fallback.
