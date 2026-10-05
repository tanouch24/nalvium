import Image from 'next/image';
import Link from 'next/link';
import { ButtonLink, StoreBadges } from './components';
import { categories, categoryImages, photoAssets } from './data';
import { AppFinalCta, HeroAppShowcase, HouseAppFeature, ObservationDemoInteractive, ProductMechanism, ProfessionalAppFlow, SafetyAppBreak, SituationMosaic, SituationWall } from './interactive';

export default function Home() {
  return <main>
    <section className="hero-app-first">
      <div className="hero-app-copy">
        <span className="eyebrow">L’ASSISTANT DE VOTRE MAISON</span>
        <h1>Un problème à la maison ? <em>Montrez-le.</em></h1>
        <p>Une photo suffit pour commencer à comprendre ce qui se passe.</p>
        <ButtonLink href="/comment-ca-marche">Essayer NALVIUM</ButtonLink>
        <StoreBadges />
      </div>
      <HeroAppShowcase />
    </section>

    <SituationMosaic />

    <section id="parcours" className="home-mechanism"><div className="home-section-heading"><span className="eyebrow">COMMENT ÇA MARCHE</span><h2>Une photo.<br /><em>Quelques questions. Une réponse claire.</em></h2><p className="home-mechanism-lead">NALVIUM avance avec vous étape par étape, sans vous demander de connaître la panne.</p></div><ProductMechanism /></section>

    <ObservationDemoInteractive />
    <SituationWall />
    <SafetyAppBreak />
    <ProfessionalAppFlow />
    <HouseAppFeature />

    <section className="home-popular-guides"><div className="home-section-heading"><span className="eyebrow">AVANT D’APPELER</span><h2>Commencez par comprendre.</h2></div><div className="home-guide-grid">{categories.map(category => { const image = categoryImages[category.slug as keyof typeof categoryImages]; return <Link className="home-guide-card" href={`/guides/${category.slug}`} key={category.slug}><Image src={image.src} alt={image.alt} fill sizes="(max-width: 560px) 100vw, 25vw" quality={78} loading="eager" /><span className="home-guide-card-shade" /><div><small>{category.label}</small><strong>{category.description}</strong><i>Explorer <span aria-hidden="true">→</span></i></div></Link>; })}</div><ButtonLink href="/guides" secondary>Voir tous les guides</ButtonLink></section>

    <AppFinalCta />
  </main>;
}
