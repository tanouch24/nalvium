import 'package:flutter/material.dart';

import 'ads_service.dart';
import 'theme/nalvium_theme.dart';
import 'support_screens.dart';
import 'widgets/nalvium_widgets.dart';

class NalviumSettingsScreen extends StatefulWidget {
  const NalviumSettingsScreen({super.key});
  @override
  State<NalviumSettingsScreen> createState() => _NalviumSettingsState();
}

class _NalviumSettingsState extends State<NalviumSettingsScreen> {
  bool analytics = false;
  bool advertising = false;

  void _document(String title, String body) => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => LegalDocumentScreen(title: title, body: body),
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Réglages')),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      children: [
        Text(
          'Confidentialité et à propos',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        const Text(
          'Vous gardez le contrôle des usages non essentiels. Les médias et conversations restent privés par défaut.',
          style: TextStyle(color: NalviumColors.textSecondary, height: 1.4),
        ),
        const SizedBox(height: 24),
        ListTile(
          leading: const Icon(Icons.privacy_tip_outlined),
          title: const Text('Politique de confidentialité'),
          onTap: () => _document('Politique de confidentialité', _privacyText),
        ),
        ListTile(
          leading: const Icon(Icons.favorite_border),
          title: const Text('Soutenir Nalvium'),
          subtitle: const Text('Contribution volontaire, sans avantage ni fonctionnalité payante.'),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportScreen())),
        ),
        ListTile(
          leading: const Icon(Icons.description_outlined),
          title: const Text('Conditions générales'),
          onTap: () => _document('Conditions générales', _termsText),
        ),
        ListTile(
          leading: const Icon(Icons.forum_outlined),
          title: const Text('Règles de la Communauté'),
          onTap: () => _document('Règles de la Communauté', _communityText),
        ),
        const SizedBox(height: 18),
        const SectionLabel('Consentements'),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: analytics,
          onChanged: (value) => setState(() => analytics = value),
          title: const Text('Analytics facultatif'),
          subtitle: const Text(
            'Aucun contenu de diagnostic, média ou conversation.',
          ),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.tune_outlined),
          title: const Text('Gérer les choix publicitaires'),
          subtitle: const Text(
            'Le formulaire Google est disponible uniquement si les publicités sont activées pour cet environnement.',
          ),
          onTap: () async {
            if (!AdsService.instance.enabled) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Les publicités sont désactivées dans cette version.')),
              );
              return;
            }
            await AdsService.instance.showPrivacyOptions();
          },
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: advertising,
          onChanged: (value) => setState(() => advertising = value),
          title: const Text('Publicité et attribution'),
          subtitle: const Text(
            'Désactivées par défaut dans la première release.',
          ),
        ),
        const SizedBox(height: 18),
        const SectionLabel('Mes données'),
        ListTile(
          leading: const Icon(Icons.delete_outline),
          title: const Text('Demander la suppression de mes données'),
          subtitle: const Text(
            'La demande est préparée ; rien n’est déclaré supprimé avant traitement.',
          ),
          onTap: () => showDialog<void>(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Demande de suppression'),
              content: const Text(
                'Écrivez à contact@nalvium.com en indiquant votre identifiant d’installation. La suppression sera confirmée après traitement.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Fermer'),
                ),
              ],
            ),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.mail_outline),
          title: const Text('Contact'),
          subtitle: const Text(
            'contact@nalvium.com — à confirmer avant publication',
          ),
          onTap: () {},
        ),
        const SizedBox(height: 24),
        const Text(
          'NALVIUM utilise des systèmes automatisés pour analyser les informations que vous fournissez. Une réponse peut être inexacte ; respectez toujours les arrêts de sécurité.',
          style: TextStyle(color: NalviumColors.textTertiary, height: 1.4),
        ),
      ],
    ),
  );
}

class LegalDocumentScreen extends StatelessWidget {
  final String title;
  final String body;
  const LegalDocumentScreen({
    super.key,
    required this.title,
    required this.body,
  });
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Text(
        body,
        style: const TextStyle(color: NalviumColors.textSecondary, height: 1.5),
      ),
    ),
  );
}

const _privacyText =
    'NALVIUM traite les données nécessaires aux fonctions que vous utilisez : identité invité, médias privés, diagnostics, assistant, équipements, documents, historique et contenus communautaires volontairement publiés. Les bases légales, durées, sous-traitants et informations éditeur doivent être validés avant publication. Vous pouvez demander l’accès, la rectification ou la suppression à contact@nalvium.com.';
const _termsText =
    'NALVIUM est un service d’assistance et d’orientation. Ses analyses peuvent être inexactes et ne garantissent ni diagnostic, ni réparation, ni intervention. Respectez les safety stops. Un dossier professionnel READY ne signifie ni réservation, ni devis, ni prix, ni disponibilité garantie.';
const _communityText =
    'Les publications sont des expériences utilisateur et non des instructions validées par NALVIUM. Les conseils dangereux, le spam, le harcèlement et les données personnelles de tiers sont interdits. Un contenu peut être signalé, restreint ou supprimé.';
