# Catalogue et tarification

Les catégories, offres, zones et prix sont créés par le dashboard. La base ne contient aucun faux tarif actif par défaut.

Types supportés :

- `FIXED` : prix fixe ;
- `STARTING_FROM` : prix à partir de ;
- `RANGE` : fourchette ;
- `QUOTE_REQUIRED` : sur devis.

Les montants sont stockés en centimes avec devise, jamais supposés dans Flutter. Les majorations doivent être exposées avant confirmation lorsqu’elles seront ajoutées. Aucun paiement, encaissement, commission ou achat n’est implémenté dans ce lot.

Toute tarification et toute relation utilisateur/professionnel nécessitent une validation juridique et opérationnelle avant lancement.
