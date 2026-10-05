# Sources des photographies NALVIUM

Les images ci-dessous ont été téléchargées localement depuis Unsplash le 1er octobre 2026, puis redimensionnées avec les paramètres `fit=crop`, largeur maximale adaptée au site et qualité JPEG raisonnable. Elles sont servies par `next/image` afin que Next.js génère les variantes adaptées aux écrans.

Unsplash autorise l’utilisation des images sous sa licence Unsplash. Les liens de recherche et les identifiants de photo sont conservés ici pour la traçabilité éditoriale. Les visuels ne constituent pas des preuves d’un diagnostic réel : ils illustrent uniquement des situations domestiques.

| Fichier local | Usage | Source |
| --- | --- | --- |
| `problems/leak-under-sink.jpg` | Hero, démo, contexte plomberie sous évier | [Unsplash photo `photo-1661044437435-8f6b5ed0d777`](https://unsplash.com/s/photos/plumbing-under-kitchen-sink) |
| `problems/clogged-sink.jpg` | Galerie, évier bouché | [Unsplash photo `photo-1772397546294-a2554a8a9793`](https://unsplash.com/s/photos/clogged-sink-water) |
| `problems/toilet-running.jpg` | Galerie, toilettes | [Yevhenii Deshko — Unsplash](https://unsplash.com/photos/a-white-toilet-sitting-in-a-bathroom-next-to-a-bath-tub-AZ2o9cBTjr8) |
| `problems/washing-machine.jpg` | Galerie, Ma Maison | [Sincerely Media — Unsplash](https://unsplash.com/photos/a-close-up-of-a-washing-machine-with-water-inside-CFrPAtWa2-M) |
| `problems/dishwasher.jpg` | Réserve éditoriale, lave-vaisselle | [Unsplash photo `photo-1620568400263-6f1cf95b9e30`](https://unsplash.com/s/photos/dishwasher-kitchen) |
| `problems/leaking-faucet.jpg` | Réserve éditoriale, robinet | [Jonathan Castañeda — Unsplash](https://unsplash.com/photos/a-faucet-that-is-sitting-on-a-sink-zWhWtMiu5ss) |
| `problems/oven.jpg` | Mur de situations, four | [Unsplash photo `photo-1565357253897-79d691886a73`](https://unsplash.com/s/photos/oven-not-heating) |
| `problems/refrigerator.jpg` | Mur de situations, réfrigérateur | [Unsplash photo `photo-1610733374054-59454fe657cd`](https://unsplash.com/s/photos/refrigerator-kitchen) |
| `problems/wall-mounting.jpg` | Mur de situations, bricolage | [Unsplash photo `photo-1594026112284-02bb6f3352fe`](https://unsplash.com/s/photos/wall-mounting-home) |
| `problems/electrical-outlet.jpg` | Mur de situations, observation électrique externe | [Unsplash photo `photo-1610056494071-9373f12bf769`](https://unsplash.com/s/photos/electrical-outlet-wall) |

Les assets des stores restent séparés dans `public/images/stores/`. Leurs URL d’application sont volontairement vides dans `app/data.ts` tant que les liens officiels NALVIUM ne sont pas fournis.

## Badges stores

- `stores/app-store-badge-fr.svg` : artwork Apple Inc. en français canadien (`FRCA`), conservé sans modification. [Consignes officielles Apple sur les badges localisés](https://developer.apple.com/app-store/marketing/guidelines/) et [fichier artwork original Apple référencé](https://commons.wikimedia.org/wiki/File:Download_on_the_App_Store_Badge_FRCA_RGB_blk.svg).
- `stores/google-play-badge-fr.png` : fichier PNG fourni par Google Play depuis l’URL officielle `https://play.google.com/intl/fr_fr/badges/static/images/badges/fr_badge_web_generic.png`. [Ressources officielles Google Play](https://play.google.com/intl/fr_fr/badges/).

Les badges sont affichés à leurs proportions natives. Ils restent visuellement désactivés tant qu’aucune URL d’application réelle n’est renseignée.
