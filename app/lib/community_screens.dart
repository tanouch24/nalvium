// The compact screen builders intentionally keep simple one-line guards.
// ignore_for_file: curly_braces_in_flow_control_structures, prefer_conditional_assignment

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'api_client.dart';
import 'community_identity.dart';
import 'theme/nalvium_theme.dart';
import 'widgets/nalvium_widgets.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});
  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final api = const ApiClient();
  final query = TextEditingController();
  String actor = '';
  String category = 'all';
  bool savedOnly = false;
  Future<List<Map<String, dynamic>>> posts = Future.value(
    const <Map<String, dynamic>>[],
  );

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    actor = await CommunityIdentity.id();
    if (mounted) setState(() => posts = _fetch());
  }

  Future<List<Map<String, dynamic>>> _fetch() => api.communityPosts(
    actorKey: actor,
    query: query.text.trim(),
    category: category,
    saved: savedOnly,
  );
  void _refresh() {
    if (actor.isNotEmpty) setState(() => posts = _fetch());
  }

  Future<void> _create() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CommunityCreatePostScreen(api: api, actorKey: actor),
      ),
    );
    _refresh();
  }

  @override
  void dispose() {
    query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 22, 16, 0),
          child: Row(
            children: [
              const Expanded(child: NalviumLogo()),
              IconButton(
                tooltip: 'Partager une réparation',
                onPressed: actor.isEmpty ? null : _create,
                icon: const Icon(Icons.add_a_photo_outlined),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Communauté',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 8),
          child: TextField(
            controller: query,
            onSubmitted: (_) => _refresh(),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'Rechercher une réparation',
              suffixIcon: IconButton(
                onPressed: _refresh,
                icon: const Icon(Icons.arrow_forward_rounded),
              ),
            ),
          ),
        ),
        SizedBox(
          height: 46,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            scrollDirection: Axis.horizontal,
            itemCount: 5,
            separatorBuilder: (_, index) => const SizedBox(width: 8),
            itemBuilder: (_, index) {
              const values = [
                ('all', 'Tous'),
                ('plumbing', 'Plomberie'),
                ('appliance', 'Électroménager'),
                ('diy', 'Bricolage'),
              ];
              if (index == 4) {
                return ChoiceChip(
                  label: const Text('Enregistrés'),
                  selected: savedOnly,
                  onSelected: (_) {
                    setState(() => savedOnly = !savedOnly);
                    _refresh();
                  },
                );
              }
              final item = values[index];
              return ChoiceChip(
                label: Text(item.$2),
                selected: category == item.$1,
                onSelected: (_) {
                  setState(() => category = item.$1);
                  _refresh();
                },
              );
            },
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: posts,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done)
                return const Center(child: CircularProgressIndicator());
              if (snapshot.hasError) return _CommunityError(onRetry: _refresh);
              final items = snapshot.data ?? const <Map<String, dynamic>>[];
              if (items.isEmpty)
                return EmptyState(
                  icon: Icons.compare_outlined,
                  title: 'Aucune réparation partagée',
                  body: 'Les réparations partagées par la communauté apparaîtront ici. Une réparation réussie avec NALVIUM pourra être partagée volontairement.',
                );
              return RefreshIndicator(
                onRefresh: () async => _refresh(),
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                  itemCount: items.length,
                  itemBuilder: (_, index) => CommunityPostCard(
                    post: items[index],
                    api: api,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CommunityPostDetailScreen(
                            postId: items[index]['id'].toString(),
                            api: api,
                            actorKey: actor,
                          ),
                        ),
                      );
                      _refresh();
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    ),
  );
}

class _CommunityError extends StatelessWidget {
  final VoidCallback onRetry;
  const _CommunityError({required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.cloud_off_outlined,
          color: NalviumColors.warning,
          size: 42,
        ),
        const SizedBox(height: 12),
        const Text('La communauté est indisponible.'),
        TextButton(onPressed: onRetry, child: const Text('Réessayer')),
      ],
    ),
  );
}

String? _communityMediaId(Iterable<Map> media, String kind) {
  for (final item in media) {
    if (item['media_kind'] == kind && item['public_media_id'] != null)
      return item['public_media_id'].toString();
  }
  return null;
}

class CommunityPostCard extends StatelessWidget {
  final Map<String, dynamic> post;
  final ApiClient api;
  final VoidCallback onTap;
  const CommunityPostCard({
    super.key,
    required this.post,
    required this.api,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final media = (post['media'] as List? ?? []).whereType<Map>().toList();
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: SurfaceCard(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _CommunityImage(
                      id: _communityMediaId(media, 'before'),
                      api: api,
                      label: 'AVANT',
                    ),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    child: _CommunityImage(
                      id: _communityMediaId(media, 'after'),
                      api: api,
                      label: 'APRÈS',
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                child: Text(
                  post['title']?.toString() ?? 'Réparation',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  [post['equipment_type'], post['category'], 'Résolu']
                      .where((v) => v != null && v.toString().isNotEmpty)
                      .join('  •  '),
                  style: const TextStyle(
                    color: NalviumColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                child: Row(
                  children: [
                    Text(
                      'Utile ${post['helpful_count'] ?? 0}',
                      style: const TextStyle(
                        color: NalviumColors.textTertiary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 18),
                    Text(
                      '${(post['comments'] as List? ?? []).length} commentaire(s)',
                      style: const TextStyle(
                        color: NalviumColors.textTertiary,
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: NalviumColors.textTertiary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CommunityImage extends StatelessWidget {
  final String? id;
  final ApiClient api;
  final String label;
  const _CommunityImage({
    required this.id,
    required this.api,
    required this.label,
  });
  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 1.15,
    child: Stack(
      fit: StackFit.expand,
      children: [
        if (id != null && id!.isNotEmpty)
          Image.network(
            '${api.baseUrl}/v1/community/media/$id',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stack) => const ColoredBox(
              color: NalviumColors.surfaceAlternative,
              child: Icon(Icons.image_not_supported_outlined),
            ),
          )
        else
          const ColoredBox(
            color: NalviumColors.surfaceAlternative,
            child: Icon(
              Icons.image_outlined,
              color: NalviumColors.textTertiary,
            ),
          ),
        Positioned(
          left: 10,
          top: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
            color: NalviumColors.background.withValues(alpha: .82),
            child: Text(
              label,
              style: const TextStyle(
                color: NalviumColors.ink,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class CommunityPostDetailScreen extends StatefulWidget {
  final String postId;
  final ApiClient api;
  final String actorKey;
  const CommunityPostDetailScreen({
    super.key,
    required this.postId,
    required this.api,
    required this.actorKey,
  });
  @override
  State<CommunityPostDetailScreen> createState() => _CommunityPostDetailState();
}

class _CommunityPostDetailState extends State<CommunityPostDetailScreen> {
  late Future<Map<String, dynamic>> post;
  final comment = TextEditingController();
  bool busy = false;
  String? replyParentId;
  @override
  void initState() {
    super.initState();
    post = widget.api.getCommunityPost(widget.postId, widget.actorKey);
  }

  @override
  void dispose() {
    comment.dispose();
    super.dispose();
  }

  Future<void> _comment() async {
    if (comment.text.trim().isEmpty) return;
    setState(() => busy = true);
    try {
      await widget.api.addCommunityComment(
        widget.postId,
        widget.actorKey,
        comment.text.trim(),
        parentCommentId: replyParentId,
      );
      comment.clear();
      replyParentId = null;
      setState(
        () =>
            post = widget.api.getCommunityPost(widget.postId, widget.actorKey),
      );
    } catch (error) {
      if (mounted) _showCommunityError(context, error);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Réparation partagée')),
    body: FutureBuilder<Map<String, dynamic>>(
      future: post,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done)
          return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError)
          return _CommunityError(
            onRetry: () => setState(
              () => post = widget.api.getCommunityPost(
                widget.postId,
                widget.actorKey,
              ),
            ),
          );
        final item = snapshot.data!;
        final media = (item['media'] as List? ?? []).whereType<Map>().toList();
        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 28),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item['title']?.toString() ?? 'Réparation',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                IconButton(
                  onPressed: () => widget.api
                      .communityAction(
                        widget.postId,
                        widget.actorKey,
                        'helpful',
                        enabled: item['helpful'] != true,
                      )
                      .then(
                        (_) => setState(
                          () => post = widget.api.getCommunityPost(
                            widget.postId,
                            widget.actorKey,
                          ),
                        ),
                      ),
                  icon: Icon(
                    Icons.check_circle_outline,
                    color: item['helpful'] == true
                        ? NalviumColors.primary
                        : NalviumColors.textTertiary,
                  ),
                ),
                IconButton(
                  onPressed: () => widget.api
                      .communityAction(
                        widget.postId,
                        widget.actorKey,
                        'save',
                        enabled: item['saved'] != true,
                      )
                      .then(
                        (_) => setState(
                          () => post = widget.api.getCommunityPost(
                            widget.postId,
                            widget.actorKey,
                          ),
                        ),
                      ),
                  icon: Icon(
                    Icons.bookmark_border,
                    color: item['saved'] == true
                        ? NalviumColors.primary
                        : NalviumColors.textTertiary,
                  ),
                ),
              ],
            ),
            Text(
              'Expérience partagée par ${item['author_handle'] ?? 'un utilisateur'} — ce n’est pas une instruction NALVIUM.',
              style: const TextStyle(
                color: NalviumColors.textSecondary,
                fontSize: 13,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                for (final kind in ['before', 'after'])
                  Expanded(
                    child: _CommunityImage(
                      id: _communityMediaId(media, kind),
                      api: widget.api,
                      label: kind == 'before' ? 'AVANT' : 'APRÈS',
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 22),
            const SectionLabel('Problème rencontré'),
            const SizedBox(height: 6),
            Text(item['problem_summary']?.toString() ?? ''),
            const SizedBox(height: 18),
            const SectionLabel('Ce qui a été fait'),
            const SizedBox(height: 6),
            Text(item['solution_summary']?.toString() ?? ''),
            if ((item['materials_used']?.toString() ?? '').isNotEmpty) ...[
              const SizedBox(height: 18),
              const SectionLabel('Matériel utilisé'),
              const SizedBox(height: 6),
              Text(item['materials_used'].toString()),
            ],
            const SizedBox(height: 26),
            const SectionLabel('Commentaires'),
            const SizedBox(height: 8),
            ...((item['comments'] as List? ?? []).whereType<Map>().map(
              (c) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(c['content']?.toString() ?? ''),
                subtitle: Text(
                  c['author_handle']?.toString() ?? 'Membre Nalvium',
                ),
                trailing: TextButton(
                  onPressed: () {
                    setState(() {
                      replyParentId = c['id']?.toString();
                    });
                  },
                  child: const Text('Répondre'),
                ),
              ),
            )),
            const SizedBox(height: 8),
            TextField(
              controller: comment,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: replyParentId == null
                    ? 'Partager votre expérience'
                    : 'Répondre à ce commentaire',
                suffixIcon: IconButton(
                  onPressed: busy ? null : _comment,
                  icon: const Icon(Icons.send_outlined),
                ),
              ),
            ),
            TextButton.icon(
              onPressed: () async {
                await widget.api.reportCommunity(
                  widget.actorKey,
                  'post',
                  widget.postId,
                  'Contenu inapproprié',
                );
                if (context.mounted)
                  _showCommunityError(
                    context,
                    'Merci, le signalement a été enregistré.',
                  );
              },
              icon: const Icon(Icons.flag_outlined),
              label: const Text('Signaler'),
            ),
          ],
        );
      },
    ),
  );
}

class CommunityCreatePostScreen extends StatefulWidget {
  final ApiClient api;
  final String actorKey;
  final String? repairId;
  final String? beforeMediaId;
  final String? afterMediaId;
  final File? beforeFile;
  final File? afterFile;
  const CommunityCreatePostScreen({
    super.key,
    required this.api,
    required this.actorKey,
    this.repairId,
    this.beforeMediaId,
    this.afterMediaId,
    this.beforeFile,
    this.afterFile,
  });
  @override
  State<CommunityCreatePostScreen> createState() => _CommunityCreatePostState();
}

class _CommunityCreatePostState extends State<CommunityCreatePostScreen> {
  final picker = ImagePicker();
  late final title = TextEditingController(text: 'Ma réparation');
  late final problem = TextEditingController();
  late final solution = TextEditingController();
  late final materials = TextEditingController();
  XFile? before;
  XFile? after;
  bool busy = false;
  bool consent = false;
  Future<void> _pick(bool isBefore) async {
    final file = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 2048,
      maxHeight: 2048,
      imageQuality: 84,
    );
    if (file == null) return;
    setState(() {
      if (isBefore)
        before = file;
      else
        after = file;
    });
  }

  Future<void> _publish() async {
    if (!consent) {
      _showCommunityError(
        context,
        'Confirmez les éléments qui seront publiés.',
      );
      return;
    }
    if ((widget.beforeMediaId == null && before == null) ||
        (widget.afterMediaId == null && after == null) ||
        title.text.trim().isEmpty ||
        problem.text.trim().isEmpty ||
        solution.text.trim().isEmpty) {
      _showCommunityError(
        context,
        'Ajoutez une photo avant, une photo après et les trois textes principaux.',
      );
      return;
    }
    setState(() => busy = true);
    try {
      String? beforeId = widget.beforeMediaId, afterId = widget.afterMediaId;
      final session = await widget.api.createSession(actorKey: widget.actorKey);
      if (beforeId == null)
        beforeId = await widget.api.upload(before!, session);
      if (afterId == null) afterId = await widget.api.upload(after!, session);
      final draft = await widget.api.createCommunityPost({
        'repair_record_id': widget.repairId,
        'title': title.text.trim(),
        'category': 'other',
        'problem_summary': problem.text.trim(),
        'solution_summary': solution.text.trim(),
        'materials_used': materials.text.trim().isEmpty
            ? null
            : materials.text.trim(),
        'before_media_id': beforeId,
        'after_media_id': afterId,
      }, widget.actorKey);
      await widget.api.publishCommunityPost(
        draft['id'].toString(),
        widget.actorKey,
        beforeMediaId: beforeId,
        afterMediaId: afterId,
      );
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) _showCommunityError(context, error);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    for (final item in [title, problem, solution, materials]) {
      item.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Partager ma réparation')),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 14, 24, 30),
        children: [
          Text(
            'Vérifiez ce qui sera public.',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          const Text(
            'Aucun nom, contact, adresse, numéro de série ou document privé ne sera ajouté.',
            style: TextStyle(color: NalviumColors.textSecondary),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _PickCommunityMedia(
                  label: 'AVANT',
                  file:
                      before ??
                      (widget.beforeFile == null
                          ? null
                          : XFile(widget.beforeFile!.path)),
                  onTap: () => _pick(true),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PickCommunityMedia(
                  label: 'APRÈS',
                  file:
                      after ??
                      (widget.afterFile == null
                          ? null
                          : XFile(widget.afterFile!.path)),
                  onTap: () => _pick(false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          _CommunityField(label: 'Titre', controller: title),
          _CommunityField(
            label: 'Problème rencontré',
            controller: problem,
            maxLines: 3,
          ),
          _CommunityField(
            label: 'Ce qui a été fait',
            controller: solution,
            maxLines: 4,
          ),
          _CommunityField(
            label: 'Matériel utilisé (facultatif)',
            controller: materials,
            maxLines: 2,
          ),
          const SizedBox(height: 10),
          const SurfaceCard(
            color: NalviumColors.surfaceAlternative,
            child: Text(
              'Expérience partagée par un utilisateur. Ce contenu ne constitue pas une instruction validée par NALVIUM.',
              style: TextStyle(color: NalviumColors.ink, height: 1.35),
            ),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: consent,
            onChanged: busy
                ? null
                : (value) => setState(() => consent = value ?? false),
            title: const Text(
              'Je confirme que ces photos et textes peuvent être publiés dans la Communauté.',
            ),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: busy ? null : _publish,
            icon: const Icon(Icons.public_outlined),
            label: Text(busy ? 'Publication…' : 'Publier cette réparation'),
          ),
        ],
      ),
    ),
  );
}

class _PickCommunityMedia extends StatelessWidget {
  final String label;
  final XFile? file;
  final VoidCallback onTap;
  const _PickCommunityMedia({
    required this.label,
    required this.file,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(18),
    child: AspectRatio(
      aspectRatio: .9,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: file == null
            ? Container(
                color: NalviumColors.surfaceAlternative,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.add_a_photo_outlined,
                      color: NalviumColors.primaryLight,
                    ),
                    const SizedBox(height: 8),
                    Text(label),
                  ],
                ),
              )
            : Image.file(File(file!.path), fit: BoxFit.cover),
      ),
    ),
  );
}

class _CommunityField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final int maxLines;
  const _CommunityField({
    required this.label,
    required this.controller,
    this.maxLines = 1,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(labelText: label),
    ),
  );
}

void _showCommunityError(BuildContext context, Object error) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(error is ApiException ? error.message : error.toString()),
    ),
  );
}
