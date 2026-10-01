import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart';
import 'theme/nalvium_theme.dart';
import 'widgets/nalvium_widgets.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});
  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final api = const ApiClient();
  bool loading = true;
  bool enabled = false;
  bool providerReady = false;
  int amountCents = 500;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final config = await api.supportConfig();
      if (!mounted) return;
      setState(() {
        enabled = config['enabled'] == true;
        providerReady = enabled && config['provider'] != null && config['provider'] != 'REQUIRES_SERVER_PROVIDER';
        final amounts = (config['amounts_cents'] as List? ?? []).whereType<num>().map((value) => value.toInt()).toList();
        if (amounts.isNotEmpty && !amounts.contains(amountCents)) amountCents = amounts.first;
      });
    } catch (_) {
      // The safe default is disabled; the page remains usable offline.
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Soutenir Nalvium')),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      children: [
        Text('Nalvium est gratuit', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 12),
        const Text('Si l’application vous a aidé, vous pouvez contribuer volontairement à son développement et à son accessibilité.', style: TextStyle(color: NalviumColors.textSecondary, height: 1.45)),
        const SizedBox(height: 28),
        if (loading) const LinearProgressIndicator()
        else if (!providerReady) const SurfaceCard(child: Text('Les contributions ne sont pas encore activées dans cette version. Nalvium reste entièrement gratuit.', style: TextStyle(height: 1.4)))
        else ...[
          const SectionLabel('Choisir un montant'),
          const SizedBox(height: 10),
          Wrap(spacing: 10, children: [100, 500].map((value) => ChoiceChip(label: Text('${value ~/ 100} €'), selected: amountCents == value, onSelected: (_) => setState(() => amountCents = value))).toList()),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: () {}, child: const Text('Autre montant')),
          const SizedBox(height: 16),
          FilledButton(onPressed: () {}, child: const Text('Soutenir Nalvium')),
        ],
        const SizedBox(height: 18),
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Pas maintenant')),
      ],
    ),
  );
}

class SupportResolutionPrompt extends StatefulWidget {
  final String repairKey;
  const SupportResolutionPrompt({super.key, required this.repairKey});
  @override
  State<SupportResolutionPrompt> createState() => _SupportResolutionPromptState();
}

class _SupportResolutionPromptState extends State<SupportResolutionPrompt> {
  bool visible = false;
  bool dismissed = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'nalvium_support_prompt_${widget.repairKey}';
    if (prefs.getBool(key) == true) return;
    await prefs.setBool(key, true);
    if (mounted) setState(() => visible = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!visible || dismissed) return const SizedBox.shrink();
    return SurfaceCard(
      color: NalviumColors.surfaceAlternative,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Votre problème est résolu', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        const Text('Nalvium est gratuit. Votre soutien peut nous aider à améliorer l’application et à la garder accessible gratuitement.', style: TextStyle(color: NalviumColors.textSecondary, height: 1.35)),
        const SizedBox(height: 12),
        OutlinedButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportScreen())), child: const Text('Soutenir Nalvium')),
        TextButton(onPressed: () => setState(() => dismissed = true), child: const Text('Pas maintenant')),
      ]),
    );
  }
}
