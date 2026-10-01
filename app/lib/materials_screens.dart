import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'api_client.dart';
import 'theme/nalvium_theme.dart';
import 'widgets/nalvium_widgets.dart';

class RequiredItemsScreen extends StatefulWidget {
  final List<dynamic> items;
  final ApiClient api;
  final VoidCallback onContinue;
  final String? postalCode;
  final String? city;
  const RequiredItemsScreen({super.key, required this.items, required this.api, required this.onContinue, this.postalCode, this.city});

  @override
  State<RequiredItemsScreen> createState() => _RequiredItemsScreenState();
}

class _RequiredItemsScreenState extends State<RequiredItemsScreen> {
  late final List<bool> owned = List<bool>.filled(widget.items.length, false);

  bool get canContinue => widget.items.asMap().entries.every((entry) =>
      entry.value is! Map || entry.value['required'] != true || owned[entry.key]);

  String _label(Map item) => (item['generic_name'] ?? item['name'] ?? 'Matériel').toString();
  String _type(Map item) => (item['type'] ?? 'TOOL').toString();

  Future<void> _search(int index, Map item, String mode) async {
    try {
      final result = await widget.api.commerceSearch(
        mode: mode,
        itemType: _type(item),
        genericName: _label(item),
        purchaseSearchQuery: item['purchase_search_query']?.toString(),
        postalCode: widget.postalCode,
        city: widget.city,
      );
      final url = Uri.tryParse(result['search_url']?.toString() ?? '');
      if (url == null || !mounted) return;
      final opened = await launchUrl(url, mode: LaunchMode.externalApplication);
      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('La recherche externe n’a pas pu être ouverte.')));
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('La recherche n’est pas disponible pour le moment.')));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Avant de commencer')),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            children: [
              Text('Matériel nécessaire', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              const Text('Vérifiez ce que vous avez avant de lancer cette étape.', style: TextStyle(color: NalviumColors.textSecondary)),
              const SizedBox(height: 20),
              ...widget.items.asMap().entries.map((entry) {
                final item = entry.value is Map ? Map<String, dynamic>.from(entry.value as Map) : <String, dynamic>{'name': entry.value.toString(), 'required': true, 'type': 'TOOL'};
                final required = item['required'] == true;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SurfaceCard(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      CheckboxListTile(
                        value: owned[entry.key],
                        onChanged: (value) => setState(() => owned[entry.key] = value ?? false),
                        contentPadding: EdgeInsets.zero,
                        title: Text(_label(item)),
                        subtitle: Text(required ? 'Obligatoire' : 'Facultatif'),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                      if (item['description'] != null) Text(item['description'].toString(), style: const TextStyle(color: NalviumColors.textSecondary)),
                      if (!owned[entry.key]) ...[
                        const SizedBox(height: 8),
                        Wrap(spacing: 8, runSpacing: 8, children: [
                          OutlinedButton.icon(onPressed: () => _search(entry.key, item, 'nearby'), icon: const Icon(Icons.storefront_outlined), label: const Text('Trouver près de moi')),
                          OutlinedButton.icon(onPressed: () => _search(entry.key, item, 'online'), icon: const Icon(Icons.open_in_new), label: const Text('Acheter en ligne')),
                        ]),
                      ],
                    ]),
                  ),
                );
              }),
              const SizedBox(height: 12),
              FilledButton(onPressed: canContinue ? widget.onContinue : null, child: const Text("J’ai le matériel — Continuer")),
            ],
          ),
        ),
      );
}
