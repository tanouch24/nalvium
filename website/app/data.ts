export type Guide = {
  slug: string;
  category: string;
  categorySlug: string;
  title: string;
  metaTitle: string;
  metaDescription: string;
  intro: string;
  quickAnswer: string;
  causes: string[];
  observations: string[];
  safeChecks: string[];
  safeActions: string[];
  stopConditions: string[];
  whenToCallPro: string;
  faq: { question: string; answer: string }[];
  related: string[];
};

export const guides: Guide[] = [
  {
    slug: 'fuite-sous-evier', category: 'Plomberie', categorySlug: 'plomberie',
    title: 'Fuite sous évier : que vérifier sans prendre de risque ?',
    metaTitle: 'Fuite sous évier : vérifications sûres | NALVIUM',
    metaDescription: 'Une fuite sous évier ? Identifiez ce qui est visible, essayez une vérification simple et sachez quand arrêter pour appeler un professionnel.',
    intro: 'Une flaque sous l’évier ne permet pas, à elle seule, de connaître l’origine exacte de la fuite. Commencez par observer sans démonter.',
    quickAnswer: 'Placez un récipient sous la zone humide, séchez l’extérieur des raccords et observez d’où vient la première goutte lorsque l’eau coule. Si le débit est important ou si de l’eau approche une installation électrique, arrêtez-vous et mettez la zone en sécurité.',
    causes: ['Un raccord du siphon légèrement desserré', 'Un joint qui n’assure plus correctement l’étanchéité', 'Une fuite située plus haut, sur le robinet ou le flexible', 'Une évacuation qui refoule lorsque l’eau s’écoule'],
    observations: ['La zone exacte où apparaît la première goutte', 'Si la fuite arrive uniquement quand l’eau coule', 'La quantité d’eau et son évolution', 'La présence éventuelle d’une prise ou d’un appareil électrique à proximité'],
    safeChecks: ['Éloigner ce qui peut être endommagé sans toucher à une installation électrique humide', 'Placer un récipient stable sous la fuite', 'Essuyer l’extérieur puis regarder quel raccord redevient humide', 'Fermer l’arrivée d’eau uniquement si elle est accessible sans forcer'],
    safeActions: ['Photographier le raccord humide de près, sans mettre les mains dans l’eau', 'Resserrer très légèrement un raccord accessible uniquement s’il est manifestement desserré et sans outil', 'Faire couler un petit filet d’eau pour vérifier si la goutte réapparaît'],
    stopConditions: ['L’eau coule fortement ou ne peut pas être contenue', 'L’eau atteint une prise, une multiprise ou un appareil alimenté', 'Le raccord résiste, tourne dans le vide ou semble endommagé', 'Vous ne localisez pas la fuite avec assez de certitude'],
    whenToCallPro: 'Un plombier pourra identifier l’origine exacte, remplacer le joint ou le raccord adapté et vérifier que la fuite n’a pas endommagé le meuble. NALVIUM peut vous aider à préparer une demande claire, sans prétendre remplacer son diagnostic.',
    faq: [
      { question: 'Puis-je démonter le siphon ?', answer: 'Pas automatiquement. Commencez par localiser la fuite. Si l’eau est importante, si un appareil électrique est proche ou si vous n’êtes pas à l’aise, arrêtez-vous et demandez un professionnel.' },
      { question: 'Pourquoi la fuite apparaît-elle seulement quand l’eau coule ?', answer: 'Cela peut orienter vers un raccord d’évacuation ou une fuite qui se manifeste avec le débit. C’est une hypothèse à vérifier, pas une certitude.' },
      { question: 'NALVIUM peut-il envoyer un plombier ?', answer: 'L’application peut vous aider à préparer une demande. La transmission de vos coordonnées ou photos nécessite votre consentement explicite et aucun professionnel n’est affiché ici sans donnée réelle.' },
    ], related: ['robinet-qui-goutte', 'evier-bouche', 'chasse-eau-qui-coule'],
  },
  {
    slug: 'robinet-qui-goutte', category: 'Plomberie', categorySlug: 'plomberie', title: 'Robinet qui goutte : comprendre avant d’intervenir', metaTitle: 'Robinet qui goutte : premières vérifications | NALVIUM', metaDescription: 'Un robinet qui goutte ? Distinguez les observations utiles, les vérifications sans danger et les situations qui nécessitent un professionnel.', intro: 'Le point de fuite n’est pas toujours celui que l’on croit. Observez le robinet dans plusieurs positions avant de toucher à quoi que ce soit.', quickAnswer: 'Séchez le robinet, ouvrez puis fermez doucement l’eau et regardez si les gouttes viennent du bec, de la base ou d’un raccord. Ne forcez aucune poignée.', causes: ['Cartouche ou joint interne usé', 'Raccord ou flexible humide', 'Dépôt autour de l’aérateur', 'Pression ou commande qui ne ferme plus correctement'], observations: ['L’endroit précis des gouttes', 'Le moment où elles apparaissent', 'L’état visible des flexibles et raccords', 'La présence d’eau dans le meuble'], safeChecks: ['Sécher les surfaces visibles', 'Vérifier sans outil qu’un flexible ne bouge pas anormalement', 'Fermer l’eau si une fuite augmente et si l’accès est sûr'], safeActions: ['Prendre une photo de la base et des raccords', 'Nettoyer uniquement l’aérateur extérieur si le problème est clairement localisé là'], stopConditions: ['Fuite importante', 'Raccord corrodé ou déformé', 'Eau proche d’électricité', 'Poignée bloquée ou besoin de forcer'], whenToCallPro: 'Un professionnel est recommandé si le mécanisme interne doit être démonté ou si l’origine reste incertaine.', faq: [{ question: 'Est-ce forcément le joint ?', answer: 'Non. Une goutte peut venir d’un raccord, d’une cartouche ou d’une fuite située plus haut.' }], related: ['fuite-sous-evier', 'evier-bouche'],
  },
  {
    slug: 'chasse-eau-qui-coule', category: 'Plomberie', categorySlug: 'plomberie', title: 'Chasse d’eau qui coule : les vérifications sûres', metaTitle: 'Chasse d’eau qui coule : que vérifier ? | NALVIUM', metaDescription: 'Votre chasse d’eau coule en continu ? Voici ce que vous pouvez observer sans démontage dangereux et quand demander de l’aide.', intro: 'Une chasse d’eau qui coule peut être liée au flotteur, au clapet ou à un réglage. Commencez par écouter et observer.', quickAnswer: 'Retirez seulement le couvercle s’il se soulève sans forcer, puis observez si l’eau continue d’entrer ou passe dans la cuvette. Ne forcez pas un mécanisme bloqué.', causes: ['Clapet qui ne ferme plus complètement', 'Flotteur mal positionné ou entartré', 'Bouton ou mécanisme qui reste en tension', 'Fuite du réservoir vers la cuvette'], observations: ['Bruit d’arrivée d’eau', 'Filet d’eau dans la cuvette', 'Position du flotteur', 'Traces d’eau autour du réservoir'], safeChecks: ['Fermer le petit robinet d’arrivée si l’eau coule beaucoup et qu’il tourne normalement', 'Observer sans débrancher ni forcer le mécanisme', 'Vérifier si le bouton revient correctement'], safeActions: ['Prendre une photo du mécanisme visible', 'Nettoyer uniquement une surface accessible sans produit agressif'], stopConditions: ['Robinet d’arrêt bloqué', 'Fuite à l’extérieur du réservoir', 'Réservoir fissuré', 'Besoin de forcer ou de démonter'], whenToCallPro: 'Un plombier peut remplacer le mécanisme adapté et vérifier l’étanchéité du réservoir.', faq: [{ question: 'Puis-je régler le flotteur ?', answer: 'Seulement si le réglage est clairement accessible et prévu pour cela. Ne forcez pas une pièce et arrêtez si vous n’identifiez pas le mécanisme.' }], related: ['fuite-sous-evier', 'evier-bouche'],
  },
  {
    slug: 'evier-bouche', category: 'Plomberie', categorySlug: 'plomberie', title: 'Évier bouché : quoi essayer sans mélanger de produits ?', metaTitle: 'Évier bouché : vérifications et gestes sûrs | NALVIUM', metaDescription: 'Évier bouché ou qui s’écoule lentement : observez, évitez les mélanges chimiques et sachez quand appeler un professionnel.', intro: 'Un évier qui s’écoule mal peut être obstrué près de la bonde ou plus loin dans l’évacuation. La sécurité passe avant le débouchage.', quickAnswer: 'Retirez les débris visibles avec des gants adaptés, limitez l’eau ajoutée et n’utilisez jamais plusieurs produits déboucheurs ensemble. Si un produit chimique est déjà présent, ne démontez pas.', causes: ['Débris près de la bonde', 'Siphon encombré', 'Bouchon plus loin dans l’évacuation', 'Accumulation de graisse ou de résidus'], observations: ['Vitesse d’écoulement', 'Refoulement ou non', 'Présence d’un produit chimique', 'Évolution après une petite quantité d’eau'], safeChecks: ['Éviter tout mélange de produits', 'Retirer uniquement les débris visibles', 'Protéger le sol et limiter le volume d’eau'], safeActions: ['Utiliser une ventouse adaptée uniquement si aucun produit chimique n’a été versé', 'Photographier la bonde et le dessous de l’évier'], stopConditions: ['Produit chimique présent ou inconnu', 'Refoulement important', 'Fuite du siphon', 'Plusieurs évacuations touchées'], whenToCallPro: 'Un professionnel est préférable si le bouchon est profond, récurrent ou si un produit chimique est impliqué.', faq: [{ question: 'Puis-je mélanger vinaigre et déboucheur ?', answer: 'Non. Ne mélangez jamais des produits ménagers ou déboucheurs.' }], related: ['fuite-sous-evier', 'robinet-qui-goutte'],
  },
  ...(['machine-a-laver-qui-fuit','lave-linge-ne-vidange-plus','lave-vaisselle-ne-vidange-plus','eau-au-fond-du-lave-vaisselle','four-ne-chauffe-plus','refrigerateur-ne-refroidit-plus'].map((slug) => ({ slug, category: 'Électroménager', categorySlug: 'electromenager', title: slug === 'machine-a-laver-qui-fuit' ? 'Machine à laver qui fuit : les premières observations' : slug.replaceAll('-', ' ').replace(/\b\w/g, c => c.toUpperCase()), metaTitle: 'Problème électroménager : comprendre avant d’agir | NALVIUM', metaDescription: 'Comprenez les premières vérifications sûres pour votre appareil électroménager, sans démontage ni promesse de diagnostic certain.', intro: 'Avant de chercher une pièce, observez le symptôme, la référence de l’appareil et les conditions dans lesquelles il apparaît.', quickAnswer: 'Débranchez l’appareil uniquement si cela est possible sans toucher une zone humide ou dangereuse. Photographiez le modèle et le symptôme visible. Ne démontez pas un appareil sous tension.', causes: ['Filtre ou évacuation encombré', 'Joint ou flexible visible', 'Programme ou code erreur', 'Panne nécessitant un professionnel'], observations: ['Code ou voyant affiché', 'Moment où le problème apparaît', 'Bruit, odeur ou chaleur anormale', 'Référence exacte de l’appareil'], safeChecks: ['Lire la notice si elle est disponible', 'Photographier l’étiquette et le code erreur', 'Éloigner l’eau des prises sans toucher à une installation mouillée'], safeActions: ['Vérifier uniquement les éléments explicitement accessibles dans la notice', 'Attendre le refroidissement complet avant toute observation extérieure'], stopConditions: ['Fumée, odeur de brûlé ou choc électrique', 'Eau proche d’une prise alimentée', 'Composant interne, condensateur ou zone haute tension', 'Besoin de contourner une sécurité'], whenToCallPro: 'Un réparateur est recommandé dès que l’action dépasse une vérification prévue par la notice ou qu’un risque apparaît.', faq: [{ question: 'Puis-je démonter le capot ?', answer: 'Pas pour une première vérification. Un appareil doit être hors tension et certains composants restent dangereux. Demandez l’avis d’un professionnel.' }], related: ['fuite-sous-evier'], } as Guide))),
];

export const guideBySlug = Object.fromEntries(guides.map((guide) => [guide.slug, guide])) as Record<string, Guide>;
export const categories = [
  { slug: 'plomberie', label: 'Plomberie', description: 'Fuites, évacuations, robinetterie et WC : comprendre le symptôme avant d’agir.' },
  { slug: 'electromenager', label: 'Électroménager', description: 'Lave-linge, lave-vaisselle, four et réfrigérateur : observer sans démontage risqué.' },
  { slug: 'bricolage', label: 'Bricolage', description: 'Petites fixations et objets du quotidien, avec une limite claire quand le risque change.' },
  { slug: 'electricite', label: 'Électricité', description: 'Identifier et mettre en sécurité. Aucune intervention sur conducteurs ou tableau.' },
];

export const cities = {
  nice: { name: 'Nice', department: 'Alpes-Maritimes', intro: 'Si vous cherchez un plombier à Nice, NALVIUM peut d’abord vous aider à identifier ce qui se passe chez vous, gratuitement.', problems: ['Fuite sous évier', 'Robinet qui goutte', 'Chasse d’eau qui coule', 'Évier bouché'] },
  lyon: { name: 'Lyon', department: 'Rhône', intro: 'Une recherche de plombier à Lyon commence parfois par une question plus simple : quel est exactement le problème à montrer ?', problems: ['Fuite sous évier', 'Évier bouché', 'Robinet qui goutte', 'Chasse d’eau qui coule'] },
};

export const storeLinks = { appStoreUrl: '', googlePlayUrl: '' };

export const photoAssets = {
  leakUnderSink: { src: '/images/problems/leak-under-sink.jpg', alt: 'Vue réelle sous un évier, avec une personne qui vérifie le raccord du siphon' },
  cloggedSink: { src: '/images/problems/clogged-sink.jpg', alt: 'Évier de cuisine avec de l’eau stagnante autour de la bonde' },
  toilet: { src: '/images/problems/toilet-running.jpg', alt: 'Toilettes dans une salle de bains domestique' },
  washingMachine: { src: '/images/problems/washing-machine.jpg', alt: 'Lave-linge installé dans une buanderie domestique' },
  dishwasher: { src: '/images/problems/dishwasher.jpg', alt: 'Lave-vaisselle ouvert dans une cuisine' },
  leakingFaucet: { src: '/images/problems/leaking-faucet.jpg', alt: 'Robinet de cuisine laissant tomber de l’eau' },
} as const;
