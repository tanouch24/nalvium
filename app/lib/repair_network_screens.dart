import 'package:flutter/material.dart';

import 'api_client.dart';
import 'theme/nalvium_theme.dart';
import 'widgets/nalvium_widgets.dart';

class RepairNetworkScreen extends StatefulWidget {
  final String? sessionId;
  final String? equipmentId;
  final String? initialDescription;
  final List<String> mediaIds;
  const RepairNetworkScreen({super.key, this.sessionId, this.equipmentId, this.initialDescription, this.mediaIds = const []});
  @override
  State<RepairNetworkScreen> createState() => _RepairNetworkState();
}

class _RepairNetworkState extends State<RepairNetworkScreen> {
  final api = const ApiClient();
  late Future<Map<String, dynamic>> catalog;

  @override
  void initState() {
    super.initState();
    catalog = api.serviceCatalog();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Dépannage')),
    body: FutureBuilder<Map<String, dynamic>>(
      future: catalog,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return _ErrorState(onRetry: () => setState(() => catalog = api.serviceCatalog()));
        final offerings = (snapshot.data?['offerings'] as List? ?? []).whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList();
        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 32),
          children: [
            Text('Besoin d’un professionnel ?', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            const Text('Décrivez votre problème et vérifiez la couverture de votre secteur.', style: TextStyle(color: NalviumColors.textSecondary, height: 1.4)),
            const SizedBox(height: 22),
            FilledButton.icon(onPressed: () => _openRequest(context, offerings), icon: const Icon(Icons.build_outlined), label: const Text('Demander un dépannage')),
            const SizedBox(height: 30),
            const SectionLabel('Services disponibles'),
            const SizedBox(height: 10),
            if (offerings.isEmpty) const Text('Les services seront affichés ici lorsque le catalogue aura été configuré.', style: TextStyle(color: NalviumColors.textSecondary))
            else ...offerings.map<Widget>((item) => _OfferingTile(item: item, onTap: () => _openRequest(context, [item]))),
            const SizedBox(height: 28),
            const SectionLabel('Mes demandes'),
            const SizedBox(height: 10),
            FutureBuilder<List<Map<String, dynamic>>>(future: api.repairRequests(), builder: (context, requests) {
              if (requests.connectionState != ConnectionState.done) return const LinearProgressIndicator();
              if (requests.hasError || requests.data!.isEmpty) return const Text('Aucune demande pour le moment.', style: TextStyle(color: NalviumColors.textSecondary));
              return Column(
                children: requests.data!
                    .map<Widget>(
                      (item) => ListTile(
                        title: Text(item['description']?.toString() ?? 'Demande de dépannage'),
                        subtitle: Text(item['status']?.toString() ?? ''),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RepairRequestDetailScreen(request: item),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              );
            }),
          ],
        );
      },
    ),
  );

  void _openRequest(BuildContext context, List<Map<String, dynamic>> offerings) {
    if (offerings.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Aucun service n’est encore disponible.')));
      return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => RepairRequestFlow(api: api, offerings: offerings.first, sessionId: widget.sessionId, equipmentId: widget.equipmentId, initialDescription: widget.initialDescription, mediaIds: widget.mediaIds)));
  }
}

class _OfferingTile extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onTap;
  const _OfferingTile({required this.item, required this.onTap});
  @override
  Widget build(BuildContext context) => ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.handyman_outlined), title: Text(item['title']?.toString() ?? ''), subtitle: Text(_pricing(item), maxLines: 2), trailing: const Icon(Icons.chevron_right), onTap: onTap);
}

String _pricing(Map<String, dynamic> item) {
  switch (item['pricing_type']) {
    case 'FIXED': return item['price_cents'] == null ? 'Prix configuré par NALVIUM' : '${(item['price_cents'] as num) / 100} €';
    case 'STARTING_FROM': return item['price_cents'] == null ? 'À partir de —' : 'À partir de ${(item['price_cents'] as num) / 100} €';
    case 'RANGE': return 'Fourchette tarifaire à consulter';
    default: return 'Sur devis';
  }
}

class RepairRequestFlow extends StatefulWidget {
  final ApiClient api;
  final Map<String, dynamic> offerings;
  final String? sessionId;
  final String? equipmentId;
  final String? initialDescription;
  final List<String> mediaIds;
  const RepairRequestFlow({super.key, required this.api, required this.offerings, this.sessionId, this.equipmentId, this.initialDescription, this.mediaIds = const []});
  @override
  State<RepairRequestFlow> createState() => _RepairRequestFlowState();
}

class _RepairRequestFlowState extends State<RepairRequestFlow> {
  final postal = TextEditingController(), firstName = TextEditingController(), phone = TextEditingController(), description = TextEditingController(), window = TextEditingController();
  bool consent = false, busy = false;
  final selectedMediaIds = <String>{};
  List<Map<String, dynamic>> sessionMedia = [];
  Map<String, dynamic>? availability;
  @override
  void initState() {
    super.initState();
    description.text = widget.initialDescription ?? '';
    selectedMediaIds.addAll(widget.mediaIds);
    if (widget.sessionId != null) {
      widget.api.getSession(widget.sessionId!).then((session) {
        if (!mounted) return;
        setState(() => sessionMedia = (session['media'] as List? ?? []).whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList());
      }).catchError((_) {});
    }
  }
  @override
  void dispose() {
    for (final c in [postal, firstName, phone, description, window]) {
      c.dispose();
    }
    super.dispose();
  }
  Future<void> _check() async {
    if (postal.text.trim().length != 5) { _error('Saisissez un code postal français.'); return; }
    try { final result = await widget.api.serviceAvailability(postal.text.trim()); if (mounted) setState(() => availability = result); } catch (e) { if (mounted) _error(e.toString()); }
  }
  Future<void> _submit() async {
    if (!consent) { _error('Votre consentement est requis avant transmission.'); return; }
    if (availability?['covered'] != true) { _error('Cette zone n’est pas couverte actuellement.'); return; }
    if (firstName.text.trim().isEmpty || phone.text.trim().isEmpty || description.text.trim().isEmpty) { _error('Complétez les informations nécessaires.'); return; }
    setState(() => busy = true);
    try {
      final result = await widget.api.createRepairRequest({'service_offering_id': widget.offerings['id'], 'session_id': widget.sessionId, 'equipment_id': widget.equipmentId, 'first_name': firstName.text.trim(), 'phone': phone.text.trim(), 'postal_code': postal.text.trim(), 'description': description.text.trim(), 'desired_time_window': window.text.trim(), 'selected_media_ids': selectedMediaIds.toList(), 'consent': true, 'source': widget.sessionId == null ? 'direct' : 'diagnostic'});
      if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => RepairRequestDetailScreen(request: result)));
    } catch (e) { if (mounted) _error(e.toString()); } finally { if (mounted) setState(() => busy = false); }
  }
  void _error(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message.replaceFirst('Exception: ', ''))));
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Demander un dépannage')), body: ListView(padding: const EdgeInsets.fromLTRB(24, 18, 24, 32), children: [Text(widget.offerings['title']?.toString() ?? 'Service', style: Theme.of(context).textTheme.headlineMedium), const SizedBox(height: 8), Text(_pricing(widget.offerings), style: const TextStyle(color: NalviumColors.primaryLight)), const SizedBox(height: 24), const SectionLabel('Votre zone'), TextField(controller: postal, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Code postal')), const SizedBox(height: 8), OutlinedButton(onPressed: _check, child: const Text('Vérifier la couverture')), if (availability != null) ...[const SizedBox(height: 8), Text(availability!['coverage_message']?.toString() ?? '', style: TextStyle(color: availability!['covered'] == true ? NalviumColors.primaryLight : NalviumColors.textSecondary))], const SizedBox(height: 22), const SectionLabel('Votre problème'), TextField(controller: description, maxLines: 4, decoration: const InputDecoration(hintText: 'Décrivez brièvement ce qui se passe')), if (sessionMedia.isNotEmpty) ...[const SizedBox(height: 18), const SectionLabel('Photos transmises'), ...sessionMedia.map((item) { final id = item['id']?.toString() ?? ''; return CheckboxListTile(value: selectedMediaIds.contains(id), onChanged: (value) => setState(() => value == true ? selectedMediaIds.add(id) : selectedMediaIds.remove(id)), contentPadding: EdgeInsets.zero, title: Text(item['media_type']?.toString().startsWith('video/') == true ? 'Vidéo du problème' : 'Photo du problème'), subtitle: const Text('Sélection explicite requise'), controlAffinity: ListTileControlAffinity.leading); })], const SizedBox(height: 18), const SectionLabel('Coordonnées nécessaires'), TextField(controller: firstName, decoration: const InputDecoration(labelText: 'Prénom')), const SizedBox(height: 10), TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Téléphone')), const SizedBox(height: 10), TextField(controller: window, decoration: const InputDecoration(labelText: 'Créneau souhaité (facultatif)')), const SizedBox(height: 18), CheckboxListTile(value: consent, onChanged: (value) => setState(() => consent = value == true), contentPadding: EdgeInsets.zero, title: const Text('J’accepte que ces informations soient transmises pour traiter ma demande.'), subtitle: const Text('Aucune réservation, disponibilité ou prix final n’est garanti.'), controlAffinity: ListTileControlAffinity.leading), const SizedBox(height: 12), FilledButton(onPressed: busy ? null : _submit, child: Text(busy ? 'Envoi…' : 'Confirmer la demande'))]));
}

class RepairRequestDetailScreen extends StatelessWidget {
  final Map<String, dynamic> request;
  const RepairRequestDetailScreen({super.key, required this.request});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Ma demande')), body: ListView(padding: const EdgeInsets.all(24), children: [Text(request['description']?.toString() ?? '', style: Theme.of(context).textTheme.headlineMedium), const SizedBox(height: 12), StatusChip(label: request['status']?.toString() ?? 'REQUESTED', icon: Icons.info_outline, color: NalviumColors.primary), const SizedBox(height: 20), Text('Code postal : ${request['postal_code'] ?? ''}'), const SizedBox(height: 8), Text('Créneau souhaité : ${request['desired_time_window']?.toString().isEmpty == true ? 'non indiqué' : request['desired_time_window']}'), const SizedBox(height: 24), const Text('La demande reste soumise aux conditions et à la couverture réellement disponibles. Aucun artisan, rendez-vous ou montant final n’est confirmé sans mise à jour explicite.', style: TextStyle(color: NalviumColors.textSecondary, height: 1.4))]));
}

class _ErrorState extends StatelessWidget { final VoidCallback onRetry; const _ErrorState({required this.onRetry}); @override Widget build(BuildContext context) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [const Text('Le catalogue est indisponible.'), const SizedBox(height: 12), OutlinedButton(onPressed: onRetry, child: const Text('Réessayer'))])); }
