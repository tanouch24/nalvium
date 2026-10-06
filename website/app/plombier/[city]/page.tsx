import type { Metadata } from 'next';
import Link from 'next/link';
import { notFound } from 'next/navigation';
import { Breadcrumbs, ButtonLink, CameraScene, FAQ, PageHero, PhotoProblemCard, RelatedGuides, SafetyStop, SectionHeader, SiteCta } from '../../components';
import { cities, photoAssets } from '../../data';
import { assertLocalPageQuality, franceCities, getFranceCity, preRenderedCitySlugs } from '../../data/france';
import { metroCities, metroProblems, type MetroCity } from '../../metropole-data';

export const dynamicParams = true;
export const revalidate = 3600;

export function generateStaticParams() { return preRenderedCitySlugs().map(city => ({ city })); }

export async function generateMetadata({ params }: { params: Promise<{ city: string }> }): Promise<Metadata> {
  const { city } = await params;
  const franceCity = getFranceCity(city);
  if (!franceCity) notFound();
  const metro = metroCities[city];
  const c = cities[city as keyof typeof cities];
  if (metro) { const url = `https://nalvium.com/plombier/${metro.slug}`; return { title: `Plombier à ${metro.name} ? Comprendre le problème d’abord | NALVIUM`, description: `${metro.name} : observez une fuite, un WC bouché ou une canalisation avant de décider si un plombier doit intervenir.`, alternates: { canonical: url }, openGraph: { title: `Plombier à ${metro.name} ? Comprendre le problème d’abord | NALVIUM`, description: metro.localContext, url, type: 'website' } }; }
  if (!c) {
    const location = `${franceCity.name}, ${franceCity.departmentName}, ${franceCity.regionName}`;
    const title = `Plombier à ${franceCity.name} ? Diagnostiquez le problème d’abord | NALVIUM`;
    const description = `Un problème de plomberie à ${location} ? NALVIUM aide à comprendre ce qui se passe, à effectuer des vérifications sûres et à décider de la suite.`;
    return { title, description, alternates: { canonical: `https://nalvium.com/plombier/${franceCity.urlSlug}` }, openGraph: { title, description, url: `https://nalvium.com/plombier/${franceCity.urlSlug}`, type: 'website' } };
  }
  if (city === 'lyon') return { title: 'Besoin d’un plombier à Lyon ? Identifiez d’abord le problème', description: 'Fuite, WC bouché, évier ou chauffe-eau à Lyon : NALVIUM vous aide gratuitement à observer le problème avant de décider de la suite.', alternates: { canonical: 'https://nalvium.com/plombier/lyon' }, openGraph: { title: 'Besoin d’un plombier à Lyon ? Identifiez d’abord le problème | NALVIUM', description: 'Comprenez ce qui se passe chez vous avant de faire intervenir quelqu’un.', url: 'https://nalvium.com/plombier/lyon', type: 'website' } };
  return { title: `Plombier à ${c.name} : identifier le problème avant d’appeler`, description: `Vous cherchez un plombier à ${c.name} ? NALVIUM vous aide gratuitement à comprendre votre problème avant de décider de la suite.`, alternates: { canonical: `https://nalvium.com/plombier/${city}` } };
}

const lyonProblems = [
  { title: 'Fuite d’eau', href: '/plombier/lyon/fuite-eau', image: photoAssets.leakUnderSink },
  { title: 'Recherche de fuite', href: '/plombier/lyon/recherche-fuite', image: photoAssets.leakUnderSink },
  { title: 'WC bouché', href: '/plombier/lyon/wc-bouche', image: photoAssets.toilet },
  { title: 'Évier bouché', href: '/plombier/lyon/evier-bouche', image: photoAssets.cloggedSink },
  { title: 'Canalisation bouchée', href: '/plombier/lyon/canalisation-bouchee', image: photoAssets.cloggedSink },
  { title: 'Chasse d’eau', href: '/plombier/lyon/chasse-eau', image: photoAssets.toilet },
  { title: 'Robinet qui fuit', href: '/plombier/lyon/robinet-qui-fuit', image: photoAssets.leakingFaucet },
  { title: 'Chauffe-eau', href: '/plombier/lyon/chauffe-eau', image: photoAssets.waterHeater },
  { title: 'Ballon d’eau chaude', href: '/plombier/lyon/ballon-eau-chaude', image: photoAssets.waterHeater },
  { title: 'Dégât des eaux', href: '/plombier/lyon/degat-des-eaux', image: photoAssets.leakUnderSink },
];

const lyonSymptoms = [
  { symptom: 'L’eau remonte dans le WC', href: '/plombier/lyon/wc-bouche', text: 'Le niveau qui monte invite d’abord à limiter l’eau et à observer si d’autres évacuations sont touchées.' },
  { symptom: 'L’évier se vide lentement', href: '/plombier/lyon/evier-bouche', text: 'Une évacuation lente peut rester locale, mais le refoulement ou la présence d’autres équipements touchés change la situation.' },
  { symptom: 'Plusieurs évacuations sont bouchées', href: '/plombier/lyon/canalisation-bouchee', text: 'Plusieurs équipements concernés orientent vers un problème plus loin dans le réseau, sans permettre de confirmer sa cause.' },
  { symptom: 'Une canalisation fait glouglou', href: '/plombier/lyon/canalisation-bouchee', text: 'Un bruit après l’utilisation d’un autre équipement est une observation utile à noter avant de multiplier les essais.' },
  { symptom: 'Un robinet goutte même fermé', href: '/plombier/lyon/robinet-qui-fuit', text: 'Repérez si les gouttes viennent du bec, de la base ou d’un raccord, sans forcer la poignée.' },
  { symptom: 'Une trace d’humidité apparaît sans origine visible', href: '/plombier/lyon/recherche-fuite', text: 'Une trace peut venir d’un point situé plus haut ou d’un passage d’eau non visible : commencez par documenter son évolution.' },
  { symptom: 'Le chauffe-eau ne produit plus d’eau chaude', href: '/plombier/lyon/chauffe-eau', text: 'Observez uniquement l’extérieur, les références et les signes visibles ; n’ouvrez pas la partie électrique.' },
  { symptom: 'Le ballon d’eau chaude fuit', href: '/plombier/lyon/ballon-eau-chaude', text: 'Une fuite visible autour de la cuve ou du groupe de sécurité doit être observée sans toucher à l’électricité ni au gaz.' },
  { symptom: 'De l’eau apparaît au plafond', href: '/plombier/lyon/degat-des-eaux', text: 'Protégez la zone si c’est possible sans danger, éloignez-vous de l’électricité humide et notez l’étendue visible.' },
];

const lyonFaq = [
  { question: 'Dois-je appeler immédiatement un plombier pour une fuite ?', answer: 'Pas toujours. Commencez par observer l’origine visible, le débit et l’évolution de la fuite si vous pouvez le faire sans danger. Si l’eau est importante, non maîtrisable ou proche d’une installation électrique, arrêtez-vous et demandez une aide professionnelle.' },
  { question: 'Que faire avant l’arrivée d’un plombier ?', answer: 'Éloignez les objets exposés, limitez l’eau si la commande est accessible sans forcer, photographiez ce qui est visible et notez quand le problème apparaît. Ne démontez pas une installation si le contexte est incertain.' },
  { question: 'Comment savoir d’où vient une fuite ?', answer: 'Séchez uniquement les surfaces accessibles et observez quel point redevient humide lorsque l’eau est utilisée. Une trace plus haute peut venir d’un autre raccord : l’observation n’est pas une certitude.' },
  { question: 'Que faire si mon WC est bouché ?', answer: 'Évitez de rajouter de l’eau si elle monte, observez si d’autres évacuations sont touchées et n’utilisez pas de mélanges chimiques. Arrêtez-vous en cas de refoulement important ou de produit déjà présent.' },
  { question: 'NALVIUM remplace-t-il un plombier ?', answer: 'Non. NALVIUM aide à montrer le problème, comprendre des causes probables et effectuer uniquement des vérifications sûres avant de décider si un professionnel est nécessaire.' },
];

const metroProblemCards = [
  { slug: 'fuite-eau', image: photoAssets.leakUnderSink },
  { slug: 'wc-bouche', image: photoAssets.toilet },
  { slug: 'canalisation-bouchee', image: photoAssets.cloggedSink },
];
const metroNeighbors: Record<string, string[]> = { villeurbanne: ['lyon', 'bron'], bron: ['lyon', 'villeurbanne'], venissieux: ['lyon', 'saint-priest'], 'saint-priest': ['lyon', 'venissieux'], 'caluire-et-cuire': ['lyon', 'villeurbanne'] };
const legacyCityProblemCards: Record<string, { title: string; slug: string; image: { src: string; alt: string } }[]> = {
  nice: [
    { title: 'Fuite d’eau', slug: 'fuite-eau', image: photoAssets.leakUnderSink },
    { title: 'Évier bouché', slug: 'evier-bouche', image: photoAssets.cloggedSink },
    { title: 'Chasse d’eau qui coule', slug: 'chasse-eau', image: photoAssets.toilet },
  ],
};

function MetroHub({ city }: { city: MetroCity }) {
  const registryCity = getFranceCity(city.slug);
  if (!registryCity) notFound();
  const cards = metroProblemCards.map(card => ({ ...card, content: metroProblems[card.slug] }));
  assertLocalPageQuality({ city: registryCity, title: `Plombier à ${city.name} ? Comprendre le problème d’abord | NALVIUM`, description: city.localContext, h1: `Un problème de plomberie à ${city.name} ? Comprenez d’abord ce qui se passe.`, canonical: `https://nalvium.com/plombier/${city.slug}`, hasSafety: true, hasCta: true, usefulLinks: cards.length, hasFalseProfessionalData: false });
  const faq = [
    { question: `NALVIUM intervient-il comme plombier à ${city.name} ?`, answer: `Non. NALVIUM est un service numérique gratuit qui aide à observer le problème, envisager des causes possibles et savoir quand demander un professionnel. ${city.faqAnswer}` },
    { question: `Que vérifier avant d’appeler un plombier à ${city.name} ?`, answer: `Notez l’équipement concerné, l’origine visible de l’eau, le moment d’apparition et les autres équipements touchés. Ne démontez pas et arrêtez-vous si l’eau approche l’électricité ou si le risque augmente.` },
    { question: `Que faire en cas de problème de plomberie à ${city.name} ?`, answer: 'Commencez par limiter l’eau uniquement si une commande est identifiable et sûre, puis décrivez ce que vous voyez. Une fuite importante, un refoulement ou une installation électrique humide nécessitent de s’arrêter.' },
  ];
  const faqJsonLd = { '@context': 'https://schema.org', '@type': 'FAQPage', mainEntity: faq.map(item => ({ '@type': 'Question', name: item.question, acceptedAnswer: { '@type': 'Answer', text: item.answer } })) };
  const articleJsonLd = { '@context': 'https://schema.org', '@type': 'Article', headline: `Un problème de plomberie à ${city.name} ? Comprenez d’abord ce qui se passe.`, description: city.localContext, mainEntityOfPage: `https://nalvium.com/plombier/${city.slug}`, publisher: { '@type': 'Organization', name: 'NALVIUM', url: 'https://nalvium.com' } };
  return <main><Breadcrumbs items={[{ label: 'Plombier', href: '/professionnels' }, { label: city.name }]} /><section className="local-hero-v5"><PageHero eyebrow={`NALVIUM · ${city.name.toUpperCase()}`} title={<><span style={{ display: 'block' }}>Un problème de plomberie à {city.name} ?</span><span style={{ display: 'block' }}>Comprenez d’abord ce qui se passe.</span></>}><p>{city.localContext}</p><p>{city.housingContext}</p><ButtonLink href="/comment-ca-marche">Diagnostiquer gratuitement</ButtonLink></PageHero><CameraScene compact label="MONTREZ LA SITUATION" priority /></section><section className="section-v5 local-situations"><SectionHeader eyebrow={`PROBLÈMES FRÉQUENTS À ${city.name.toUpperCase()}`} title="Quel problème rencontrez-vous ?">Choisissez le symptôme qui ressemble le plus à ce que vous voyez. NALVIUM ne confirme pas une cause à distance : il vous aide à clarifier la prochaine observation.</SectionHeader><div className="local-photo-grid">{cards.map((card, index) => <PhotoProblemCard key={card.slug} title={card.content.label} href={`/plombier/${city.slug}/${card.slug}`} image={card.image} size={index === 0 ? 'is-featured' : ''} />)}</div></section><section className="section-v5"><SectionHeader eyebrow="AVANT D’APPELER UN PLOMBIER" title={`Les premières observations utiles à ${city.name}.`}>Dans un appartement, une maison ou un immeuble, commencez par ce qui est visible et accessible sans forcer.</SectionHeader><div className="outcome-grid"><div className="outcome"><span>01 · ORIGINE</span><h3>Où l’eau apparaît-elle ?</h3><p>{city.firstObservation}</p></div><div className="outcome"><span>02 · MOMENT</span><h3>Quand le signe arrive-t-il ?</h3><p>Notez s’il apparaît au repos, pendant l’utilisation, après une chasse ou quand plusieurs équipements sont sollicités.</p></div><div className="outcome"><span>03 · ÉTENDUE</span><h3>Quel autre équipement réagit ?</h3><p>Un seul point d’eau et plusieurs évacuations ne se trient pas de la même manière. Ne remplissez pas le réseau pour tester.</p></div></div></section><SafetyStop items={['Eau proche d’une prise, d’un tableau ou d’un appareil électrique alimenté', 'Fuite importante, refoulement ou eau potentiellement contaminée', 'Odeur de gaz, fumée, chaleur anormale ou risque structurel', 'Besoin de forcer, de démonter ou d’intervenir sous tension']} /><section className="section-v5"><SectionHeader eyebrow={`CONTEXTE LOCAL · ${city.name.toUpperCase()}`} title="Une commune, mais pas de diagnostic automatique.">{city.housingContext} La commune indique le parcours local ; elle ne permet pas de déduire l’âge d’une installation, la cause d’une fuite ou la disponibilité d’un professionnel.</SectionHeader><div className="local-problems">{metroNeighbors[city.slug].map(slug => <Link key={slug} href={slug === 'lyon' ? '/plombier/lyon' : `/plombier/${slug}`}>{slug === 'lyon' ? 'Parcours Lyon' : `Parcours ${metroCities[slug].name}`}<span>→</span></Link>)}</div></section><section className="section-v5"><SectionHeader eyebrow="QUESTIONS FRÉQUENTES" title={`Avant de décider de la suite à ${city.name}.`} /><FAQ items={faq} /></section><script type="application/ld+json" dangerouslySetInnerHTML={{ __html: JSON.stringify([articleJsonLd, faqJsonLd]) }} /><SiteCta title="Montrez le problème à NALVIUM." /></main>;
}

function LegacyCityHub({ citySlug, city }: { citySlug: string; city: typeof cities[keyof typeof cities] }) {
  const registryCity = getFranceCity(citySlug);
  if (!registryCity) notFound();
  const cards = legacyCityProblemCards[citySlug] ?? [];
  assertLocalPageQuality({ city: registryCity, title: `Plombier à ${city.name} : identifier le problème avant d’appeler`, description: city.intro, h1: `Besoin d’un plombier à ${city.name} ? Commencez par montrer le problème.`, canonical: `https://nalvium.com/plombier/${citySlug}`, hasSafety: true, hasCta: true, usefulLinks: cards.length, hasFalseProfessionalData: false });
  return <main><Breadcrumbs items={[{ label: 'Plombier', href: '/professionnels' }, { label: city.name }]} /><section className="local-hero-v5"><PageHero eyebrow={`NALVIUM · ${city.name.toUpperCase()}`} title={`Besoin d’un plombier à ${city.name} ? Commencez par montrer le problème.`}><p>{city.intro}</p><ButtonLink href="/comment-ca-marche">Montrer mon problème</ButtonLink></PageHero><CameraScene compact /></section><section className="section-v5 local-situations"><SectionHeader eyebrow={`SITUATIONS À ${city.name.toUpperCase()}`} title="Commencez par le symptôme que vous voyez.">Choisissez une situation proche de ce que vous observez. NALVIUM aide à clarifier la suite sans se présenter comme un service de dépannage local.</SectionHeader><div className="local-photo-grid">{cards.map((card, index) => <PhotoProblemCard key={card.slug} title={card.title} href={`/plombier/${citySlug}/${card.slug}`} image={card.image} size={index === 0 ? 'is-featured' : ''} />)}</div></section><section className="section-v5 local-professional-note"><SectionHeader eyebrow="QUAND PASSER LA MAIN ?" title={`Vous avez besoin d’un professionnel à ${city.name} ?`}>Si l’eau est importante, si le risque augmente ou si l’origine reste incertaine, arrêtez-vous. NALVIUM aide à préparer une description plus claire, mais ne fournit ni intervention, ni disponibilité, ni tarif.</SectionHeader><ButtonLink href="/securite" secondary>Voir les règles de sécurité</ButtonLink></section><SiteCta title="Commencez par montrer votre problème à NALVIUM." /></main>;
}

const nationalHubFamilies = [
  { title: 'Fuite d’eau', text: 'Observez l’origine visible, le moment où l’eau apparaît et si elle approche une installation électrique.', guides: ['fuite-sous-evier', 'fuite-sous-lavabo', 'robinet-qui-goutte'] },
  { title: 'WC', text: 'Notez si le niveau monte, si l’évacuation ralentit et si d’autres équipements sont concernés.', guides: ['wc-qui-remonte', 'wc-se-vide-lentement', 'chasse-eau-qui-coule'] },
  { title: 'Évier et lavabo', text: 'Distinguez une évacuation lente, une eau stagnante, une odeur et un problème qui touche plusieurs points.', guides: ['evier-bouche', 'evier-se-vide-lentement', 'lavabo-se-vide-lentement'] },
  { title: 'Canalisation', text: 'Un glouglou, un refoulement ou plusieurs évacuations touchées sont des observations à relever sans conclure trop vite.', guides: ['canalisation-qui-glougloute', 'mauvaise-odeur-canalisation', 'eau-remonte-dans-douche'] },
  { title: 'Robinet', text: 'Repérez si la goutte vient du bec, de la base ou d’un raccord visible, sans forcer la poignée.', guides: ['robinet-qui-goutte', 'robinet-qui-fuit-a-la-base'] },
  { title: 'Chauffe-eau', text: 'Restez sur les signes extérieurs : eau chaude absente, fuite, bruit ou groupe de sécurité qui coule.', guides: ['chauffe-eau-ne-chauffe-plus', 'chauffe-eau-fuit', 'groupe-securite-chauffe-eau-qui-coule'] },
  { title: 'Dégât des eaux', text: 'Documentez l’étendue visible et éloignez-vous de l’électricité humide ; l’origine peut rester incertaine.', guides: ['recherche-fuite', 'fuite-sous-lavabo', 'chauffe-eau-fuit'] },
];

function NationalHub({ city }: { city: (typeof franceCities)[number] }) {
  const location = `${city.name}, en ${city.departmentName}, dans la région ${city.regionName}`;
  const canonical = `https://nalvium.com/plombier/${city.urlSlug}`;
  const title = `Plombier à ${city.name} ? Diagnostiquez le problème d’abord | NALVIUM`;
  const description = `Un problème de plomberie à ${location} ? NALVIUM aide à comprendre ce qui se passe avant de décider si un professionnel est nécessaire.`;
  const faq = [
    { question: `NALVIUM est-il un plombier à ${city.name} ?`, answer: 'Non. NALVIUM est un service numérique gratuit qui aide à observer un problème, envisager des causes possibles et effectuer uniquement des vérifications sûres avant de décider de la suite.' },
    { question: `Que vérifier avant d’appeler un plombier à ${city.name} ?`, answer: 'Commencez par l’équipement concerné, l’origine visible de l’eau, le moment où le symptôme apparaît et le nombre de points touchés. Ne forcez pas et ne démontez pas si le contexte est incertain.' },
  ];
  assertLocalPageQuality({ city, title, description, h1: `Un problème de plomberie à ${city.name} ? Comprenez d’abord ce qui se passe.`, canonical, hasSafety: true, hasCta: true, usefulLinks: nationalHubFamilies.reduce((count, family) => count + family.guides.length, 0), hasFalseProfessionalData: false });
  const articleJsonLd = { '@context': 'https://schema.org', '@type': 'Article', headline: `Un problème de plomberie à ${city.name} ? Comprenez d’abord ce qui se passe.`, description, mainEntityOfPage: canonical, publisher: { '@type': 'Organization', name: 'NALVIUM', url: 'https://nalvium.com' } };
  const faqJsonLd = { '@context': 'https://schema.org', '@type': 'FAQPage', mainEntity: faq.map(item => ({ '@type': 'Question', name: item.question, acceptedAnswer: { '@type': 'Answer', text: item.answer } })) };
  return <main><Breadcrumbs items={[{ label: 'Plombier', href: '/professionnels' }, { label: city.name }]} /><section className="local-hero-v5"><PageHero eyebrow={`NALVIUM · ${city.name.toUpperCase()}`} title={`Un problème de plomberie à ${city.name} ? Comprenez d’abord ce qui se passe.`}><p>NALVIUM vous aide à identifier le type de problème, à évaluer les signes de prudence et à effectuer uniquement les vérifications sûres avant de décider si un professionnel est nécessaire.</p><p>Vous êtes à {location}. Le nom de la commune et les données géographiques servent à situer ce parcours, pas à déduire la cause d’une panne ou la disponibilité d’un artisan.</p><ButtonLink href="/comment-ca-marche">Diagnostiquer gratuitement</ButtonLink></PageHero><CameraScene compact label="MONTREZ LA SITUATION" /></section><section className="section-v5 local-situations"><SectionHeader eyebrow={`SITUATIONS À ${city.name.toUpperCase()}`} title="Quel problème rencontrez-vous ?">Commencez par le symptôme que vous voyez, puis consultez les guides nationaux qui correspondent à votre observation.</SectionHeader><div className="outcome-grid">{nationalHubFamilies.map(family => <article className="outcome" key={family.title}><h3>{family.title}</h3><p>{family.text}</p><div className="local-problems">{family.guides.map(slug => <Link key={slug} href={`/guides/${slug}`}>{slug.replaceAll('-', ' ')}<span>→</span></Link>)}</div></article>)}</div></section><section className="section-v5"><SectionHeader eyebrow="AVANT D’APPELER UN PLOMBIER" title="Les premières observations utiles.">Sans démonter ni forcer, notez l’origine visible de l’eau, l’équipement concerné, le moment d’apparition, l’évolution du symptôme et les autres points touchés.</SectionHeader></section><SafetyStop items={['Eau proche d’une prise, d’un tableau ou d’un appareil électrique alimenté', 'Fuite importante, refoulement ou eau potentiellement contaminée', 'Odeur de gaz, fumée, chaleur anormale ou risque structurel', 'Besoin de forcer, de démonter ou d’intervenir sous tension']} /><section className="section-v5"><SectionHeader eyebrow="CONTEXTE GÉOGRAPHIQUE" title={`Un parcours situé à ${city.name}.`}>{location}. Ces informations officielles permettent de lever une ambiguïté entre communes homonymes ; elles ne constituent ni une description du bâti, ni une statistique de panne, ni une promesse d’intervention.</SectionHeader><div className="local-problems"><Link href="/securite">Lire les règles de sécurité<span>→</span></Link><Link href="/comment-ca-marche">Comprendre comment fonctionne NALVIUM<span>→</span></Link></div></section><section className="section-v5"><SectionHeader eyebrow="GUIDES NATIONAUX ASSOCIÉS" title="Approfondir le symptôme observé."/><RelatedGuides slugs={Array.from(new Set(nationalHubFamilies.flatMap(family => family.guides))).slice(0, 8)} /></section><section className="section-v5"><SectionHeader eyebrow="QUESTIONS FRÉQUENTES" title={`Avant de décider de la suite à ${city.name}.`} /><FAQ items={faq} /></section><script type="application/ld+json" dangerouslySetInnerHTML={{ __html: JSON.stringify([articleJsonLd, faqJsonLd]) }} /><SiteCta title="Montrez le problème à NALVIUM." /></main>;
}

export default async function LocalPage({ params }: { params: Promise<{ city: string }> }) {
  const { city } = await params;
  const franceCity = getFranceCity(city);
  if (!franceCity) notFound();
  const metro = metroCities[city];
  const c = cities[city as keyof typeof cities];
  if (metro) return <MetroHub city={metro} />;
  if (!c) return <NationalHub city={franceCity} />;
  if (city !== 'lyon') return <LegacyCityHub citySlug={city} city={c} />;
  const registryCity = getFranceCity(city);
  if (!registryCity) notFound();
  assertLocalPageQuality({ city: registryCity, title: 'Besoin d’un plombier à Lyon ? Identifiez d’abord le problème', description: 'Fuite, WC bouché, évier ou chauffe-eau à Lyon : NALVIUM vous aide gratuitement à observer le problème avant de décider de la suite.', h1: 'Un problème de plomberie à Lyon ? Comprenez d’abord ce qui se passe.', canonical: 'https://nalvium.com/plombier/lyon', hasSafety: true, hasCta: true, usefulLinks: lyonProblems.length, hasFalseProfessionalData: false });
  const faqJsonLd = { '@context': 'https://schema.org', '@type': 'FAQPage', mainEntity: lyonFaq.map(item => ({ '@type': 'Question', name: item.question, acceptedAnswer: { '@type': 'Answer', text: item.answer } })) };
  return <main>
    <Breadcrumbs items={[{ label: 'Plombier', href: '/professionnels' }, { label: 'Lyon' }]} />
    <section className="local-hero-v5"><PageHero eyebrow="NALVIUM · LYON" title={<><span style={{ display: 'block' }}>Un problème de plomberie à Lyon ?</span><span style={{ display: 'block' }}>Comprenez d’abord ce qui se passe.</span></>}><p>Une fuite, un WC bouché ou un évier qui ne s’évacue plus ne nécessite pas toujours la même intervention.</p><p>Avec NALVIUM, montrez le problème et obtenez gratuitement une première orientation avant de décider de la suite.</p><ButtonLink href="/comment-ca-marche">Diagnostiquer gratuitement</ButtonLink></PageHero><CameraScene compact label="MONTREZ LA SITUATION" priority /></section>
    <section className="section-v5 local-situations"><SectionHeader eyebrow="PROBLÈMES FRÉQUENTS À LYON" title="Quel problème rencontrez-vous ?">Choisissez le symptôme qui ressemble le plus à ce que vous voyez. NALVIUM ne prétend pas confirmer une cause à distance : il commence par clarifier la situation.</SectionHeader><div className="local-photo-grid">{lyonProblems.map((problem, index) => <PhotoProblemCard key={problem.href} title={problem.title} href={problem.href} image={problem.image} size={index === 0 ? 'is-featured' : ''} />)}</div></section>
    <section className="section-v5"><SectionHeader eyebrow="AVANT D’APPELER UN PLOMBIER" title="Quelques observations peuvent déjà orienter la suite.">Sans démonter ni forcer, regardez ce qui est réellement visible :</SectionHeader><div className="outcome-grid"><div className="outcome"><span>01 · ORIGINE</span><h3>Où l’eau apparaît-elle ?</h3><p>Repérez l’origine visible, l’équipement concerné et si l’humidité vient d’un point précis ou d’une zone plus large.</p></div><div className="outcome"><span>02 · MOMENT</span><h3>Quand le problème arrive-t-il ?</h3><p>Notez si la fuite est permanente ou seulement pendant l’utilisation, et si l’évacuation est lente ou totalement bloquée.</p></div><div className="outcome"><span>03 · SIGNAL</span><h3>Quel autre signe voyez-vous ?</h3><p>Un bruit inhabituel, un refoulement ou de l’eau près d’un équipement électrique change immédiatement la prudence à adopter.</p></div></div></section>
    <SafetyStop items={['Eau près d’une prise, d’une multiprise ou d’un appareil électrique', 'Fuite importante, rapide ou impossible à contenir', 'Odeur de gaz, fumée, chaleur anormale ou installation endommagée', 'Besoin de forcer, de démonter ou d’intervenir sous tension']} />
    <section className="section-v5 local-journey"><SectionHeader eyebrow="COMMENT NALVIUM VOUS AIDE" title="Une observation, puis une décision plus claire.">Le parcours reste simple et gratuit pour les particuliers.</SectionHeader><div className="local-journey-line"><div><span>01 · MONTRER</span><strong>Une photo de la situation</strong></div><i>→</i><div><span>02 · COMPRENDRE</span><strong>Quelques questions</strong></div><i>→</i><div><span>03 · VÉRIFIER</span><strong>Des gestes sûrs</strong></div><i>→</i><div><span>04 · DÉCIDER</span><strong>Simple ou professionnel</strong></div></div></section>
    <section className="section-v5"><SectionHeader eyebrow="PLOMBERIE À LYON" title="Les mêmes symptômes peuvent demander des suites différentes.">Dans un appartement, une maison ou un immeuble de Lyon et de la Métropole de Lyon, une eau sous un évier peut venir d’un raccord visible, d’une évacuation ou d’un équipement voisin. En copropriété, plusieurs logements ou évacuations peuvent aussi être concernés. Le bon premier réflexe est de décrire ce que vous voyez avant de choisir une intervention.</SectionHeader><div className="local-problems">{lyonProblems.map(problem => <Link key={problem.href} href={problem.href}>{problem.title}<span>→</span></Link>)}</div></section>
    <section className="section-v5"><SectionHeader eyebrow="LIRE LES SIGNES SANS CONCLURE TROP VITE" title="Ce que vos symptômes peuvent déjà indiquer">Ces observations peuvent orienter la prochaine vérification, mais elles ne constituent pas un diagnostic certain.</SectionHeader><div className="outcome-grid">{lyonSymptoms.map(item => <Link className="outcome" key={item.href + item.symptom} href={item.href}><span>{item.symptom}</span><p>{item.text}</p><strong>Voir la situation →</strong></Link>)}</div></section>
    <section className="section-v5 local-professional-note"><SectionHeader eyebrow="LA LIMITE FAIT PARTIE DU PRODUIT" title="NALVIUM ne remplace pas un plombier.">L’outil aide à mieux observer, à essayer uniquement ce qui reste raisonnablement sûr et à préparer un contexte plus clair. Si le risque augmente ou si l’origine reste incertaine, arrêtez-vous et faites intervenir un professionnel de votre choix.</SectionHeader><ButtonLink href="/securite" secondary>Voir les règles de sécurité</ButtonLink></section>
    <section className="section-v5"><SectionHeader eyebrow="QUESTIONS FRÉQUENTES" title="Avant de décider de la suite." /><FAQ items={lyonFaq} /></section><script type="application/ld+json" dangerouslySetInnerHTML={{ __html: JSON.stringify(faqJsonLd) }} /><SiteCta title="Diagnostiquez gratuitement ce que vous voyez." />
  </main>;
}
