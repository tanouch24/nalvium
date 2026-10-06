import { photoAssets } from './data';

export type MetroCity = {
  slug: string;
  name: string;
  localContext: string;
  housingContext: string;
  firstObservation: string;
  faqAnswer: string;
};

export const metroCities: Record<string, MetroCity> = {
  villeurbanne: {
    slug: 'villeurbanne', name: 'Villeurbanne',
    localContext: 'Cette page concerne Villeurbanne, notamment des situations rencontrées dans un appartement, une maison ou un immeuble collectif.',
    housingContext: 'Dans un logement près de Charpennes, Gratte-Ciel ou Cusset, commencez par noter si le symptôme reste limité à votre équipement ou s’il touche une évacuation partagée.',
    firstObservation: 'À Villeurbanne, comparez l’équipement concerné avec les autres points d’eau avant d’ajouter de l’eau ou de forcer un raccord.',
    faqAnswer: 'La commune aide à situer le parcours, mais ne permet pas de conclure sur l’origine de la panne. Décrivez surtout ce qui est visible dans votre logement.'
  },
  bron: {
    slug: 'bron', name: 'Bron',
    localContext: 'Cette page concerne Bron et s’adresse aux particuliers qui veulent clarifier une fuite ou une évacuation avant de choisir la suite.',
    housingContext: 'Dans un appartement ou une maison à Bron, observez si l’eau apparaît pendant l’utilisation, au repos ou après un équipement situé à proximité.',
    firstObservation: 'À Bron, l’heure d’apparition et le premier point humide sont souvent plus utiles que le nom supposé de la panne.',
    faqAnswer: 'NALVIUM ne déduit pas une cause à partir de la commune. Les observations faites chez vous restent le point de départ.'
  },
  venissieux: {
    slug: 'venissieux', name: 'Vénissieux',
    localContext: 'Cette page concerne Vénissieux, pour une première orientation numérique avant une vérification ou l’intervention éventuelle d’un professionnel.',
    housingContext: 'Dans un logement à Vénissieux, vérifiez si le problème reste dans la cuisine ou la salle de bains, ou si plusieurs évacuations réagissent ensemble.',
    firstObservation: 'À Vénissieux, notez l’ordre dans lequel les équipements sont touchés : cela aide à distinguer un symptôme isolé d’une situation plus étendue.',
    faqAnswer: 'La commune n’est pas un diagnostic. NALVIUM vous aide à décrire le symptôme et à savoir quand arrêter les vérifications.'
  },
  'saint-priest': {
    slug: 'saint-priest', name: 'Saint-Priest',
    localContext: 'Cette page concerne Saint-Priest et propose un parcours local de compréhension, sans annoncer de dépannage ni de professionnel disponible.',
    housingContext: 'Dans une maison ou un immeuble à Saint-Priest, photographiez la zone avant de déplacer un appareil, une protection ou un meuble humide.',
    firstObservation: 'À Saint-Priest, distinguez d’abord un écoulement ralenti d’un refoulement : la prudence à adopter n’est pas la même.',
    faqAnswer: 'NALVIUM ne réalise pas d’intervention à Saint-Priest. La page sert à préparer une observation utile et une décision plus sûre.'
  },
  'caluire-et-cuire': {
    slug: 'caluire-et-cuire', name: 'Caluire-et-Cuire',
    localContext: 'Cette page concerne Caluire-et-Cuire, que le problème apparaisse dans un appartement, une maison ou un immeuble.',
    housingContext: 'À Caluire-et-Cuire, autour de Montessuy, Vassieux ou Bissardon, restez centré sur le point d’eau visible et les équipements qui réagissent en même temps.',
    firstObservation: 'À Caluire-et-Cuire, une photo de la zone et une chronologie simple valent mieux qu’un démontage effectué dans le doute.',
    faqAnswer: 'La localisation ne suffit pas à identifier une panne. NALVIUM fournit une orientation générale à partir de ce que vous observez réellement.'
  }
};

type LocalAngle = { heading: string; text: string; observations: string[]; question: string; answer: string };
export type MetroProblem = {
  slug: 'fuite-eau' | 'wc-bouche' | 'canalisation-bouchee';
  label: string;
  image: { src: string; alt: string };
  title: (city: MetroCity) => string;
  metaTitle: (city: MetroCity) => string;
  description: (city: MetroCity) => string;
  intro: string;
  quickAnswer: string;
  causes: string[];
  observations: string[];
  checks: string[];
  actions: string[];
  stop: string[];
  whenToCallPro: string;
  guides: string[];
  relatedProblems: string[];
  angles: Record<string, LocalAngle>;
};

export const metroProblems: Record<string, MetroProblem> = {
  'fuite-eau': {
    slug: 'fuite-eau', label: 'Fuite d’eau', image: photoAssets.leakUnderSink,
    title: city => `Fuite d’eau à ${city.name} : que faire avant d’appeler un plombier ?`,
    metaTitle: city => `Fuite d’eau à ${city.name} : vérifications sûres | NALVIUM`,
    description: city => `Fuite d’eau à ${city.name} : observez l’origine, distinguez les situations et sachez quand arrêter avant une intervention.`,
    intro: 'Une fuite visible, une humidité sans origine claire ou de l’eau près d’un équipement ne se traite pas de la même manière. Commencez par ce qui est accessible sans danger.',
    quickAnswer: 'Séchez uniquement une surface extérieure et observez le premier point humide, le moment où l’eau revient et l’équipement concerné. Si la fuite est importante ou proche de l’électricité, éloignez-vous et arrêtez les vérifications.',
    causes: ['Raccord, flexible ou joint visible', 'Fuite sous évier ou lavabo', 'Robinet, WC ou chauffe-eau voisin', 'Trace venant d’un point plus haut ou d’une origine non localisée'],
    observations: ['Fuite permanente ou seulement pendant l’utilisation', 'Eau sous évier, lavabo, WC, robinet ou chauffe-eau', 'Premier point humide et chemin suivi par l’eau', 'Eau proche d’une prise, d’un appareil ou d’un tableau'],
    checks: ['Placer un récipient stable seulement si la zone est sèche et accessible', 'Sécher l’extérieur puis regarder où l’humidité revient', 'Fermer l’arrivée si elle est identifiable et tourne sans forcer', 'Photographier avant de déplacer ou démonter quoi que ce soit'],
    actions: ['Noter l’heure et l’évolution du débit', 'Éloigner les objets secs sans toucher une zone électrique humide', 'Préparer les références visibles de l’équipement'],
    stop: ['Fuite importante ou impossible à contenir', 'Eau proche d’une installation électrique alimentée', 'Raccord fissuré, corrodé ou résistant', 'Besoin d’ouvrir, forcer ou déplacer un équipement lourd'],
    whenToCallPro: 'Un professionnel est préférable si l’origine reste incertaine, si la fuite augmente ou si un raccord, une cuve ou une canalisation cachée doit être examiné.',
    guides: ['fuite-sous-evier', 'fuite-sous-lavabo', 'robinet-qui-goutte', 'chauffe-eau-fuit'], relatedProblems: ['wc-bouche', 'canalisation-bouchee'],
    angles: {
      villeurbanne: { heading: 'Dans un immeuble ou un appartement à Villeurbanne', text: 'Commencez par distinguer une fuite dans votre équipement d’une humidité qui pourrait venir d’un logement voisin ou d’une partie commune.', observations: ['Trace sous un meuble ou au plafond', 'Variation après l’usage d’un voisin ou de votre propre équipement'], question: 'Une fuite à Villeurbanne vient-elle forcément de mon logement ?', answer: 'Non. Une trace peut venir d’un raccord, d’un équipement voisin ou d’un autre niveau. Documentez ce qui est visible sans ouvrir une paroi.' },
      bron: { heading: 'À Bron, commencer par la chronologie', text: 'Notez si la flaque apparaît au repos, au remplissage ou pendant l’évacuation : cette chronologie évite de confondre arrivée d’eau et refoulement.', observations: ['Moment précis d’apparition', 'Débit stable ou qui augmente'], question: 'Que noter avant de faire intervenir quelqu’un à Bron ?', answer: 'Le premier point humide, le moment d’apparition et l’évolution du débit sont plus utiles qu’une hypothèse sur la pièce défectueuse.' },
      venissieux: { heading: 'À Vénissieux, regarder les équipements voisins', text: 'Une fuite visible dans une cuisine ou une salle de bains peut descendre depuis un raccord voisin. Regardez autour sans démonter.', observations: ['Équipement voisin humide ou non', 'Eau claire, stagnante ou issue d’un refoulement'], question: 'Une humidité sans origine visible est-elle urgente ?', answer: 'Elle devient prioritaire si elle s’étend, approche l’électricité ou déforme un plafond. NALVIUM ne permet pas d’en confirmer la cause.' },
      'saint-priest': { heading: 'À Saint-Priest, protéger avant de chercher', text: 'Avant toute recherche, protégez le sol et les objets seulement si cela ne demande pas de toucher une zone humide ou un appareil alimenté.', observations: ['Sol et prises secs ou humides', 'Objets pouvant être éloignés sans risque'], question: 'Puis-je couper l’eau à Saint-Priest ?', answer: 'Seulement si la commande est clairement identifiable et se ferme sans forcer. Une fuite importante ou une zone électrique humide impose de s’arrêter.' },
      'caluire-et-cuire': { heading: 'À Caluire-et-Cuire, distinguer trace et origine', text: 'Une trace d’eau peut se déplacer avant d’apparaître. Photographiez la zone et cherchez le point de première humidité sans percer ni démonter.', observations: ['Trace la plus haute et zone où l’eau finit', 'Apparition après robinet, chasse ou évacuation'], question: 'Une photo suffit-elle pour trouver une fuite ?', answer: 'Elle aide à préparer l’observation, mais ne prouve pas l’origine. Une fuite cachée ou située plus haut doit être examinée avec prudence.' }
    }
  },
  'wc-bouche': {
    slug: 'wc-bouche', label: 'WC bouché', image: photoAssets.toilet,
    title: city => `WC bouché à ${city.name} : que vérifier avant une intervention ?`, metaTitle: city => `WC bouché à ${city.name} : vérifications sûres | NALVIUM`, description: city => `WC bouché à ${city.name} : distinguez eau qui monte, évacuation lente et problème plus général sans mélange chimique.`,
    intro: 'Le niveau de la cuvette, sa vitesse de baisse et les autres évacuations permettent de décrire la situation avant de tenter quoi que ce soit.', quickAnswer: 'N’ajoutez pas d’eau si le niveau monte et arrêtez la chasse. Observez si le WC seul est touché, si l’eau redescend lentement ou si douche et lavabo réagissent aussi.',
    causes: ['Bouchon local dans la cuvette ou sa sortie', 'Évacuation partiellement ralentie', 'Obstruction plus loin si plusieurs équipements sont concernés', 'Produit chimique déjà présent rendant toute manipulation dangereuse'],
    observations: ['Eau qui monte puis redescend ou reste haute', 'Évacuation lente après la chasse', 'WC seul ou plusieurs évacuations touchées', 'Glouglou, odeur inhabituelle ou refoulement'], checks: ['Ne pas relancer la chasse si le niveau monte', 'Fermer l’arrivée seulement si elle est accessible sans forcer', 'Observer douche, lavabo et évier sans ajouter d’eau', 'Vérifier si un produit a déjà été versé'], actions: ['Ventouse uniquement sans produit chimique et avec niveau maîtrisable', 'Photographier le niveau sans toucher l’eau', 'Noter l’ordre d’apparition des symptômes'], stop: ['Eau qui déborde ou refoulement important', 'Eau potentiellement contaminée', 'Plusieurs évacuations touchées', 'Produit chimique présent ou besoin de démonter'], whenToCallPro: 'Une aide professionnelle est préférable si le niveau ne baisse pas, si plusieurs équipements refoulent ou si le bouchon revient rapidement.', guides: ['wc-qui-remonte', 'wc-se-vide-lentement', 'canalisation-qui-glougloute', 'chasse-eau-qui-coule'], relatedProblems: ['fuite-eau', 'canalisation-bouchee'],
    angles: {
      villeurbanne: { heading: 'À Villeurbanne, comparer WC et salle de bains', text: 'Dans un immeuble, vérifiez si douche ou lavabo ralentissent également, sans multiplier les chasses pour tester.', observations: ['WC seul ou salle de bains entière', 'Niveau qui baisse entre deux utilisations'], question: 'Si seul le WC est bouché à Villeurbanne, est-ce forcément local ?', answer: 'Cela peut orienter vers le WC, mais ne confirme pas la cause. N’ajoutez pas d’eau si le niveau monte.' },
      bron: { heading: 'À Bron, éviter le débordement d’abord', text: 'Avant toute tentative, protégez le sol et repérez si le niveau reste haut. Une cuvette qui redescend lentement ne doit pas être testée par plusieurs chasses.', observations: ['Niveau stable ou en baisse', 'Chasse interrompue ou répétée'], question: 'Faut-il tirer une seconde fois la chasse à Bron ?', answer: 'Non si l’eau monte ou redescend mal. Limitez l’eau et observez les autres évacuations.' },
      venissieux: { heading: 'À Vénissieux, noter les refoulements associés', text: 'Un WC qui réagit avec la douche ou le lavabo donne un contexte différent d’une cuvette seule. Ne touchez pas à une eau potentiellement contaminée.', observations: ['Refoulement dans douche ou lavabo', 'Odeur ou eau trouble'], question: 'Que signifie un WC et une douche touchés à Vénissieux ?', answer: 'Cela peut signaler une évacuation plus générale. Arrêtez les essais et demandez une aide professionnelle.' },
      'saint-priest': { heading: 'À Saint-Priest, ne pas mélanger de produits', text: 'Si un déboucheur a déjà été versé, ne plongez pas les mains et ne tentez pas une ventouse : signalez-le avant toute intervention.', observations: ['Produit utilisé ou inconnu', 'Gants et protection disponibles sans contact avec l’eau'], question: 'Puis-je utiliser un déboucheur pour un WC bouché à Saint-Priest ?', answer: 'NALVIUM ne conseille pas les mélanges chimiques. Un produit déjà présent change la sécurité à adopter.' },
      'caluire-et-cuire': { heading: 'À Caluire-et-Cuire, distinguer lenteur et refoulement', text: 'Une baisse lente du niveau et une eau qui revient dans un autre équipement ne décrivent pas la même situation.', observations: ['Lenteur simple ou retour d’eau', 'Autre point d’évacuation concerné'], question: 'Quand arrêter pour un WC bouché à Caluire-et-Cuire ?', answer: 'Arrêtez dès qu’il y a débordement, refoulement, produit chimique ou plusieurs évacuations touchées.' }
    }
  },
  'canalisation-bouchee': {
    slug: 'canalisation-bouchee', label: 'Canalisation bouchée', image: photoAssets.cloggedSink,
    title: city => `Canalisation bouchée à ${city.name} : comprendre où se situe le problème`, metaTitle: city => `Canalisation bouchée à ${city.name} : problème local ou général ? | NALVIUM`, description: city => `Canalisation bouchée à ${city.name} : comparez évier, lavabo, douche, WC, odeurs, glouglous et refoulements avant d’agir.`,
    intro: 'La différence entre un seul équipement ralenti et plusieurs évacuations touchées change la prudence à adopter. NALVIUM aide à trier les signes, pas à effectuer un débouchage professionnel.', quickAnswer: 'Notez quels équipements sont concernés et dans quel ordre. Un évier seul ne se décrit pas comme un refoulement dans la douche et le WC ; limitez l’eau si plusieurs points réagissent.',
    causes: ['Bouchon près d’un évier, lavabo ou douche', 'Branche commune ralentie', 'Obstruction plus loin dans l’évacuation', 'Refoulement ou eau potentiellement contaminée'], observations: ['Évier, lavabo, douche ou WC seuls', 'Plusieurs évacuations touchées', 'Glouglous ou mauvaises odeurs', 'Refoulement et évolution du niveau'], checks: ['Ne pas verser beaucoup d’eau pour tester', 'Noter l’ordre des équipements concernés', 'Retirer seulement les débris visibles d’une bonde', 'Vérifier si un produit chimique a été utilisé'], actions: ['Photographier un niveau ou un refoulement sans toucher l’eau', 'Comparer les équipements au repos', 'Préparer une chronologie simple pour un professionnel'], stop: ['Refoulement d’eau usée', 'Débordement ou risque sanitaire', 'Plusieurs équipements touchés', 'Produit chimique présent ou raccord qui résiste'], whenToCallPro: 'Un professionnel est indiqué si plusieurs branches sont concernées, si le refoulement revient ou si l’accès nécessite démontage ou outil.', guides: ['canalisation-qui-glougloute', 'mauvaise-odeur-canalisation', 'evier-se-vide-lentement', 'douche-se-vide-lentement', 'lavabo-se-vide-lentement'], relatedProblems: ['fuite-eau', 'wc-bouche'],
    angles: {
      villeurbanne: { heading: 'À Villeurbanne, cartographier les points d’eau', text: 'Faites une liste courte : évier, lavabo, douche ou WC. Le nombre de points touchés est plus utile qu’un essai supplémentaire.', observations: ['Un seul point ou plusieurs pièces', 'Ordre d’apparition dans le logement'], question: 'Plusieurs évacuations bouchées à Villeurbanne : que faire ?', answer: 'Limitez l’eau, notez les points touchés et arrêtez les essais. Cela peut concerner une branche plus générale sans le prouver.' },
      bron: { heading: 'À Bron, écouter sans provoquer', text: 'Un glouglou après l’utilisation d’un autre équipement est à noter, mais ne justifie pas de remplir les évacuations pour reproduire le bruit.', observations: ['Bruit après évier, douche ou WC', 'Écoulement ralenti ou normal'], question: 'Un glouglou indique-t-il une canalisation bouchée à Bron ?', answer: 'Pas forcément. Le bruit, la lenteur, l’odeur et le nombre d’équipements doivent être distingués.' },
      venissieux: { heading: 'À Vénissieux, distinguer eau propre et refoulement', text: 'Une eau stagnante claire près d’une bonde n’a pas le même niveau de risque qu’un refoulement chargé dans plusieurs équipements.', observations: ['Aspect de l’eau', 'Présence d’odeur ou de matières'], question: 'Que faire si une canalisation refoule à Vénissieux ?', answer: 'N’ajoutez plus d’eau, éloignez-vous d’une eau potentiellement contaminée et demandez une aide professionnelle.' },
      'saint-priest': { heading: 'À Saint-Priest, protéger les zones touchées', text: 'Si la douche, le lavabo et le WC sont concernés, protégez le sol sans toucher l’eau et évitez d’utiliser les évacuations.', observations: ['Sol ou murs exposés', 'Nombre de pièces concernées'], question: 'Puis-je continuer à utiliser un évier si la douche refoule à Saint-Priest ?', answer: 'Mieux vaut limiter l’eau : plusieurs équipements touchés peuvent indiquer une évacuation commune, sans diagnostic certain.' },
      'caluire-et-cuire': { heading: 'À Caluire-et-Cuire, regarder l’évolution', text: 'Un problème intermittent mérite une chronologie : après quel usage, à quelle vitesse et avec quel bruit le symptôme revient-il ?', observations: ['Symptôme ponctuel ou récurrent', 'Temps entre deux utilisations et retour du niveau'], question: 'Une canalisation peut-elle se déboucher seule à Caluire-et-Cuire ?', answer: 'Le niveau peut baisser temporairement, mais une récurrence, une odeur ou un refoulement justifient d’arrêter les essais et de demander conseil.' }
    }
  }
};

export const metroDetails: Record<string, Record<string, { title: string; paragraph: string; checks: string[]; handoff: string }>> = {
  villeurbanne: {
    'fuite-eau': { title: 'Le premier point humide à Villeurbanne', paragraph: 'Dans un immeuble ou un logement individuel, une trace sous meuble ne permet pas de choisir immédiatement une réparation. Comparez le point le plus haut, l’usage qui précède la fuite et les équipements voisins.', checks: ['Sécher une zone extérieure puis attendre sans relancer fortement l’eau', 'Comparer évier, lavabo et chauffe-eau si la trace se déplace', 'Conserver une photo avec l’heure d’observation'], handoff: 'Si la trace s’étend vers un autre niveau ou une prise, transmettez cette chronologie à un professionnel plutôt que de chercher derrière une paroi.' },
    'wc-bouche': { title: 'Le triage du WC à Villeurbanne', paragraph: 'Un WC seul qui baisse lentement ne se décrit pas comme un niveau qui revient dans la douche. Dans un immeuble, cette différence évite de provoquer un débordement collectif par des essais répétés.', checks: ['Attendre la baisse naturelle du niveau', 'Regarder la douche sans la remplir', 'Noter si le bruit apparaît après la chasse'], handoff: 'La présence d’un refoulement ou de plusieurs évacuations touchées doit faire arrêter les essais et être décrite précisément.' },
    'canalisation-bouchee': { title: 'Comparer les pièces avant de conclure à Villeurbanne', paragraph: 'La cuisine et la salle de bains peuvent donner des signes proches. Notez les pièces dans l’ordre, puis distinguez lenteur, odeur, glouglou et refoulement au lieu de parler d’un bouchon général sans observation.', checks: ['Faire une liste évier, lavabo, douche, WC', 'Ne pas verser d’eau pour reproduire le bruit', 'Photographier uniquement un refoulement accessible sans contact'], handoff: 'Plusieurs branches concernées ou une eau douteuse justifient une prise en charge professionnelle.' }
  },
  bron: {
    'fuite-eau': { title: 'La chronologie de la fuite à Bron', paragraph: 'À Bron, commencez par l’instant précis où l’eau apparaît : au repos, pendant le remplissage, après la chasse ou pendant l’évacuation. Cette chronologie sépare des scénarios qui se ressemblent visuellement.', checks: ['Noter l’heure et l’usage juste avant la trace', 'Comparer le débit après une courte attente', 'Ne pas retenir une fuite avec la main'], handoff: 'Une fuite qui augmente ou approche un équipement électrique sort du champ des essais domestiques.' },
    'wc-bouche': { title: 'Le niveau de cuvette comme repère à Bron', paragraph: 'Avant de penser au débouchage, regardez si l’eau reste haute, redescend par à-coups ou disparaît normalement. Une deuxième chasse ne fournit pas une information fiable si le niveau est déjà haut.', checks: ['Marquer mentalement le niveau sans toucher l’eau', 'Fermer l’arrivée seulement si elle est souple', 'Vérifier un éventuel produit déjà utilisé'], handoff: 'Un produit chimique ou un refoulement impose de signaler la situation et de ne pas utiliser de ventouse.' },
    'canalisation-bouchee': { title: 'Le bruit ne suffit pas à Bron', paragraph: 'Un glouglou isolé peut accompagner un écoulement perturbé sans prouver un bouchon. Ce sont l’évolution du débit, l’odeur et le nombre de points d’eau touchés qui donnent le contexte.', checks: ['Écouter sans faire couler plusieurs robinets', 'Comparer un point d’eau à la fois', 'Noter si le bruit suit une vidange'], handoff: 'Si le bruit devient refoulement ou ralentissement généralisé, arrêtez les tests.' }
  },
  venissieux: {
    'fuite-eau': { title: 'Fuite visible ou humidité diffuse à Vénissieux', paragraph: 'Dans une cuisine, une salle de bains ou près d’un plafond, l’endroit où l’eau finit peut être différent de son origine. Cherchez seulement la première trace accessible et gardez une distance avec l’électricité.', checks: ['Photographier la limite de la zone humide', 'Regarder au-dessus sans ouvrir ni percer', 'Éloigner un objet sec seulement si le sol l’est aussi'], handoff: 'Une humidité qui progresse ou traverse un plafond nécessite une intervention adaptée, pas une recherche derrière la paroi.' },
    'wc-bouche': { title: 'WC seul ou évacuations liées à Vénissieux', paragraph: 'Le WC est-il le seul point perturbé ? La douche et le lavabo apportent une information de triage, mais il ne faut pas remplir ces équipements pour vérifier.', checks: ['Observer les niveaux existants', 'Noter une odeur ou une eau trouble', 'Limiter toutes les chasses supplémentaires'], handoff: 'Un refoulement dans plusieurs pièces ou une eau contaminée doit être laissé à un professionnel.' },
    'canalisation-bouchee': { title: 'L’aspect de l’eau à Vénissieux', paragraph: 'Une eau claire qui stagne près d’une bonde et une eau chargée qui remonte ne présentent pas la même prudence. Décrivez l’aspect sans la toucher et évitez les produits.', checks: ['Regarder sans plonger les mains', 'Noter l’odeur et la couleur à distance', 'Fermer les usages d’eau non indispensables'], handoff: 'Une eau potentiellement contaminée, un débordement ou plusieurs pièces touchées justifient l’arrêt immédiat.' }
  },
  'saint-priest': {
    'fuite-eau': { title: 'Protéger la zone avant la recherche à Saint-Priest', paragraph: 'Avant de suivre une fuite, vérifiez que le sol, la prise et vos chaussures restent secs. Une protection posée dans une zone humide peut augmenter le risque au lieu de le réduire.', checks: ['Éloigner les objets sans toucher l’eau', 'Photographier avant de déplacer un meuble', 'Identifier visuellement une vanne sans la forcer'], handoff: 'Si la commande n’est pas identifiable ou si l’eau atteint l’électricité, éloignez-vous et demandez une aide professionnelle.' },
    'wc-bouche': { title: 'Produit chimique ou ventouse à Saint-Priest', paragraph: 'La première question n’est pas quel outil utiliser, mais si un produit a déjà été versé. Cette information change immédiatement les gestes autorisés.', checks: ['Demander si un déboucheur a été utilisé', 'Ne pas mélanger ni ajouter d’eau', 'Garder le visage et les mains éloignés de la cuvette'], handoff: 'Un produit inconnu, une projection ou un niveau qui déborde imposent de ne plus intervenir soi-même.' },
    'canalisation-bouchee': { title: 'Limiter l’eau dans plusieurs pièces à Saint-Priest', paragraph: 'Lorsque douche, lavabo et WC réagissent ensemble, chaque nouvel essai peut déplacer de l’eau vers une zone déjà fragile. La bonne information est la liste des points touchés, pas un test supplémentaire.', checks: ['Suspendre les usages d’eau non nécessaires', 'Protéger le sol sans contact avec l’eau', 'Noter la première pièce concernée'], handoff: 'Un refoulement ou un risque sanitaire nécessite un professionnel capable d’examiner la situation globale.' }
  },
  'caluire-et-cuire': {
    'fuite-eau': { title: 'Trace et origine à Caluire-et-Cuire', paragraph: 'Une trace peut descendre ou se déplacer avant d’être visible. À Caluire-et-Cuire comme ailleurs, la photo de la zone la plus haute et la chronologie sont plus sûres qu’un perçage ou un démontage.', checks: ['Photographier la zone avant séchage', 'Comparer avec l’usage du robinet ou de la chasse', 'Ne pas ouvrir plafond ou mur'], handoff: 'Une origine cachée, une trace qui s’étend ou une installation électrique proche appellent une intervention.' },
    'wc-bouche': { title: 'Lenteur ou retour d’eau à Caluire-et-Cuire', paragraph: 'Une cuvette qui baisse lentement laisse encore une marge d’observation ; une eau qui revient dans une douche ou un lavabo signale une situation différente à ne pas provoquer davantage.', checks: ['Observer le délai de baisse sans nouvelle chasse', 'Comparer les autres évacuations au repos', 'Noter un glouglou sans verser d’eau'], handoff: 'Arrêtez-vous dès qu’il y a retour d’eau, débordement, produit ou plusieurs équipements concernés.' },
    'canalisation-bouchee': { title: 'Une évolution parfois intermittente à Caluire-et-Cuire', paragraph: 'Un écoulement peut redevenir normal puis ralentir à nouveau. Notez les moments, l’équipement utilisé juste avant et la présence d’odeur : une amélioration temporaire ne confirme pas une résolution.', checks: ['Écrire une chronologie courte', 'Photographier le niveau avant qu’il ne redescende', 'Ne pas multiplier les essais de grande eau'], handoff: 'Une récurrence, un refoulement ou une odeur persistante doivent conduire à demander un avis professionnel.' }
  }
};
