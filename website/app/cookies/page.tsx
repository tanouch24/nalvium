import { LegalPage, LegalSection } from '../legal';

export const metadata = {
  title: 'Cookies',
  description: 'Informations sur les cookies et technologies similaires utilisés par le site NALVIUM.',
  alternates: { canonical: '/cookies' },
};

export default function Cookies() {
  return <LegalPage eyebrow="NALVIUM · COOKIES" title="Cookies et technologies similaires" intro="Cette page décrit les cookies et outils de mesure actuellement identifiés sur le site public NALVIUM.">
    <LegalSection title="État actuel"><p>Le site public n’intègre pas Google Analytics, Meta Pixel, publicité, outil d’analytics tiers ou autre tracker tiers identifié.</p><p>Aucun contenu de diagnostic, média, conversation, numéro de téléphone ou adresse précise n’est envoyé à un outil d’analytics du site.</p></LegalSection>
    <LegalSection title="Technologies nécessaires"><p>Le navigateur, le rendu du site, la sécurité, la mise en cache et l’hébergement peuvent utiliser des mécanismes techniques nécessaires au fonctionnement. Ils ne sont pas utilisés ici pour établir un profil publicitaire.</p></LegalSection>
    <LegalSection title="Vos réglages"><p>Vous pouvez contrôler les cookies et le stockage local depuis les réglages de votre navigateur. Aucun consentement publicitaire n’est demandé par le site dans sa configuration actuelle.</p></LegalSection>
    <LegalSection title="Contact"><p>Pour toute question relative aux cookies ou aux traceurs : <a href="mailto:contact@nalvium.com">contact@nalvium.com</a>.</p></LegalSection>
  </LegalPage>;
}
