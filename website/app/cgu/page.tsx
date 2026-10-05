import { LegalPage, LegalSection } from '../legal';

export const metadata = {
  title: 'Conditions générales d’utilisation',
  description: 'Conditions générales d’utilisation du service NALVIUM, édité par 3E Technology Ltd.',
  alternates: { canonical: '/cgu' },
};

export default function Cgu() {
  return <LegalPage eyebrow="NALVIUM · CONDITIONS" title="Conditions générales d’utilisation" intro="Les règles de base applicables à l’utilisation de NALVIUM, service gratuit destiné aux particuliers.">
    <LegalSection title="1. Objet"><p>Les présentes conditions encadrent l’accès au site public et l’utilisation des fonctions NALVIUM lorsqu’elles sont proposées. NALVIUM est édité par 3E Technology Ltd.</p></LegalSection>
    <LegalSection title="2. Description du service"><p>NALVIUM aide à observer un problème domestique, à formuler des hypothèses prudentes, à poser des questions, à proposer une vérification simple et à indiquer quand il faut s’arrêter ou demander un professionnel.</p><p>Le service est gratuit pour les particuliers dans la version actuellement documentée. Aucun abonnement payant, paiement d’intervention ou prix de dépannage n’est proposé ici.</p></LegalSection>
    <LegalSection title="3. Accès et informations fournies"><p>L’utilisateur doit fournir des informations aussi exactes que possible et ne doit pas envoyer de contenu qu’il n’est pas autorisé à partager. Il doit éviter les données personnelles inutiles dans les photos et descriptions.</p></LegalSection>
    <LegalSection title="4. Assistance automatisée et limites"><p>Les réponses peuvent être produites avec l’aide de systèmes automatisés. Elles peuvent être inexactes, incomplètes ou ne pas identifier l’origine réelle d’un problème.</p><p>Une observation ou une hypothèse n’est pas un diagnostic certain. L’utilisateur doit vérifier le contexte et ne pas poursuivre une action qui semble dangereuse ou qu’il ne comprend pas.</p></LegalSection>
    <LegalSection title="5. Sécurité"><p>NALVIUM fournit une assistance et une orientation ; il ne remplace pas un professionnel qualifié. Il peut recommander d’arrêter une procédure.</p><p>Gaz, incendie, fumée, électricité dangereuse, risque structurel, produit toxique, équipement sous pression et fuite importante nécessitent une prudence renforcée et peuvent imposer l’arrêt immédiat. Consultez <a href="/securite">la page Sécurité</a>.</p></LegalSection>
    <LegalSection title="6. Professionnels tiers"><p>NALVIUM ne prétend pas disposer aujourd’hui d’un réseau national, de professionnels disponibles en temps réel, de prix garantis ou de classements vérifiés.</p><p>Lorsqu’une fonctionnalité de transmission est proposée, les informations sont partagées uniquement selon le parcours et les consentements applicables. Le professionnel reste responsable de son intervention et de ses propres conditions.</p></LegalSection>
    <LegalSection title="7. Ma Maison"><p>Ma Maison peut permettre de conserver volontairement des informations sur des équipements, références, documents, photos ou problèmes passés. L’utilisateur conserve le contrôle prévu par les fonctions réellement disponibles. Aucune fonction d’export ou de suppression spécifique n’est promise ici au-delà des procédures confirmées.</p></LegalSection>
    <LegalSection title="8. Propriété intellectuelle"><p>Le nom NALVIUM, ses éléments graphiques, contenus et composants sont protégés par les droits applicables. Ils ne peuvent pas être réutilisés ou copiés hors des usages autorisés.</p></LegalSection>
    <LegalSection title="9. Disponibilité et usage abusif"><p>Le service peut évoluer, être interrompu pour maintenance ou devenir temporairement indisponible. L’utilisateur ne doit pas tenter de contourner une mesure de sécurité, perturber le service ou utiliser NALVIUM pour une activité illégale.</p></LegalSection>
    <LegalSection title="10. Données personnelles"><p>Les traitements de données sont décrits dans la <a href="/confidentialite">politique de confidentialité</a>. Les cookies et outils similaires sont décrits dans la <a href="/cookies">politique cookies</a>.</p></LegalSection>
    <LegalSection title="11. Modification des conditions"><p>Les conditions peuvent être modifiées pour refléter l’évolution du service ou des obligations applicables. La date de mise à jour sera indiquée sur cette page.</p></LegalSection>
    <LegalSection title="12. Contact"><p>Pour toute question relative au service ou à ces conditions : <a href="mailto:contact@nalvium.com">contact@nalvium.com</a>.</p></LegalSection>
  </LegalPage>;
}
