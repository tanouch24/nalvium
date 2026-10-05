import { LegalPage, LegalSection } from '../legal';

export const metadata = {
  title: 'Mentions légales',
  description: 'Informations sur la marque NALVIUM et la société éditrice 3E Technology Ltd.',
  alternates: { canonical: '/mentions-legales' },
};

export default function MentionsLegales() {
  return <LegalPage eyebrow="NALVIUM · INFORMATIONS LÉGALES" title="Mentions légales" intro="Les informations d’identification de la marque NALVIUM et de sa société éditrice, 3E Technology Ltd.">
    <LegalSection title="Marque et éditeur"><p><strong>NALVIUM</strong> est la marque du service.</p><p>Le service est édité et exploité par <strong>3E Technology Ltd</strong>, société de droit anglais enregistrée sous le numéro <strong>17179077</strong>.</p><p>Siège social : 71-75 Shelton Street, Covent Garden, Londres WC2H 9JQ, Royaume-Uni.</p><p>Directeur de publication : le représentant légal de la société 3E Technology Ltd.</p><p>Contact NALVIUM : <a href="mailto:contact@nalvium.com">contact@nalvium.com</a>.</p></LegalSection>
    <LegalSection title="Activité du service"><p>NALVIUM est une application mobile gratuite destinée aux particuliers. Elle aide à observer un problème domestique, à poser des questions et à effectuer uniquement des vérifications raisonnablement sûres.</p><p>NALVIUM ne remplace pas un professionnel qualifié et ne constitue pas, à lui seul, un diagnostic professionnel.</p></LegalSection>
  </LegalPage>;
}
