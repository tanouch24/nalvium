# Moteur SEO local France

## Principe

Le moteur sépare le référentiel communal, le registre des problèmes et le rendu Next.js.
Une commune est identifiée par son code officiel géographique Insee (`inseeCode`), jamais par son nom ou son slug seul.

Le catalogue complet est dans `data/france/catalog.json`. Il contient les 34 875 communes `COM` du COG 2026. Les sept communes historiques — Lyon, Nice, Villeurbanne, Bron, Vénissieux, Saint-Priest et Caluire-et-Cuire — restent `seoStatus: "full"`; les 34 868 autres communes sont `seoStatus: "hub"` sans problème local activé. Les codes, départements et régions viennent des fichiers COG officiels ; aucune population n’est importée et aucun voisinage n’est inventé.

Le registre des problèmes est dans le même catalogue. Les trois intentions Métropole V1 sont obligatoires : `fuite-eau`, `wc-bouche` et `canalisation-bouchee`. Les autres problèmes déjà publiés à Lyon sont conservés pour ne pas changer leurs URLs.

## Publication

Chaque commune possède un `seoStatus` :

- `disabled` : aucune route indexable ni entrée sitemap ;
- `hub` : hub national uniquement, rendu à la demande ;
- `full` : hub et problèmes listés dans `activeProblems`.

L’import national active explicitement tous les `COM` en `hub` et préserve les sept `full`. Les problèmes restent toujours opt-in : une commune `hub` ne génère aucune page problème.

## Homonymes

Le code Insee reste l’identifiant stable. Le slug de base peut être partagé, mais deux communes homonymes doivent avoir des `urlSlug` distincts, par exemple `saint-priest` et `saint-priest-07`. Le suffixe département est lisible, stable et contrôlé par le quality gate. Les URLs déjà publiées ne doivent pas être renommées.

`data/france/published-url-history.json` verrouille les slugs historiques par code Insee. Lors d’un import, cette table prime sur le slug généré et sur l’ancienne valeur du catalogue : une commune déjà publiée conserve son URL, tandis que les nouvelles communes homonymes reçoivent la désambiguïsation départementale ou INSEE.

## Overrides éditoriaux

`app/data/france/overrides.ts` fournit la couche `default template → city override → city/problem override`.
Les contenus actuels conservent leurs sources éditoriales existantes (`legacy-lyon`, `legacy-nice`, `metro-data`). Une future ville pourra recevoir une introduction, une FAQ, une image, des métadonnées ou un maillage propres sans copier le composant.

## Quality gate

Le quality gate de `app/data/france/quality-gate.ts` vérifie notamment :

- codes Insee et identifiants uniques ;
- statuts et problèmes activés cohérents ;
- collisions de slugs ;
- registre de problème complet ;
- absence de déclarations professionnelles ou locales non sourcées.

`assertLocalPageQuality` est prévu pour les contrôles de contenu rendus : title, description, H1, canonical NALVIUM, sécurité, CTA et liens utiles.

Les tests `tests/local-seo-engine.test.js` vérifient l’inventaire publié, les 35 URLs actuelles, les collisions et les champs interdits.

## Sitemap et performance

`app/sitemap.xml/route.ts` expose un index XML compatible avec `/sitemap.xml`. Il référence `general.xml`, les lots `local-hubs-*.xml` et `local-problems-*.xml`, servis par `app/sitemaps/[segment]/route.ts`. Chaque lot reste sous la limite prudente de 45 000 URLs. Les 34 875 hubs sont dans un lot et les 28 problèmes historiques dans un autre.

Le moteur pré-rend seulement les sept communes `full` et leurs 28 problèmes historiques. Les autres hubs utilisent le rendu dynamique/ISR à la demande (`revalidate: 3600`) : ils ne sont pas envoyés dans `generateStaticParams`. Le runtime utilise des maps `urlSlug → commune` ; le catalogue compact publié fait environ 21 MB côté serveur et n’est jamais envoyé au navigateur comme payload de catalogue. Le rapport d’import est écrit dans `data/insee/cog-2026/import-report.json`.

## Source communes France

Source maître : [INSEE — Code officiel géographique au 1er janvier 2026](https://www.insee.fr/fr/information/8740222), millésime 2026, fichiers CSV UTF-8 :

- `data/insee/cog-2026/v_commune_2026.csv` : communes, communes associées, communes déléguées et arrondissements municipaux ;
- `data/insee/cog-2026/v_departement_2026.csv` : rattachement et libellé officiel des départements ;
- `data/insee/cog-2026/v_region_2026.csv` : libellé officiel des régions.

Le script reproductible est `scripts/import-insee-cog.mjs`. Il valide les colonnes, importe seulement `TYPECOM=COM`, conserve les compteurs `COMA`, `COMD` et `ARM`, détecte les homonymes et préserve les statuts éditoriaux existants par `inseeCode`. Il n’importe ni population ni voisins. Le rapport détaille aussi la couverture métropolitaine et ultramarine du fichier source.

Pour refaire l’import au COG 2027 :

1. télécharger depuis la page COG officielle les trois fichiers `v_commune_2027.csv`, `v_departement_2027.csv` et `v_region_2027.csv` dans un nouveau dossier millésimé ;
2. adapter les constantes de millésime/source du script, ou fournir `--input`, `--departments`, `--regions`, `--output` et `--report` ;
3. lancer `node scripts/import-insee-cog.mjs --existing data/france/catalog.json` ;
4. inspecter le rapport, les collisions et la liste des communes actives ;
5. exécuter les tests et ne modifier `seoStatus` qu’après une revue éditoriale explicite.

Les codes `2A` et `2B` sont acceptés pour la Corse. Le fichier principal des communes couvre la métropole et les départements/régions d’outre-mer présents dans le COG ; les autres collectivités et territoires ultramarins nécessitent un traitement géographique dédié et ne sont pas activés automatiquement.

## Ajouter une ville SEO

1. Importer une commune depuis un référentiel Insee validé et conserver son `inseeCode`.
2. Vérifier les collisions de nom et définir un `urlSlug` stable.
3. Ajouter la commune au catalogue avec `seoStatus: "hub"` ou `"full"` ; l’import national utilise `hub` par défaut et seules les villes éditorialement couvertes passent en `full`.
4. Activer uniquement les problèmes réellement couverts.
5. Ajouter les overrides éditoriaux et les sources locales vérifiables.
6. Lancer `npm test`, le quality gate et les tests de routes.
7. Vérifier canonicales, maillage, sécurité, sitemap et rendu mobile.
8. Publier uniquement après revue humaine du contenu.

La présence dans le COG peut rendre un hub national disponible uniquement lorsqu’une politique de publication l’autorise. Les pages problème restent explicitement activées et le quality gate doit être exécuté avant toute extension éditoriale.
