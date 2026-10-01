# Réseau dépannage NALVIUM

Le flux national repose sur un catalogue et des zones administrés côté backend. Aucun métier, tarif, artisan ou code postal n’est codé dans Flutter.

Flux : service → code postal → couverture → description → médias explicitement sélectionnés → créneau → récapitulatif → consentement → demande.

`RepairRequest` est la source de vérité opérationnelle. Le `ProfessionalDossier` reste un dossier de contexte privé ; il peut alimenter une demande, mais ne constitue pas un deuxième système d’assignation.

États V1 : `REQUESTED`, `REVIEWING`, `ASSIGNED`, `APPOINTMENT_PROPOSED`, `APPOINTMENT_CONFIRMED`, `IN_PROGRESS`, `COMPLETED`, `CANCELLED`, `UNAVAILABLE`.

Une demande ne confirme jamais un artisan, un prix final ou un rendez-vous avant une action réelle du dashboard. Les zones non couvertes peuvent enregistrer un intérêt explicite, sans créer de demande assignable.

Les médias sont transmis uniquement après sélection explicite et consentement. Les documents, conversations, numéros de série et historiques complets restent exclus par défaut.
