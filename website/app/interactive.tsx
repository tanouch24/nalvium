'use client';

import Image from 'next/image';
import Link from 'next/link';
import { useEffect, useRef, useState } from 'react';
import { photoAssets } from './data';
import { ButtonLink, StoreBadges } from './components';

type Scenario = {
  id: string;
  label: string;
  image: { src: string; alt: string };
  observation: string;
  question: string;
  action: string;
  href: string;
};

const primaryScenario: Scenario = {
  id: 'leak',
  label: 'Sous l’évier',
  image: photoAssets.leakUnderSink,
  observation: 'La bonde et la zone d’évacuation sont visibles.',
  question: 'L’eau apparaît-elle uniquement lorsque l’eau coule ?',
  action: 'Séchez la zone puis faites couler l’eau quelques secondes pour vérifier l’origine.',
  href: '/guides/fuite-sous-evier',
};

const scenarios: Scenario[] = [
  primaryScenario,
  { id: 'washer', label: 'Lave-linge', image: photoAssets.washingMachineDrain, observation: 'Vous signalez un problème de vidange.', question: 'Le programme s’est-il terminé sans vidanger ?', action: 'Éteignez et débranchez l’appareil avant toute vérification.', href: '/guides/lave-linge-ne-vidange-plus' },
  { id: 'toilet', label: 'WC', image: photoAssets.toilet, observation: 'Vous signalez une chasse d’eau qui coule en continu.', question: 'Le bruit d’écoulement continue-t-il plusieurs minutes après la chasse ?', action: 'Fermez l’arrivée d’eau si elle tourne sans forcer.', href: '/guides/chasse-eau-qui-coule' },
  { id: 'sink', label: 'Évier', image: photoAssets.leakUnderSink, observation: 'Vous signalez une évacuation lente.', question: 'L’eau finit-elle par s’évacuer complètement ?', action: 'N’ajoutez pas de produit et évitez tout mélange chimique.', href: '/guides/evier-bouche' },
];

const productDemoScenario = scenarios[1];

function useReducedMotion() {
  const [reduced, setReduced] = useState(false);
  useEffect(() => {
    const media = window.matchMedia('(prefers-reduced-motion: reduce)');
    const update = () => setReduced(media.matches);
    update();
    media.addEventListener?.('change', update);
    return () => media.removeEventListener?.('change', update);
  }, []);
  return reduced;
}

export function Reveal({ children, className = '', delay = 0 }: { children: React.ReactNode; className?: string; delay?: number }) {
  const ref = useRef<HTMLDivElement>(null);
  const reduced = useReducedMotion();
  const [visible, setVisible] = useState(reduced);
  useEffect(() => {
    if (reduced) { setVisible(true); return; }
    const node = ref.current;
    if (!node) return;
    const observer = new IntersectionObserver(([entry]) => {
      if (entry.isIntersecting) { setVisible(true); observer.disconnect(); }
    }, { threshold: 0.12, rootMargin: '0px 0px -40px' });
    observer.observe(node);
    return () => observer.disconnect();
  }, [reduced]);
  return <div ref={ref} className={`reveal ${visible ? 'is-visible' : ''} ${className}`} style={{ '--reveal-delay': `${delay}ms` } as React.CSSProperties}>{children}</div>;
}

export function RevealGroup({ children, className = '' }: { children: React.ReactNode; className?: string }) {
  return <div className={`reveal-group ${className}`}>{children}</div>;
}

function FocusCorners() {
  return <div className="hero-focus" aria-hidden="true"><i /></div>;
}

function ScenarioPanel({ scenario, phase }: { scenario: Scenario; phase: number }) {
  return <>
    <div className="hero-camera-top"><span>NALVIUM • CAMÉRA</span><span>● DÉMO</span></div>
    <div className="hero-observing">J’observe…</div>
    <div className={`hero-scenario-copy ${phase >= 3 ? 'is-visible' : ''}`}>
      <small>CE QUE JE VOIS</small>
      <strong>{scenario.observation}</strong>
      <p>Je vérifie avec vous avant de conclure.</p>
    </div>
    <div className={`hero-scenario-action ${phase >= 4 ? 'is-visible' : ''}`}>
      <small>PROCHAINE ÉTAPE</small>
      <strong>{scenario.action}</strong>
      <span>Une action à la fois</span>
    </div>
    <div className={`hero-focus-layer ${phase >= 2 && (scenario.id === 'leak' || scenario.id === 'sink') ? 'is-visible' : ''}`}><FocusCorners /><span>zone observée</span></div>
  </>;
}

function HeroSimplePhone() {
  return <div className="nalvium-phone hero-simple-phone" aria-label="Exemple d’écran NALVIUM avec un lave-linge">
    <div className="hero-simple-phone-screen">
      <Image src="/images/nalvium/app/home-screen.jpg" alt="Écran d’accueil de l’application NALVIUM" fill sizes="(max-width: 700px) 84vw, 330px" priority quality={100} className="hero-simple-phone-image" />
    </div>
  </div>;
}

export function HeroAppShowcase() {
  return <div className="hero-app-showcase hero-app-showcase-simple"><div className="hero-phone-wrap"><HeroSimplePhone /></div></div>;
}

export function SituationMosaic() {
  const items = [
    ['leak', 'PLOMBERIE', 'J’ai de l’eau sous l’évier', photoAssets.plumbingMosaic, '/guides/fuite-sous-evier', 'is-large'],
    ['washer', 'LAVE-LINGE', 'L’eau ne s’évacue plus', photoAssets.washingMachine, '/guides/lave-linge-ne-vidange-plus', ''],
    ['toilet', 'WC', 'La chasse d’eau coule en continu', photoAssets.toilet, '/guides/chasse-eau-qui-coule', ''],
    ['oven', 'FOUR', 'Le four ne chauffe plus', photoAssets.oven, '/guides/four-ne-chauffe-plus', ''],
    ['fridge', 'RÉFRIGÉRATEUR', 'Le réfrigérateur ne fait plus assez de froid', photoAssets.refrigerator, '/guides/refrigerateur-ne-refroidit-plus', ''],
  ] as const;
  return <section className="situation-mosaic-section"><div className="situation-mosaic-copy"><span className="eyebrow">PAS BESOIN DE CONNAÎTRE LA PANNE</span><h2>Montrez simplement<br /><em>ce qui ne va pas.</em></h2><p>Fuite, appareil qui ne démarre plus, eau qui ne s’évacue pas… NALVIUM part de ce que vous voyez et vous pose les bonnes questions.</p></div><div className="situation-mosaic">{items.map(([id, label, text, image, href, size]) => <Link key={id} href={href} className={`situation-mosaic-card ${size}`}><Image src={image.src} alt={image.alt} fill sizes="(max-width: 700px) 50vw, 25vw" quality={76} /><span className="situation-mosaic-shade" /><div><small>{label}</small><strong>{text}</strong></div></Link>)}</div></section>;
}

export function ProfessionalAppFlow() {
  const flow = [
    { label: 'PHOTO DU PROBLÈME', image: photoAssets.leakUnderSink, text: 'Ce que vous voyez chez vous.' },
    { label: 'OBSERVATIONS', image: photoAssets.leakingFaucet, text: 'Les éléments réellement visibles.' },
    { label: 'RÉSUMÉ UTILE', image: photoAssets.washingMachineDrain, text: 'Les vérifications déjà réalisées.' },
    { label: 'PROFESSIONNEL SI NÉCESSAIRE', image: photoAssets.waterHeater, text: 'Une suite choisie avec prudence.' },
  ];
  return <section id="professionnels-home" className="professional-app-flow"><div className="professional-app-heading"><span className="eyebrow">SI QUELQU’UN DOIT INTERVENIR</span><h2>Le problème est déjà mieux expliqué.</h2><p>Avec votre consentement avant toute transmission de coordonnées ou de photos.</p></div><div className="professional-flow-visual">{flow.map((item, index) => <div className="professional-flow-item" key={item.label}><div className="professional-flow-photo"><Image src={item.image.src} alt={item.image.alt} fill sizes="(max-width: 700px) 100vw, 23vw" quality={76} loading="eager" /></div><span>{item.label}</span><strong>{item.text}</strong>{index < flow.length - 1 && <i aria-hidden="true">→</i>}</div>)}</div></section>;
}

export function AppFinalCta() {
  return <section className="app-final-cta" id="diagnostic"><div className="app-final-copy"><span className="eyebrow">GRATUIT POUR LES PARTICULIERS</span><h2>Un problème à la maison ?<br /><em>Montrez-le à NALVIUM.</em></h2><ButtonLink href="/comment-ca-marche">Essayer NALVIUM</ButtonLink><StoreBadges /></div></section>;
}

export function ProductMechanism() {
  const steps = [
    { number: '01', title: 'Montrez le problème', text: 'Prenez une photo ou décrivez simplement ce qui se passe.', image: photoAssets.stepProblem },
    { number: '02', title: 'Précisez', text: 'Quelques questions permettent de mieux comprendre la situation.', image: photoAssets.washingMachineDrain },
    { number: '03', title: 'Décidez', text: 'NALVIUM indique la prochaine étape raisonnable : agir si c’est simple et sûr, ou s’arrêter.', image: photoAssets.toilet },
  ];
  return <div className="mechanism-steps product-steps">{steps.map((step, index) => <div key={step.number} className="mechanism-step product-step"><div className={`mechanism-step-image product-step-surface product-step-${index + 1}`}>{step.image ? <Image src={step.image.src} alt={step.image.alt} fill sizes="(max-width: 700px) 100vw, 31vw" quality={78} loading="eager" /> : <div className="product-step-empty" aria-hidden="true" />}</div><small>{step.number}</small><h3>{step.title}</h3><p>{step.text}</p></div>)}</div>;
}

export function SafetyAppBreak() {
  return <section id="securite-home" className="app-safety-break"><div className="app-safety-copy"><span className="eyebrow">LA LIMITE FAIT PARTIE DU PRODUIT</span><h2>Parfois, la bonne réponse est de s’arrêter.</h2><p>NALVIUM vous aide aussi à reconnaître les situations qui ne doivent pas être réparées soi-même.</p><div className="safety-short-list"><span>Gaz</span><span>Électricité dangereuse</span><span>Fuite importante</span><span>Risque structurel</span></div><Link className="button button-secondary" href="/securite">Découvrir notre approche sécurité</Link></div><div className="safety-phone-stage"><div className="safety-context-photo"><Image src={photoAssets.electricalOutlet.src} alt={photoAssets.electricalOutlet.alt} fill sizes="(max-width: 850px) 100vw, 42vw" quality={78} loading="eager" /><span>INSTALLATION DOMESTIQUE · OBSERVER DE L’EXTÉRIEUR</span></div><p className="safety-stop-note">Dans le doute : on s’arrête.</p></div></section>;
}

export function HouseAppFeature() {
  return <section id="ma-maison" className="house-app-feature"><div className="house-app-copy"><span className="eyebrow">MA MAISON</span><h2>Votre maison a une mémoire.</h2><p>Équipements, références, notices et problèmes passés restent organisés au même endroit.</p><p className="house-app-note">Photos, références, interventions et documents restent associés à votre maison.</p><ButtonLink href="/ma-maison" secondary>Découvrir Ma Maison</ButtonLink></div><div className="house-app-stage"><div className="house-app-photo"><Image src={photoAssets.houseLaundry.src} alt={photoAssets.houseLaundry.alt} fill sizes="(max-width: 850px) 100vw, 42vw" quality={78} loading="eager" /></div><div className="house-editorial-labels" aria-label="Éléments pouvant être associés à votre maison"><span>Équipements</span><span>Documents</span><span>Entretien</span><span>Historique</span></div></div></section>;
}

export function HeroSituationDemo() {
  const reduced = useReducedMotion();
  const [active, setActive] = useState(0);
  const [phase, setPhase] = useState(reduced ? 4 : 0);
  const [paused, setPaused] = useState(false);
  const scenario = scenarios[active];

  useEffect(() => { setPhase(reduced ? 4 : 0); }, [active, reduced]);
  useEffect(() => {
    if (reduced || paused) return;
    const phaseTimers = [
      window.setTimeout(() => setPhase(1), 800),
      window.setTimeout(() => setPhase(2), 1500),
      window.setTimeout(() => setPhase(3), 2250),
      window.setTimeout(() => setPhase(4), 3000),
    ];
    const rotation = window.setTimeout(() => setActive((current) => (current + 1) % scenarios.length), 6500);
    return () => { phaseTimers.forEach(window.clearTimeout); window.clearTimeout(rotation); };
  }, [active, paused, reduced]);

  const selectScenario = (index: number) => { setPaused(true); setActive(index); };
  return <div className="hero-situation-demo" onMouseEnter={() => setPaused(true)} onFocus={() => setPaused(true)}>
    <div className="hero-situation-photo">
      <Image key={scenario.id} src={scenario.image.src} alt={scenario.image.alt} fill priority={active === 0} sizes="(max-width: 850px) 100vw, 58vw" quality={80} className="hero-situation-image" />
      <div className="hero-situation-shade" />
      <ScenarioPanel scenario={scenario} phase={phase} />
    </div>
    <div className="hero-situation-nav" aria-label="Situations démontrées">
      {scenarios.map((item, index) => <button type="button" key={item.id} className={index === active ? 'is-active' : ''} aria-pressed={index === active} onClick={() => selectScenario(index)}><i />{item.label}</button>)}
    </div>
    <Link className="hero-situation-link" href={scenario.href}>Comprendre ce problème <span>→</span></Link>
  </div>;
}

export function ObservationDemoInteractive() {
  return <section id="observation-home" className="observation-demo interactive-demo">
    <div className="observation-heading"><span className="eyebrow">À TRAVERS NALVIUM</span><h2>NALVIUM ne donne pas une réponse magique.<br /><em>Il réduit l’incertitude, étape par étape.</em></h2></div>
    <div className="observation-stage interactive-observation-stage">
      <div className="interactive-demo-photo"><Image src={photoAssets.leakUnderSink.src} alt={photoAssets.leakUnderSink.alt} fill sizes="(max-width: 850px) 100vw, 52vw" quality={80} loading="eager" /><span className="demo-photo-label">UNE SITUATION RÉELLE</span></div>
      <div className="observation-panel interactive-panel"><div className="reasoning-step"><span>01</span><div><strong>Ce que vous observez</strong><p>La photo montre ce qui est visible, sans prétendre confirmer la cause.</p></div></div><div className="reasoning-step"><span>02</span><div><strong>Ce que NALVIUM cherche à préciser</strong><p>Quelques questions distinguent le symptôme, le moment où il apparaît et ce qui reste incertain.</p></div></div><div className="reasoning-step"><span>03</span><div><strong>La prochaine étape raisonnable</strong><p>Agir si c’est simple et sûr, ou s’arrêter quand le risque ou le doute augmente.</p></div></div></div>
    </div>
  </section>;
}

const wallItems = [
  { title: 'J’ai de l’eau sous l’évier', image: photoAssets.leakUnderSink, href: '/guides/fuite-sous-evier', size: 'wall-large' },
  { title: 'Mon robinet goutte', image: photoAssets.leakingFaucet, href: '/guides/robinet-qui-goutte', size: 'wall-wide' },
  { title: 'Mon lave-linge ne vidange plus', image: photoAssets.washingMachineDrain, href: '/guides/lave-linge-ne-vidange-plus', size: 'wall-small' },
  { title: 'La chasse d’eau coule', image: photoAssets.toilet, href: '/guides/chasse-eau-qui-coule', size: 'wall-small' },
  { title: 'Mon four ne chauffe plus', image: photoAssets.oven, href: '/guides/four-ne-chauffe-plus', size: 'wall-wide' },
];

export function SituationWall() {
  return <section className="situation-wall-section"><div className="situation-wall-heading"><span className="eyebrow">DES PROBLÈMES QUI ARRIVENT VRAIMENT</span><h2>Montrez ce que vous voyez.<br /><em>NALVIUM commence par là.</em></h2></div><div className="situation-wall">{wallItems.map((item) => <div key={item.title} className={`situation-tile ${item.size}`}><Link href={item.href}><Image src={item.image.src} alt={item.image.alt} fill sizes="(max-width: 600px) 100vw, (max-width: 1000px) 50vw, 25vw" quality={76} loading="eager" /><span className="situation-tile-shade" /><strong>{item.title}</strong><span className="situation-tile-cta">Comprendre ce problème <i>→</i></span></Link></div>)}</div></section>;
}

export function AnimatedMemory() {
  const entries = [['2026', 'Chauffe-eau', 'Référence enregistrée'], ['MAI', 'Fuite évier', 'Diagnostic conservé'], ['AOÛT', 'Lave-linge', 'Notice ajoutée'], ['AUJOURD’HUI', 'Ma Maison', 'Tout le contexte au même endroit']];
  return <div className="memory-line animated-memory">{entries.map(([date, title, text], index) => <Reveal key={title} delay={index * 100} className={`memory-entry ${index === entries.length - 1 ? 'current' : ''}`}><time>{date}</time><strong>{title}</strong><span>{text}</span></Reveal>)}</div>;
}
