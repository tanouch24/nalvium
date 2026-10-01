import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'api_client.dart';
import 'equipment_photo_store.dart';
import 'history_store.dart';
import 'main.dart' show AssistantScreen, PreviewScreen;
import 'theme/nalvium_theme.dart';
import 'widgets/nalvium_widgets.dart';

String _value(Map<String, dynamic> data, String key) =>
    data[key]?.toString() ?? '';

String _equipmentLabel(Map<String, dynamic> equipment) =>
    _value(equipment, 'display_name').isNotEmpty
    ? _value(equipment, 'display_name')
    : 'Équipement domestique';

class EquipmentAddScreen extends StatefulWidget {
  final ApiClient api;
  final HistoryStore history;
  const EquipmentAddScreen({
    super.key,
    required this.api,
    required this.history,
  });

  @override
  State<EquipmentAddScreen> createState() => _EquipmentAddScreenState();
}

class _EquipmentAddScreenState extends State<EquipmentAddScreen> {
  final picker = ImagePicker();
  bool busy = false;

  Future<void> _photo(ImageSource source) async {
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 2048,
      maxHeight: 2048,
      imageQuality: 88,
    );
    if (picked == null || !mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EquipmentPhotoIdentifyScreen(
          api: widget.api,
          history: widget.history,
          picked: picked,
        ),
      ),
    );
  }

  void _manual() => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => EquipmentConfirmationScreen(
        api: widget.api,
        history: widget.history,
        identification: const {},
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Ajouter un équipement')),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        children: [
          const SectionLabel('Ma maison'),
          const SizedBox(height: 12),
          Text(
            'Qu’est-ce que vous souhaitez conserver ?',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 10),
          Text(
            'Une photo suffit pour commencer. Vous pourrez corriger chaque information avant l’enregistrement.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 30),
          _AddAction(
            icon: Icons.photo_camera_outlined,
            title: 'Prendre une photo',
            subtitle: 'La meilleure façon d’identifier l’équipement',
            onTap: busy ? null : () => _photo(ImageSource.camera),
            primary: true,
          ),
          const SizedBox(height: 12),
          _AddAction(
            icon: Icons.photo_library_outlined,
            title: 'Choisir une photo',
            subtitle: 'Depuis votre galerie',
            onTap: busy ? null : () => _photo(ImageSource.gallery),
          ),
          const SizedBox(height: 12),
          _AddAction(
            icon: Icons.edit_outlined,
            title: 'Saisir manuellement',
            subtitle: 'Si vous connaissez déjà l’équipement',
            onTap: busy ? null : _manual,
          ),
        ],
      ),
    ),
  );
}

class _AddAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool primary;
  const _AddAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.primary = false,
  });
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(NalviumRadii.md),
    child: Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: primary
            ? NalviumColors.primary.withValues(alpha: .16)
            : NalviumColors.surface,
        borderRadius: BorderRadius.circular(NalviumRadii.md),
        border: Border.all(
          color: primary
              ? NalviumColors.primary.withValues(alpha: .45)
              : NalviumColors.border,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: primary ? NalviumColors.primaryLight : NalviumColors.info,
            size: 28,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: NalviumColors.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: NalviumColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: NalviumColors.textTertiary,
          ),
        ],
      ),
    ),
  );
}

class EquipmentPhotoIdentifyScreen extends StatefulWidget {
  final ApiClient api;
  final HistoryStore history;
  final XFile picked;
  const EquipmentPhotoIdentifyScreen({
    super.key,
    required this.api,
    required this.history,
    required this.picked,
  });
  @override
  State<EquipmentPhotoIdentifyScreen> createState() =>
      _EquipmentPhotoIdentifyState();
}

class _EquipmentPhotoIdentifyState extends State<EquipmentPhotoIdentifyScreen> {
  bool busy = false;
  Future<void> _identify() async {
    setState(() => busy = true);
    try {
      final session = await widget.api.createSession();
      final mediaId = await widget.api.upload(widget.picked, session);
      final result = await widget.api.identifyEquipment(mediaId: mediaId);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => EquipmentConfirmationScreen(
            api: widget.api,
            history: widget.history,
            identification: result,
            mediaId: mediaId,
            localFile: File(widget.picked.path),
            sessionId: session,
          ),
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Identifier cet équipement')),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionLabel('Photo réelle'),
            const SizedBox(height: 12),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(NalviumRadii.lg),
                child: SizedBox(
                  width: double.infinity,
                  child: Image.file(
                    File(widget.picked.path),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'La photo sera analysée sans créer automatiquement de fiche.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: busy ? null : _identify,
                icon: busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.auto_awesome),
                label: Text(
                  busy ? 'Identification…' : 'Identifier cet équipement',
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class EquipmentConfirmationScreen extends StatefulWidget {
  final ApiClient api;
  final HistoryStore history;
  final Map<String, dynamic> identification;
  final String? mediaId;
  final String? sessionId;
  final File? localFile;
  final Map<String, dynamic>? existing;
  const EquipmentConfirmationScreen({
    super.key,
    required this.api,
    required this.history,
    required this.identification,
    this.mediaId,
    this.sessionId,
    this.localFile,
    this.existing,
  });
  @override
  State<EquipmentConfirmationScreen> createState() =>
      _EquipmentConfirmationState();
}

class _EquipmentConfirmationState extends State<EquipmentConfirmationScreen> {
  late final TextEditingController name,
      category,
      brand,
      model,
      serial,
      room,
      notes;
  bool saving = false;
  @override
  void initState() {
    super.initState();
    final d = widget.existing ?? widget.identification;
    String nested(String key) => d[key] is Map
        ? _value(Map<String, dynamic>.from(d[key] as Map), 'value')
        : _value(d, key);
    final detectedCategory = _value(d, 'category');
    final suggested = _value(d, 'suggested_name');
    name = TextEditingController(
      text: _value(d, 'display_name').isNotEmpty
          ? _value(d, 'display_name')
          : suggested,
    );
    category = TextEditingController(
      text: detectedCategory.isNotEmpty ? detectedCategory : 'other_equipment',
    );
    brand = TextEditingController(text: nested('brand'));
    model = TextEditingController(text: nested('model'));
    serial = TextEditingController(text: nested('serial_number'));
    room = TextEditingController(text: _value(d, 'room'));
    notes = TextEditingController(text: _value(d, 'notes'));
  }

  @override
  void dispose() {
    for (final c in [name, category, brand, model, serial, room, notes]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save({bool allowDuplicate = false}) async {
    if (name.text.trim().isEmpty || category.text.trim().isEmpty) return;
    if (widget.existing == null && !allowDuplicate) {
      final existing = await widget.api.listEquipment();
      final duplicate = existing.any((item) {
        final sameCategory = _value(item, 'category') == category.text.trim();
        final sameBrand =
            brand.text.trim().isNotEmpty &&
            _value(item, 'brand').toLowerCase() ==
                brand.text.trim().toLowerCase();
        final sameName =
            _value(item, 'display_name').toLowerCase() ==
            name.text.trim().toLowerCase();
        return sameName || (sameCategory && sameBrand);
      });
      if (duplicate && mounted) {
        final addAnyway = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Équipement similaire déjà enregistré'),
            content: const Text(
              'Cet équipement ressemble à une fiche existante. Vérifiez-la avant de créer un doublon.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Ajouter quand même'),
              ),
            ],
          ),
        );
        if (addAnyway != true) return;
      }
    }
    setState(() => saving = true);
    try {
      final data = {
        'display_name': name.text.trim(),
        'category': category.text.trim(),
        'brand': brand.text.trim().isEmpty ? null : brand.text.trim(),
        'model': model.text.trim().isEmpty ? null : model.text.trim(),
        'serial_number': serial.text.trim().isEmpty ? null : serial.text.trim(),
        'room': room.text.trim().isEmpty ? null : room.text.trim(),
        'notes': notes.text.trim().isEmpty ? null : notes.text.trim(),
        'primary_media_id': widget.mediaId,
        'identification_source': widget.mediaId == null ? 'manual' : 'photo',
      };
      final equipment = widget.existing == null
          ? await widget.api.createEquipment(data)
          : await widget.api.updateEquipment(
              widget.existing!['id'].toString(),
              data,
            );
      if (widget.mediaId != null && widget.localFile != null) {
        await EquipmentPhotoStore().save(
          widget.mediaId!,
          widget.localFile!.path,
        );
      }
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => EquipmentDetailScreen(
            api: widget.api,
            history: widget.history,
            equipment: equipment,
            localFile: widget.localFile,
          ),
        ),
        (route) => route.isFirst,
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    String? hint,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextField(
      controller: controller,
      decoration: InputDecoration(labelText: label, hintText: hint),
    ),
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Vérifier les informations')),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        children: [
          if (widget.localFile != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(NalviumRadii.md),
              child: SizedBox(
                height: 190,
                child: Image.file(widget.localFile!, fit: BoxFit.cover),
              ),
            ),
          if (widget.identification['object_type'] == 'not_equipment')
            Padding(
              padding: const EdgeInsets.only(top: 18),
              child: Text(
                'Je ne reconnais pas ici un équipement de la maison à enregistrer.',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          if (widget.identification['needs_nameplate_photo'] == true)
            Padding(
              padding: const EdgeInsets.only(top: 18),
              child: Text(
                'Je reconnais l’équipement, mais une photo de la plaque signalétique peut préciser le modèle. Vous pourrez l’ajouter depuis sa fiche.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          const SizedBox(height: 22),
          _field('Nom', name, hint: 'Ex. Machine à laver'),
          _field('Catégorie', category),
          _field('Marque', brand),
          _field('Modèle', model),
          _field('N° de série (privé)', serial),
          _field('Pièce', room, hint: 'Ex. Buanderie'),
          _field('Notes', notes),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed:
                  saving ||
                      widget.identification['object_type'] == 'not_equipment'
                  ? null
                  : _save,
              child: Text(
                saving
                    ? 'Enregistrement…'
                    : widget.existing == null
                    ? 'Ajouter à Ma Maison'
                    : 'Enregistrer',
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class EquipmentDetailScreen extends StatefulWidget {
  final ApiClient api;
  final HistoryStore history;
  final Map<String, dynamic> equipment;
  final File? localFile;
  const EquipmentDetailScreen({
    super.key,
    required this.api,
    required this.history,
    required this.equipment,
    this.localFile,
  });
  @override
  State<EquipmentDetailScreen> createState() => _EquipmentDetailState();
}

class _EquipmentDetailState extends State<EquipmentDetailScreen> {
  late Map<String, dynamic> equipment;
  File? localFile;
  late Future<List<Map<String, dynamic>>> timelineFuture;
  @override
  void initState() {
    super.initState();
    equipment = widget.equipment;
    localFile = widget.localFile;
    timelineFuture = _loadTimeline();
    _loadPhoto();
  }

  Future<void> _loadPhoto() async {
    final path = await EquipmentPhotoStore().pathFor(
      _value(equipment, 'primary_media_id'),
    );
    if (mounted && localFile == null && path != null) {
      setState(() => localFile = File(path));
    }
  }

  Future<void> _diagnose() async {
    final session = await widget.api.createSession(
      equipmentId: equipment['id'].toString(),
    );
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EquipmentDiagnosticStart(
          api: widget.api,
          history: widget.history,
          sessionId: session,
          equipmentId: equipment['id'].toString(),
        ),
      ),
    );
  }

  Future<void> _addNameplatePhoto() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.camera,
      maxWidth: 2048,
      maxHeight: 2048,
      imageQuality: 88,
    );
    if (picked == null || !mounted) return;
    try {
      final session = await widget.api.createSession(
        equipmentId: equipment['id'].toString(),
      );
      final mediaId = await widget.api.upload(picked, session);
      final result = await widget.api.identifyEquipment(mediaId: mediaId);
      final brand = result['brand'] is Map
          ? _value(Map<String, dynamic>.from(result['brand'] as Map), 'value')
          : '';
      final model = result['model'] is Map
          ? _value(Map<String, dynamic>.from(result['model'] as Map), 'value')
          : '';
      final patch = <String, dynamic>{};
      if (brand.isNotEmpty) patch['brand'] = brand;
      if (model.isNotEmpty) patch['model'] = model;
      if (patch.isNotEmpty) {
        await widget.api.updateEquipment(equipment['id'].toString(), patch);
      }
      await widget.api.addEquipmentMedia(
        equipment['id'].toString(),
        mediaId,
        mediaType: 'nameplate',
      );
      final updated = await widget.api.getEquipment(equipment['id'].toString());
      await EquipmentPhotoStore().save(mediaId, picked.path);
      if (mounted) setState(() => equipment = updated);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  Future<void> _edit() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EquipmentConfirmationScreen(
          api: widget.api,
          history: widget.history,
          identification: equipment,
          existing: equipment,
          localFile: localFile,
          mediaId: _value(equipment, 'primary_media_id'),
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _refresh() async {
    try {
      final updated = await widget.api.getEquipment(equipment['id'].toString());
      if (mounted) {
        setState(() {
          equipment = updated;
          timelineFuture = _loadTimeline();
        });
      }
    } catch (_) {}
  }

  Future<List<Map<String, dynamic>>> _loadTimeline() async {
    try {
      return await widget.api.equipmentTimeline(equipment['id'].toString());
    } catch (_) {
      return const [];
    }
  }

  Future<void> _addDocument() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EquipmentDocumentAddScreen(
          api: widget.api,
          equipmentId: equipment['id'].toString(),
        ),
      ),
    );
    if (mounted) _refresh();
  }

  Future<void> _addWarranty() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WarrantyFormScreen(
          api: widget.api,
          equipmentId: equipment['id'].toString(),
        ),
      ),
    );
    if (mounted) _refresh();
  }

  Future<void> _addMaintenance() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MaintenanceFormScreen(
          api: widget.api,
          equipmentId: equipment['id'].toString(),
        ),
      ),
    );
    if (mounted) _refresh();
  }

  Future<void> _delete() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer cet équipement ?'),
        content: const Text(
          'Son historique de réparation sera conservé, mais ne sera plus rattaché à cette fiche.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (yes != true) return;
    await widget.api.deleteEquipment(equipment['id'].toString());
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final repairs = (equipment['repairs'] as List? ?? const [])
        .whereType<Map>()
        .toList();
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            tooltip: 'Modifier',
            onPressed: _edit,
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'Supprimer',
            onPressed: _delete,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(NalviumRadii.lg),
              child: SizedBox(
                height: 230,
                child: localFile != null
                    ? Image.file(localFile!, fit: BoxFit.cover)
                    : Container(
                        color: NalviumColors.surfaceAlternative,
                        child: const Icon(
                          Icons.home_repair_service_outlined,
                          size: 56,
                          color: NalviumColors.primaryLight,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              _equipmentLabel(equipment),
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 10),
            Text(
              [
                _value(equipment, 'brand'),
                _value(equipment, 'model'),
                _value(equipment, 'room'),
              ].where((s) => s.isNotEmpty).join('  •  '),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (_value(equipment, 'purchase_date').isNotEmpty ||
                _value(equipment, 'seller').isNotEmpty ||
                equipment['purchase_price'] != null) ...[
              const SizedBox(height: 24),
              const SectionLabel('Informations'),
              const SizedBox(height: 10),
              if (_value(equipment, 'purchase_date').isNotEmpty)
                _InfoRow(
                  title: 'Date d’achat',
                  value: _value(equipment, 'purchase_date'),
                ),
              if (_value(equipment, 'seller').isNotEmpty)
                _InfoRow(title: 'Vendeur', value: _value(equipment, 'seller')),
              if (equipment['purchase_price'] != null)
                _InfoRow(
                  title: 'Prix',
                  value:
                      '${equipment['purchase_price']} ${_value(equipment, 'purchase_currency')}',
                ),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AssistantScreen(
                    contextType: 'equipment',
                    contextId: equipment['id'].toString(),
                    equipmentId: equipment['id'].toString(),
                  ),
                ),
              ),
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Demander à Nalvium'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _diagnose,
              icon: const Icon(Icons.report_problem_outlined),
              label: const Text('Signaler un problème'),
            ),
            TextButton.icon(
              onPressed: _addNameplatePhoto,
              icon: const Icon(Icons.document_scanner_outlined),
              label: const Text('Photographier la plaque signalétique'),
            ),
            const SizedBox(height: 28),
            _DetailSectionHeader(title: 'Documents', onAdd: _addDocument),
            const SizedBox(height: 8),
            ...((equipment['documents'] as List? ?? const [])
                    .whereType<Map>()
                    .isEmpty
                ? [
                    const _DetailEmpty(
                      text: 'Aucune notice, facture ou garantie ajoutée.',
                    ),
                  ]
                : (equipment['documents'] as List)
                      .whereType<Map>()
                      .map(
                        (document) => _DocumentRow(
                          document: Map<String, dynamic>.from(document),
                          onDelete: () async {
                            final yes = await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('Supprimer ce document ?'),
                                content: const Text(
                                  'Le document privé sera supprimé de cet équipement.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Annuler'),
                                  ),
                                  FilledButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text('Supprimer'),
                                  ),
                                ],
                              ),
                            );
                            if (yes == true) {
                              await widget.api.deleteDocument(
                                document['id'].toString(),
                              );
                              if (mounted) _refresh();
                            }
                          },
                        ),
                      )
                      .toList()),
            const SizedBox(height: 24),
            _DetailSectionHeader(title: 'Garantie', onAdd: _addWarranty),
            const SizedBox(height: 8),
            ...((equipment['warranties'] as List? ?? const [])
                    .whereType<Map>()
                    .isEmpty
                ? [const _DetailEmpty(text: 'Aucune garantie enregistrée.')]
                : (equipment['warranties'] as List)
                      .whereType<Map>()
                      .map(
                        (item) => _InfoRow(
                          title: _text(
                            Map<String, dynamic>.from(item),
                            'provider',
                            fallback: 'Garantie enregistrée',
                          ),
                          value:
                              'Jusqu’au ${_text(Map<String, dynamic>.from(item), 'end_date', fallback: 'date inconnue')}',
                        ),
                      )
                      .toList()),
            const SizedBox(height: 24),
            _DetailSectionHeader(title: 'Entretien', onAdd: _addMaintenance),
            const SizedBox(height: 8),
            ...((equipment['maintenance'] as List? ?? const [])
                    .whereType<Map>()
                    .isEmpty
                ? [const _DetailEmpty(text: 'Aucun entretien enregistré.')]
                : (equipment['maintenance'] as List)
                      .whereType<Map>()
                      .map(
                        (item) => _InfoRow(
                          title: _text(
                            Map<String, dynamic>.from(item),
                            'title',
                          ),
                          value: _maintenanceLabel(
                            Map<String, dynamic>.from(item),
                          ),
                        ),
                      )
                      .toList()),
            if (_value(equipment, 'serial_number').isNotEmpty) ...[
              const SizedBox(height: 24),
              const SectionLabel('Information privée'),
              const SizedBox(height: 8),
              Text(
                'N° de série  ${_value(equipment, 'serial_number')}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            if (repairs.isNotEmpty) ...[
              const SizedBox(height: 32),
              const SectionLabel('Historique'),
              const SizedBox(height: 12),
              ...repairs.map(
                (repair) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    _value(Map<String, dynamic>.from(repair), 'title'),
                  ),
                  subtitle: Text(
                    _value(Map<String, dynamic>.from(repair), 'status'),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: NalviumColors.textTertiary,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 28),
            const SectionLabel('Historique de la maison'),
            const SizedBox(height: 10),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: timelineFuture,
              builder: (context, snapshot) {
                final events = snapshot.data ?? const <Map<String, dynamic>>[];
                if (events.isEmpty) {
                  return const _DetailEmpty(
                    text: 'L’historique apparaîtra ici après vos premiers échanges.',
                  );
                }
                return Column(
                  children: events.take(12).map((event) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.radio_button_checked,
                        size: 14,
                        color: NalviumColors.primaryLight,
                      ),
                      title: Text(event['title']?.toString() ?? 'Événement'),
                      subtitle: Text(
                        (event['date']?.toString() ?? '').replaceFirst(
                          'T',
                          ' ',
                        ),
                        style: const TextStyle(
                          color: NalviumColors.textTertiary,
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

String _text(Map<String, dynamic> item, String key, {String fallback = ''}) {
  final value = item[key]?.toString() ?? '';
  return value.isEmpty || value == 'null' ? fallback : value;
}

String _maintenanceLabel(Map<String, dynamic> item) {
  final performed = _text(item, 'performed_at', fallback: 'date inconnue');
  final next = _text(item, 'next_due_at');
  return 'Effectué le $performed${next.isEmpty ? '' : '  •  Prochain $next'}';
}

class _DetailSectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onAdd;
  const _DetailSectionHeader({required this.title, required this.onAdd});
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(title, style: Theme.of(context).textTheme.titleLarge),
      ),
      TextButton.icon(
        onPressed: onAdd,
        icon: const Icon(Icons.add_rounded, size: 18),
        label: const Text('Ajouter'),
      ),
    ],
  );
}

class _DetailEmpty extends StatelessWidget {
  final String text;
  const _DetailEmpty({required this.text});
  @override
  Widget build(BuildContext context) =>
      Text(text, style: Theme.of(context).textTheme.bodyMedium);
}

class _InfoRow extends StatelessWidget {
  final String title;
  final String value;
  const _InfoRow({required this.title, required this.value});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: NalviumColors.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(color: NalviumColors.textSecondary),
          ),
        ),
      ],
    ),
  );
}

class _DocumentRow extends StatelessWidget {
  final Map<String, dynamic> document;
  final VoidCallback? onDelete;
  const _DocumentRow({required this.document, this.onDelete});
  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: const Icon(
      Icons.description_outlined,
      color: NalviumColors.primaryLight,
    ),
    title: Text(
      _text(document, 'display_name'),
      style: const TextStyle(
        color: NalviumColors.ink,
        fontWeight: FontWeight.w700,
      ),
    ),
    subtitle: Text(
      '${_text(document, 'document_type')}  •  ${_text(document, 'extraction_status', fallback: 'privé')}',
      style: const TextStyle(color: NalviumColors.textSecondary),
    ),
    trailing: IconButton(
      tooltip: 'Supprimer le document',
      onPressed: onDelete,
      icon: const Icon(Icons.delete_outline, color: NalviumColors.textTertiary),
    ),
  );
}

class EquipmentDocumentAddScreen extends StatefulWidget {
  final ApiClient api;
  final String equipmentId;
  const EquipmentDocumentAddScreen({
    super.key,
    required this.api,
    required this.equipmentId,
  });
  @override
  State<EquipmentDocumentAddScreen> createState() =>
      _EquipmentDocumentAddState();
}

class _EquipmentDocumentAddState extends State<EquipmentDocumentAddScreen> {
  bool busy = false;
  Future<void> _upload(XFile? picked) async {
    if (picked == null || !mounted) return;
    setState(() => busy = true);
    try {
      final document = await widget.api.uploadEquipmentDocument(
        equipmentId: widget.equipmentId,
        file: picked,
      );
      final analyzed = await widget.api.analyzeDocument(
        document['id'].toString(),
      );
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DocumentReviewScreen(
            api: widget.api,
            document: analyzed['document'] as Map<String, dynamic>,
            extraction: analyzed['extraction'] as Map<String, dynamic>,
          ),
        ),
      );
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _image(ImageSource source) async => _upload(
    await ImagePicker().pickImage(
      source: source,
      maxWidth: 2048,
      maxHeight: 2048,
      imageQuality: 88,
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Ajouter un document')),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        children: [
          const SectionLabel('Dossier privé'),
          const SizedBox(height: 12),
          Text(
            'Ajoutez une notice, une facture ou une garantie.',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 10),
          Text(
            'Nalvium l’analyse, puis vous choisissez les informations à appliquer à l’équipement.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 30),
          _AddAction(
            icon: Icons.photo_camera_outlined,
            title: 'Prendre une photo',
            subtitle: 'Photographier le document',
            onTap: busy ? null : () => _image(ImageSource.camera),
            primary: true,
          ),
          const SizedBox(height: 12),
          _AddAction(
            icon: Icons.photo_library_outlined,
            title: 'Choisir une image',
            subtitle: 'Depuis votre galerie',
            onTap: busy ? null : () => _image(ImageSource.gallery),
          ),
          const SizedBox(height: 12),
        ],
      ),
    ),
  );
}

class DocumentReviewScreen extends StatefulWidget {
  final ApiClient api;
  final Map<String, dynamic> document;
  final Map<String, dynamic> extraction;
  const DocumentReviewScreen({
    super.key,
    required this.api,
    required this.document,
    required this.extraction,
  });
  @override
  State<DocumentReviewScreen> createState() => _DocumentReviewState();
}

class _DocumentReviewState extends State<DocumentReviewScreen> {
  bool busy = false;
  String _nested(String key) {
    final value = widget.extraction[key];
    return value is Map
        ? value['value']?.toString() ?? ''
        : value?.toString() ?? '';
  }

  Future<void> _apply() async {
    setState(() => busy = true);
    try {
      final result = await widget.api.applyDocument(
        widget.document['id'].toString(),
        {
          'brand': _nested('equipment_brand').isEmpty
              ? null
              : _nested('equipment_brand'),
          'model': _nested('equipment_model').isEmpty
              ? null
              : _nested('equipment_model'),
          'serial_number': _nested('serial_number').isEmpty
              ? null
              : _nested('serial_number'),
          'purchase_date': widget.extraction['purchase_date'],
          'purchase_price': widget.extraction['purchase_price'],
          'purchase_currency': widget.extraction['purchase_currency'],
          'seller': widget.extraction['merchant'],
        },
      );
      if (!mounted) return;
      if (result['contradiction'] == true) {
        await showDialog<void>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Modèle différent'),
            content: Text(
              'Le document indique ${result['document_model']}, tandis que l’équipement contient déjà ${result['existing_model']}.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Conserver l’existant'),
              ),
            ],
          ),
        );
      } else {
        Navigator.pop(context);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Vérifier le document')),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        children: [
          const SectionLabel('J’ai trouvé ces informations'),
          const SizedBox(height: 18),
          Text(
            widget.extraction['document_title']?.toString() ?? 'Document',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),
          _InfoRow(
            title: 'Type',
            value: widget.extraction['document_type']?.toString() ?? 'Autre',
          ),
          if (_nested('equipment_brand').isNotEmpty)
            _InfoRow(title: 'Marque', value: _nested('equipment_brand')),
          if (_nested('equipment_model').isNotEmpty)
            _InfoRow(title: 'Modèle', value: _nested('equipment_model')),
          if (widget.extraction['purchase_date'] != null)
            _InfoRow(
              title: 'Date d’achat',
              value: widget.extraction['purchase_date'].toString(),
            ),
          if (widget.extraction['purchase_price'] != null)
            _InfoRow(
              title: 'Prix',
              value:
                  '${widget.extraction['purchase_price']} ${widget.extraction['purchase_currency'] ?? ''}',
            ),
          const SizedBox(height: 24),
          Text(
            'Rien ne sera appliqué sans votre confirmation.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: busy ? null : _apply,
              child: Text(busy ? 'Application…' : 'Appliquer à l’équipement'),
            ),
          ),
        ],
      ),
    ),
  );
}

class WarrantyFormScreen extends StatefulWidget {
  final ApiClient api;
  final String equipmentId;
  const WarrantyFormScreen({
    super.key,
    required this.api,
    required this.equipmentId,
  });
  @override
  State<WarrantyFormScreen> createState() => _WarrantyFormState();
}

class _WarrantyFormState extends State<WarrantyFormScreen> {
  final provider = TextEditingController();
  final end = TextEditingController();
  bool busy = false;
  @override
  void dispose() {
    provider.dispose();
    end.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => busy = true);
    try {
      await widget.api.createWarranty(widget.equipmentId, {
        'provider': provider.text.trim().isEmpty ? null : provider.text.trim(),
        'end_date': end.text.trim().isEmpty ? null : end.text.trim(),
      });
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => _SimpleFormScaffold(
    title: 'Ajouter une garantie',
    children: [
      TextField(
        controller: provider,
        decoration: const InputDecoration(labelText: 'Fournisseur'),
      ),
      TextField(
        controller: end,
        decoration: const InputDecoration(
          labelText: 'Date de fin',
          hintText: 'AAAA-MM-JJ',
        ),
      ),
      const SizedBox(height: 18),
      FilledButton(
        onPressed: busy ? null : _save,
        child: const Text('Enregistrer'),
      ),
    ],
  );
}

class MaintenanceFormScreen extends StatefulWidget {
  final ApiClient api;
  final String equipmentId;
  const MaintenanceFormScreen({
    super.key,
    required this.api,
    required this.equipmentId,
  });
  @override
  State<MaintenanceFormScreen> createState() => _MaintenanceFormState();
}

class _MaintenanceFormState extends State<MaintenanceFormScreen> {
  final title = TextEditingController();
  final performed = TextEditingController();
  final next = TextEditingController();
  bool busy = false;
  @override
  void dispose() {
    title.dispose();
    performed.dispose();
    next.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (title.text.trim().isEmpty) return;
    setState(() => busy = true);
    try {
      await widget.api.createMaintenance(widget.equipmentId, {
        'title': title.text.trim(),
        'performed_at': performed.text.trim().isEmpty
            ? null
            : performed.text.trim(),
        'next_due_at': next.text.trim().isEmpty ? null : next.text.trim(),
        'maintenance_type': 'other',
        'source': 'user',
      });
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => _SimpleFormScaffold(
    title: 'Ajouter un entretien',
    children: [
      TextField(
        controller: title,
        decoration: const InputDecoration(labelText: 'Entretien'),
      ),
      TextField(
        controller: performed,
        decoration: const InputDecoration(
          labelText: 'Effectué le',
          hintText: 'AAAA-MM-JJ',
        ),
      ),
      TextField(
        controller: next,
        decoration: const InputDecoration(
          labelText: 'Prochain',
          hintText: 'AAAA-MM-JJ',
        ),
      ),
      const SizedBox(height: 18),
      FilledButton(
        onPressed: busy ? null : _save,
        child: const Text('Enregistrer'),
      ),
    ],
  );
}

class _SimpleFormScaffold extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SimpleFormScaffold({required this.title, required this.children});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: children
            .map(
              (child) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: child,
              ),
            )
            .toList(),
      ),
    ),
  );
}

class EquipmentDiagnosticStart extends StatefulWidget {
  final ApiClient api;
  final HistoryStore history;
  final String sessionId;
  final String equipmentId;
  const EquipmentDiagnosticStart({
    super.key,
    required this.api,
    required this.history,
    required this.sessionId,
    required this.equipmentId,
  });
  @override
  State<EquipmentDiagnosticStart> createState() =>
      _EquipmentDiagnosticStartState();
}

class _EquipmentDiagnosticStartState extends State<EquipmentDiagnosticStart> {
  final picker = ImagePicker();
  bool busy = false;
  Future<void> _pick(ImageSource source) async {
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 2048,
      maxHeight: 2048,
      imageQuality: 86,
    );
    if (picked == null || !mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PreviewScreen(
          file: File(picked.path),
          pickedFile: picked,
          source: source,
          sessionId: widget.sessionId,
          api: widget.api,
          history: widget.history,
          equipmentId: widget.equipmentId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Signaler un problème')),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Montrez-moi ce qui se passe.',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 10),
            Text(
              'Le contexte de cet équipement sera conservé avec le diagnostic.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _pick(ImageSource.camera),
                icon: const Icon(Icons.photo_camera_outlined),
                label: const Text('Prendre une photo'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _pick(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Choisir une photo'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
