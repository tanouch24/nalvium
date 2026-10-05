import { LegalPage, LegalSection } from '../legal';

export const metadata = {
  title: 'Suppression du compte',
  description: 'Comment demander la suppression d’un compte ou de données NALVIUM.',
  alternates: { canonical: '/suppression-compte' },
};

export default function AccountDeletion() {
  return <LegalPage eyebrow="NALVIUM · CONTRÔLE DES DONNÉES" title="Suppression du compte" intro="Une page de référence pour les demandes de suppression liées à NALVIUM.">
    <LegalSection title="Depuis l’application"><p>Dans l’application : ouvrez <strong>Réglages</strong>, puis <strong>Mes données</strong> et <strong>Demander la suppression de mes données</strong>. La demande est préparée et traitée après vérification ; cette action ne déclare pas automatiquement les données supprimées.</p></LegalSection>
    <LegalSection title="Par email"><p>Vous pouvez aussi écrire à <a href="mailto:contact@nalvium.com">contact@nalvium.com</a> en indiquant votre identifiant d’installation et les données concernées. Des informations raisonnables peuvent être demandées pour vérifier l’identité.</p><p>Ne transmettez pas de mot de passe ni de photo sensible dans votre demande.</p></LegalSection>
    <LegalSection title="Informations complémentaires"><p>Consultez la <a href="/confidentialite">politique de confidentialité</a> pour connaître les droits applicables et les catégories de données pouvant être traitées.</p></LegalSection>
  </LegalPage>;
}
