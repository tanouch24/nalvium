# Moteur SEO local France

## Principe

Le moteur sépare le référentiel communal, le registre des problèmes et le rendu Next.js.
Une commune est identifiée par son code officiel géographique Insee (`inseeCode`), jamais par son nom ou son slug seul.

Le catalogue complet est dans `data/france/catalog.json`. Il contient les 34 875 communes `COM` du COG 2026. Les sept communes historiques — Lyon, Nice, Villeurbanne, Bron, Vénissieux, Saint-Priest et Caluire-et-Cuire — restent `seoStatus: "full"`; les 34 868 autres communes sont `seoStatus: "hub"` sans problème local activé. Les codes, départements et régions viennent des fichiers COG officiels ; aucune population n’est importée et aucun voisinage n’est inventé.

Le registre des problèmes est dans le même catalogue. Les trois intentions nationales sont disponibles pour chaque commune : `fuite-eau`, `wc-bouche` et `canalisation-bouchee`. Elles sont séparées de `activeProblems`, qui conserve les overrides et pages historiques supplémentaires sans transformer artificiellement une commune en `full`.

## Publication

Chaque commune possède un `seoStatus` :

- `disabled` : aucune route indexable ni entrée sitemap ;
- `hub` : hub et problèmes nationaux, rendus à la demande ;
- `full` : hub, problèmes nationaux et problèmes listés dans `activeProblems`.

L’import national active explicitement tous les `COM` en `hub` et préserve les sept `full`. Les trois problèmes nationaux sont une règle de couverture séparée ; les autres problèmes restent opt-in via `activeProblems`.

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

`app/sitemap.xml/route.ts` expose un index XML compatible avec `/sitemap.xml`. Il référence `general.xml`, les lots `local-hubs-*.xml` et `local-problems-*.xml`, servis par des routes XML dédiées. Chaque lot reste sous la limite prudente de 45 000 URLs. Les 34 875 hubs sont dans un lot ; les 104 634 URLs problème dédupliquées sont réparties en 45 000, 45 000 et 14 634 URLs.

Le moteur pré-rend seulement les sept communes `full` et leurs 28 problèmes historiques. Les problèmes nationaux sont contrôlés par `app/data/france/rollout.ts` et sont en `WAVE_0` par défaut : aucun problème national nouveau n’est ainsi accessible ou ajouté au sitemap. `TEST_WAVE` active localement Paris, Marseille, Toulouse, Bordeaux, Lille, Nantes, Montpellier et Strasbourg ; `ALL` active les 34 875 communes. Les autres hubs et problèmes nationaux utilisent le rendu dynamique/ISR à la demande (`revalidate: 3600`) : les 104 625 combinaisons nationales ne sont pas envoyées dans `generateStaticParams`. Le runtime utilise des maps `urlSlug → commune` ; le catalogue compact publié reste côté serveur et n’est jamais envoyé au navigateur comme payload de catalogue. Le rapport d’import est écrit dans `data/insee/cog-2026/import-report.json`.

## Rollout des problèmes nationaux

Le mode est sélectionné par `NALVIUM_PROBLEM_ROLLOUT` côté serveur. Une valeur absente signifie `WAVE_0`; une valeur inconnue provoque une erreur explicite et ne peut pas basculer silencieusement vers `ALL`. `TEST_WAVE` est réservé au développement. Les vagues population disponibles sont `WAVE_100`, `WAVE_500`, `WAVE_1000`, `WAVE_2500`, `WAVE_5000`, `WAVE_10000` et `ALL`. La production doit rester sur `WAVE_0` tant qu'une activation n'a pas été décidée.

## Population INSEE et vagues nationales

Le catalogue géographique utilise le COG INSEE 2026. Le classement interne utilise les populations de référence INSEE 2023, applicables au 1er janvier 2026. La source principale est le fichier `ensemble.zip / donnees_communes.csv` de la publication INSEE [Populations de référence 2023](https://www.insee.fr/fr/statistiques/8681011), téléchargée depuis la page officielle des fichiers [popref 2023](https://www.insee.fr/fr/statistiques/8680726). La jointure est exclusivement faite par `inseeCode`/`COM`.

Le COG contient 34 875 communes candidates. Le fichier principal contient 34 900 lignes : Paris, Marseille et Lyon sont représentées par des lignes d'arrondissements distinctes dans ce fichier, et les 17 communes de Mayotte sont absentes. Les 20 codes manquants sont complétés par des sources INSEE officielles explicites dans `data/insee/population-2023/communes-speciales.csv`. Mayotte conserve la population de référence 2017 publiée par l'INSEE ([source Mayotte](https://www.insee.fr/fr/statistiques/3291775)); elle n'est pas présentée comme une population 2023.

L'import reproductible est `node scripts/import-insee-population.mjs`. Il enrichit `data/france/catalog.json` et `app/data/france/published-catalog.json`, écrit `data/insee/population-2023/import-report.json` et `data/insee/population-2023/national-ranking.json`, et échoue si une commune COG reste sans population officielle ou si un code population est dupliqué. Pour un futur millésime, remplacer les fichiers source, mettre à jour les métadonnées de provenance et relancer ce script ; ne jamais joindre par nom.

Les vagues sont des préfixes du classement : `WAVE_100`, `WAVE_500`, `WAVE_1000`, `WAVE_2500`, `WAVE_5000`, `WAVE_10000`, puis `ALL`. Les sept communes historiques et leurs 28 URLs problème restent accessibles dans toutes les vagues. La population n'est pas affichée sur les pages publiques et le catalogue reste côté serveur.

Les URLs historiques restent autorisées dans tous les modes. Le sitemap appelle la même résolution que le routage, ce qui empêche une URL inactive d’être publiée dans le sitemap. Les tests de comptage sont dans `tests/problem-rollout.test.js` : WAVE_0 = 28 URLs problème, TEST_WAVE = 52, ALL = 104 634.

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
