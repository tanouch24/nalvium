import Image from 'next/image';
import { ButtonLink, PhotoBand, SectionHeader, SiteCta } from '../components';
import { AnimatedMemory } from '../interactive';
import { photoAssets } from '../data';

export const metadata = {
  title: 'Ma maison',
  description: 'Le carnet de votre maison : retrouver les équipements et problèmes déjà montrés à NALVIUM.',
  alternates: { canonical: '/ma-maison' },
  openGraph: { title: 'Ma maison | NALVIUM', description: 'Le carnet de votre maison : retrouver les équipements et problèmes déjà montrés à NALVIUM.', url: 'https://nalvium.com/ma-maison', type: 'website' },
};

export default function HomeMemory() {
  return (
    <main>
      <section className="page-hero-v5 home-memory-hero">
        <div className="page-hero-v5-copy">
          <span className="eyebrow">MA MAISON</span>
          <h1>Votre maison a une mémoire.</h1>
          <p>Au fil du temps, NALVIUM peut conserver le contexte que vous choisissez : équipements, références, notices, photos et problèmes passés.</p>
        </div>
        <div className="home-memory-hero-photo">
          <Image src={photoAssets.houseLaundry.src} alt={photoAssets.houseLaundry.alt} fill sizes="(max-width:850px) 100vw, 50vw" priority quality={82} />
          <div className="memory-float-card"><span>BUANDERIE</span><strong>Lave-linge</strong><small>Contexte de la maison</small></div>
        </div>
      </section>

      <PhotoBand eyebrow="UN CARNET TECHNIQUE" title="Au fil du temps, vous recommencez moins souvent de zéro." text="Une référence, une notice ou une photo déjà conservée peut rendre la prochaine situation plus facile à comprendre. Vous gardez le contrôle des informations conservées." image={photoAssets.waterHeater} light>
        <ButtonLink href="/confidentialite" secondary>Voir les principes de confidentialité</ButtonLink>
      </PhotoBand>

      <section className="section-v5 home-memory-scene">
        <SectionHeader eyebrow="UN CONTEXTE CHOISI" title="Les équipements deviennent un contexte, pas une liste." />
        <div className="memory-scene-grid">
          <div className="memory-scene-photo"><Image src={photoAssets.dishwasher.src} alt={photoAssets.dishwasher.alt} fill sizes="(max-width:850px) 100vw, 46vw" quality={80} /><span>CUISINE</span></div>
          <div className="memory-scene-panel"><h3>Retrouver le bon contexte.</h3><p>Une photo, une référence ou une notice peuvent aider à mieux comprendre une prochaine situation.</p><p>La mémoire de la maison reste utile seulement si elle est compréhensible et contrôlable.</p><ButtonLink href="/confidentialite" secondary>Voir les principes de confidentialité</ButtonLink></div>
        </div>
      </section>

      <section className="section-v5 timeline-section"><SectionHeader eyebrow="DANS LE TEMPS" title="Une mémoire qui se construit avec votre maison." /><AnimatedMemory /></section>
      <section className="section-v5 two-column-copy"><div><h2>Vous gardez la main.</h2><p>La mémoire technique n’a de valeur que si elle reste compréhensible, utile et contrôlable. Les informations choisies peuvent servir à préparer une vérification ou une demande plus claire.</p></div><ButtonLink href="/comment-ca-marche" secondary>Voir le parcours NALVIUM</ButtonLink></section>
      <SiteCta title="Commencez à comprendre votre maison autrement." />
    </main>
  );
}
