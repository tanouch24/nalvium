import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'api_client.dart';
import 'ads_service.dart';
import 'assistant_store.dart';
import 'community_screens.dart';
import 'community_identity.dart';
import 'equipment_screens.dart';
import 'equipment_photo_store.dart';
import 'history_store.dart';
import 'legal_screens.dart';
import 'release_config.dart';
import 'theme/nalvium_theme.dart';
import 'widgets/nalvium_widgets.dart';

void main() {
  ReleaseConfig.validate();
  // Disabled by default. No ad SDK request is made in the first release.
  unawaited(AdsService.instance.initialize());
  runApp(const NalviumApp());
}

class NalviumApp extends StatelessWidget {
  const NalviumApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'NALVIUM',
    debugShowCheckedModeBanner: false,
    theme: nalviumTheme(),
    home: const OnboardingScreen(),
  );
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingState();
}

class _OnboardingState extends State<OnboardingScreen> {
  final controller = PageController();
  int page = 0;
  final items = const [
    (
      'Montrez-moi le problème',
      'Une photo suffit pour commencer à comprendre ce qui se passe.',
      Icons.photo_camera_outlined,
    ),
    (
      'Avançons ensemble',
      'Une seule action claire à la fois, puis une vérification.',
      Icons.route_outlined,
    ),
    (
      'La sécurité d’abord',
      'Si la situation présente un risque, nous vous le dirons clairement.',
      Icons.shield_outlined,
    ),
  ];
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: Column(
          children: [
            Row(
              children: [
                const NalviumLogo(compact: true),
                const Spacer(),
                Text('${page + 1} / 3'),
              ],
            ),
            Expanded(
              child: PageView.builder(
                controller: controller,
                itemCount: items.length,
                onPageChanged: (value) => setState(() => page = value),
                itemBuilder: (_, index) => Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 190,
                      height: 190,
                      decoration: BoxDecoration(
                        color: NalviumColors.surfaceAlternative,
                        borderRadius: BorderRadius.circular(26),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 128,
                            height: 128,
                            decoration: BoxDecoration(
                              color: NalviumColors.primary,
                              borderRadius: BorderRadius.circular(40),
                            ),
                          ),
                          Icon(items[index].$3, size: 66, color: Colors.white),
                        ],
                      ),
                    ),
                    const SizedBox(height: 48),
                    Text(
                      items[index].$1,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      items[index].$2,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                3,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  margin: const EdgeInsets.all(4),
                  width: index == page ? 28 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: index == page
                        ? NalviumColors.primary
                        : NalviumColors.border,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  if (page < 2) {
                    controller.nextPage(
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOutCubic,
                    );
                  } else {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const MainShell()),
                    );
                  }
                },
                child: Text(page < 2 ? 'Continuer' : 'Commencer gratuitement'),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Nalvium ne remplace pas un professionnel qualifié.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: NalviumColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int index = 0;
  final history = HistoryStore();

  @override
  Widget build(BuildContext context) {
    final pages = [
      const HomeScreen(),
      HouseScreen(history: history),
      const AssistantScreen(),
      const CommunityScreen(),
      ActivityScreen(history: history),
    ];
    return Scaffold(
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: Icon(Icons.home_work_outlined),
            selectedIcon: Icon(Icons.home_work_rounded),
            label: 'Ma maison',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome),
            label: 'Nalvium',
          ),
          NavigationDestination(
            icon: Icon(Icons.forum_outlined),
            selectedIcon: Icon(Icons.forum_rounded),
            label: 'Communauté',
          ),
          NavigationDestination(
            icon: Icon(Icons.timeline_outlined),
            selectedIcon: Icon(Icons.timeline_rounded),
            label: 'Activité',
          ),
        ],
      ),
    );
  }
}

class AssistantScreen extends StatefulWidget {
  final String? contextType;
  final String? contextId;
  final String? equipmentId;
  const AssistantScreen({
    super.key,
    this.contextType,
    this.contextId,
    this.equipmentId,
  });
  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final api = const ApiClient();
  final store = AssistantStore();
  final picker = ImagePicker();
  final composer = TextEditingController();
  final composerFocus = FocusNode();
  final scroll = ScrollController();
  final recorder = AudioRecorder();
  List<Map<String, dynamic>> messages = [];
  final Map<String, File> localPhotos = {};
  String? threadId;
  bool loading = true;
  bool sending = false;
  bool recording = false;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  @override
  void dispose() {
    composer.dispose();
    composerFocus.dispose();
    scroll.dispose();
    recorder.dispose();
    super.dispose();
  }

  Future<void> _restore() async {
    try {
      final saved = widget.equipmentId == null ? await store.threadId() : null;
      if (saved != null) {
        final thread = await api.getAssistantThread(saved);
        messages = (thread['messages'] as List? ?? [])
            .whereType<Map>()
            .map((m) => Map<String, dynamic>.from(m))
            .toList();
        threadId = saved;
      }
    } catch (_) {
      /* A stale local thread should not block a new conversation. */
    }
    if (mounted) setState(() => loading = false);
  }

  Future<String> _ensureThread() async {
    if (threadId != null) return threadId!;
    final created = await api.createAssistantThread(
      contextType: widget.contextType,
      contextId: widget.contextId,
      equipmentId: widget.equipmentId,
    );
    threadId = created['id'].toString();
    await store.saveThreadId(threadId!);
    return threadId!;
  }

  Future<void> _send({String? preset, XFile? photo}) async {
    final text = (preset ?? composer.text).trim();
    if (text.isEmpty && photo == null || sending) return;
    FocusManager.instance.primaryFocus?.unfocus();
    composer.clear();
    setState(() => sending = true);
    try {
      final id = await _ensureThread();
      String? mediaId;
      if (photo != null) {
        final session = await api.createSession();
        mediaId = await api.upload(photo, session);
        localPhotos[mediaId] = File(photo.path);
      }
      final response = await api.sendAssistantMessage(
        threadId: id,
        text: text,
        mediaId: mediaId,
      );
      final thread = await api.getAssistantThread(id);
      if (mounted) {
        setState(
          () => messages = (thread['messages'] as List? ?? [])
              .whereType<Map>()
              .map((m) => Map<String, dynamic>.from(m))
              .toList(),
        );
      }
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (scroll.hasClients) {
            scroll.animateTo(
              scroll.position.maxScrollExtent,
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOut,
            );
          }
        });
      }
      if (response['safety_stop'] == true && mounted) {
        _showError(
          context,
          'Nalvium vous recommande de vous mettre en sécurité.',
        );
      }
    } catch (error) {
      if (mounted) _showError(context, error.toString());
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  Future<void> _addPhoto() async {
    final source = await showModalBottomSheet<Object>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Prendre une photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choisir une photo'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.videocam_outlined),
              title: const Text('Filmer le problème (20 s max)'),
              onTap: () => Navigator.pop(context, 'video'),
            ),
          ],
        ),
      ),
    );
    if (source == 'video') {
      await _addVideo();
      return;
    }
    if (source is! ImageSource) return;
    final photo = await picker.pickImage(
      source: source,
      maxWidth: 2048,
      maxHeight: 2048,
      imageQuality: 84,
    );
    if (photo != null) await _send(photo: photo);
  }

  Future<void> _addVideo() async {
    final video = await picker.pickVideo(
      source: ImageSource.camera,
      maxDuration: const Duration(seconds: 20),
    );
    if (video == null) return;
    setState(() => sending = true);
    try {
      final id = await _ensureThread();
      await api.sendAssistantMessage(
        threadId: id,
        text: 'Je vais vous montrer une courte vidéo du problème.',
      );
      final session = await api.createSession(
        equipmentId: widget.equipmentId,
        assistantThreadId: id,
      );
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VideoPreviewScreen(
            pickedFile: video,
            api: api,
            history: HistoryStore(),
            sessionId: session,
            equipmentId: widget.equipmentId,
          ),
        ),
      );
    } catch (error) {
      if (mounted) _showError(context, error.toString());
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  Future<void> _voice() async {
    try {
      if (recording) {
        final path = await recorder.stop();
        setState(() => recording = false);
        if (path == null) return;
        final text = await api.transcribeAudio(File(path));
        if (text.isNotEmpty && mounted) {
          composer.text = text;
          composer.selection = TextSelection.collapsed(offset: text.length);
          composerFocus.requestFocus();
        }
        return;
      }
      if (!await recorder.hasPermission()) {
        if (mounted) {
          _showError(
            context,
            'L’accès au microphone est nécessaire pour transcrire votre message.',
          );
        }
        return;
      }
      final path =
          '${Directory.systemTemp.path}/nalvium-voice-${DateTime.now().millisecondsSinceEpoch}.m4a';
      await recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: path,
      );
      setState(() => recording = true);
    } catch (_) {
      if (mounted) {
        _showError(context, 'L’enregistrement vocal n’a pas pu démarrer.');
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const NalviumLogo(compact: true),
      actions: [
        IconButton(
          tooltip: 'Nouvelle conversation',
          onPressed: () => setState(() {
            threadId = null;
            messages = [];
          }),
          icon: const Icon(Icons.add_comment_outlined),
        ),
      ],
    ),
    body: SafeArea(
      child: Column(
        children: [
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : messages.isEmpty
                ? _empty()
                : ListView.builder(
                    controller: scroll,
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                    itemCount: messages.length,
                    itemBuilder: (_, index) => _message(messages[index]),
                  ),
          ),
          _composer(),
        ],
      ),
    ),
  );

  Widget _empty() => ListView(
    padding: const EdgeInsets.fromLTRB(24, 44, 24, 20),
    children: [
      const SizedBox(height: 34),
      const Icon(Icons.auto_awesome, color: NalviumColors.primary, size: 38),
      const SizedBox(height: 22),
      Text(
        'Comment puis-je vous aider ?',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.headlineMedium,
      ),
      const SizedBox(height: 32),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _quick(Icons.photo_camera_outlined, 'Montrer un problème', _addPhoto),
          _quick(
            Icons.edit_outlined,
            'Expliquer',
            () => composerFocus.requestFocus(),
          ),
          _quick(Icons.photo_library_outlined, 'Ajouter une photo', _addPhoto),
        ],
      ),
      const SizedBox(height: 40),
      _example('Mon lave-linge fait un bruit étrange'),
      _example('Pourquoi mon robinet fuit ?'),
      _example('Comment entretenir mon chauffe-eau ?'),
    ],
  );

  Widget _quick(IconData icon, String label, VoidCallback onTap) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(18),
    child: SizedBox(
      width: 94,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: NalviumColors.surfaceAlternative,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: NalviumColors.primary),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: NalviumColors.ink,
            ),
          ),
        ],
      ),
    ),
  );
  Widget _example(String text) => InkWell(
    onTap: () => _send(preset: text),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Text(
        '“$text”',
        style: const TextStyle(
          color: NalviumColors.textSecondary,
          fontStyle: FontStyle.italic,
        ),
      ),
    ),
  );
  Widget _message(Map<String, dynamic> item) {
    final user = item['role'] == 'user';
    final media = (item['media_references'] as List? ?? [])
        .whereType<String>()
        .map((id) => localPhotos[id])
        .whereType<File>()
        .toList();
    return Align(
      alignment: user ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: EdgeInsets.only(
          left: user ? 18 : 0,
          right: user ? 18 : 26,
          top: 12,
          bottom: 12,
        ),
        decoration: user
            ? BoxDecoration(
                color: NalviumColors.surfaceAlternative,
                borderRadius: BorderRadius.circular(18),
              )
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!user)
              const Padding(
                padding: EdgeInsets.only(bottom: 5),
                child: Text(
                  'NALVIUM',
                  style: TextStyle(
                    color: NalviumColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
            if (media.isNotEmpty)
              ...media.map(
                (file) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.file(
                      file,
                      width: 220,
                      height: 150,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            Text(
              item['content']?.toString() ?? '',
              style: TextStyle(
                color: NalviumColors.ink,
                fontSize: 16,
                height: 1.4,
                fontWeight: user ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _composer() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        IconButton(
          tooltip: 'Ajouter une photo',
          onPressed: sending ? null : _addPhoto,
          icon: const Icon(Icons.add_circle_outline),
        ),
        Expanded(
          child: TextField(
            controller: composer,
            focusNode: composerFocus,
            minLines: 1,
            maxLines: 4,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _send(),
            decoration: const InputDecoration(
              hintText: 'Écrivez à Nalvium…',
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 13,
              ),
            ),
          ),
        ),
        IconButton(
          tooltip: recording ? 'Arrêter l’enregistrement' : 'Parler à Nalvium',
          onPressed: sending ? null : _voice,
          icon: Icon(
            recording ? Icons.stop_circle_outlined : Icons.mic_none_outlined,
            color: recording ? Colors.redAccent : null,
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          tooltip: 'Envoyer',
          onPressed: sending ? null : _send,
          icon: sending
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(
                  Icons.arrow_upward_rounded,
                  color: NalviumColors.primary,
                ),
        ),
      ],
    ),
  );
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeState();
}

class _HomeState extends State<HomeScreen> {
  final api = const ApiClient();
  final picker = ImagePicker();
  final history = HistoryStore();
  bool busy = false;

  Future<void> _capture(ImageSource source) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      final photo = await picker.pickImage(
        source: source,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 84,
      );
      if (photo == null || !mounted) return;
      await photo.length();
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PreviewScreen(
            file: File(photo.path),
            pickedFile: photo,
            source: source,
            sessionId: null,
            api: api,
            history: history,
          ),
        ),
      );
    } catch (error, stackTrace) {
      _logPhotoError(source, error, stackTrace);
      if (mounted) _showError(context, _photoErrorMessage(source, error));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _captureVideo() async {
    if (busy) return;
    setState(() => busy = true);
    try {
      final video = await picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(seconds: 20),
      );
      if (video == null || !mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              VideoPreviewScreen(pickedFile: video, api: api, history: history),
        ),
      );
    } catch (error) {
      if (mounted) _showError(context, 'La vidéo n’a pas pu être préparée.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  const NalviumLogo(),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Historique',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HistoryScreen(history: history),
                      ),
                    ),
                    icon: const Icon(Icons.history_rounded),
                  ),
                  IconButton(
                    tooltip: 'Réglages et confidentialité',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NalviumSettingsScreen(),
                      ),
                    ),
                    icon: const Icon(Icons.settings_outlined),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'NALVIUM',
                    style: TextStyle(
                      color: NalviumColors.primaryLight,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.2,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Qu’est-ce qui se passe\nchez vous ?',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Montrez-moi, je vous guide.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverToBoxAdapter(
              child: _CameraHero(
                busy: busy,
                onCamera: () => _capture(ImageSource.camera),
                onGallery: () => _capture(ImageSource.gallery),
                onVideo: _captureVideo,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
            sliver: SliverToBoxAdapter(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: api.activeSessions(),
                builder: (context, snapshot) {
                  final sessions =
                      snapshot.data ?? const <Map<String, dynamic>>[];
                  if (sessions.isEmpty) return const SizedBox.shrink();
                  final session = sessions.first;
                  return _ResumeDiagnosticCard(
                    session: session,
                    api: api,
                    history: history,
                  );
                },
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AssistantScreen(),
                      ),
                    ),
                    borderRadius: BorderRadius.circular(NalviumRadii.md),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: NalviumColors.surfaceAlternative,
                        borderRadius: BorderRadius.circular(NalviumRadii.md),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.auto_awesome_outlined,
                            color: NalviumColors.primaryLight,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Demander à Nalvium…',
                              style: TextStyle(
                                color: NalviumColors.textSecondary,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: NalviumColors.textTertiary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 26, 24, 0),
            sliver: SliverToBoxAdapter(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: history.list(),
                builder: (context, snapshot) {
                  final items = snapshot.data ?? const <Map<String, dynamic>>[];
                  if (items.isEmpty) return const SizedBox.shrink();
                  return _RecentProblems(items: items.take(5).toList());
                },
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
            sliver: SliverToBoxAdapter(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: api.listEquipment(),
                builder: (context, snapshot) {
                  final upcoming = <Map<String, dynamic>>[];
                  for (final equipment in snapshot.data ?? const []) {
                    for (final item
                        in (equipment['maintenance'] as List? ?? const [])) {
                      if (item is Map && item['next_due_at'] != null) {
                        upcoming.add({
                          ...Map<String, dynamic>.from(item),
                          'equipment_name': equipment['display_name'],
                        });
                      }
                    }
                  }
                  if (upcoming.isEmpty) return const SizedBox.shrink();
                  return _UpcomingMaintenance(items: upcoming.take(3).toList());
                },
              ),
            ),
          ),
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(24, 32, 24, 24),
            sliver: SliverToBoxAdapter(child: SafetyBanner()),
          ),
        ],
      ),
    ),
  );
}

class _ResumeDiagnosticCard extends StatelessWidget {
  final Map<String, dynamic> session;
  final ApiClient api;
  final HistoryStore history;
  const _ResumeDiagnosticCard({
    required this.session,
    required this.api,
    required this.history,
  });
  @override
  Widget build(BuildContext context) => SurfaceCard(
    color: NalviumColors.surfaceAlternative,
    child: Row(
      children: [
        const Icon(
          Icons.play_circle_outline,
          color: NalviumColors.primaryLight,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionLabel('À reprendre'),
              const SizedBox(height: 5),
              Text(
                session['category']?.toString() ?? 'Diagnostic en cours',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: () {
            final media = (session['media'] as List? ?? [])
                .whereType<Map>()
                .toList();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AnalysisScreen(
                  sessionId: session['id'].toString(),
                  mediaId: media.isEmpty ? null : media.last['id']?.toString(),
                  api: api,
                  history: history,
                  equipmentId: session['equipment_id']?.toString(),
                ),
              ),
            );
          },
          child: const Text('Continuer'),
        ),
      ],
    ),
  );
}

class _UpcomingMaintenance extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  const _UpcomingMaintenance({required this.items});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SectionLabel('À prévoir'),
      const SizedBox(height: 10),
      ...items.map(
        (item) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              const Icon(
                Icons.event_outlined,
                color: NalviumColors.primaryLight,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['title']?.toString() ?? 'Entretien',
                      style: const TextStyle(
                        color: NalviumColors.ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      item['equipment_name']?.toString() ?? 'Équipement',
                      style: const TextStyle(
                        color: NalviumColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                item['next_due_at']?.toString() ?? '',
                style: const TextStyle(
                  color: NalviumColors.textTertiary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

class _CameraHero extends StatelessWidget {
  final bool busy;
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final VoidCallback onVideo;
  const _CameraHero({
    required this.busy,
    required this.onCamera,
    required this.onGallery,
    required this.onVideo,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: NalviumColors.surface,
      borderRadius: BorderRadius.circular(26),
      border: Border.all(color: NalviumColors.border),
      boxShadow: const [
        BoxShadow(
          color: Color(0x33000000),
          blurRadius: 24,
          offset: Offset(0, 10),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 196,
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: NalviumColors.surfaceAlternative,
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
              const Positioned.fill(
                child: CustomPaint(painter: _FocusCornersPainter()),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: NalviumColors.primary.withValues(alpha: .16),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.photo_camera_outlined,
                        color: NalviumColors.primaryLight,
                        size: 29,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Montrez la zone du problème',
                      style: TextStyle(
                        color: NalviumColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: busy ? null : onCamera,
            style: FilledButton.styleFrom(
              backgroundColor: NalviumColors.primary,
              foregroundColor: Colors.white,
            ),
            icon: busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.photo_camera_outlined),
            label: Text(busy ? 'Préparation…' : 'Prendre une photo'),
          ),
        ),
        const SizedBox(height: 4),
        Center(
          child: TextButton.icon(
            onPressed: busy ? null : onGallery,
            style: TextButton.styleFrom(
              foregroundColor: NalviumColors.primaryDark,
            ),
            icon: const Icon(Icons.photo_library_outlined, size: 18),
            label: const Text('Choisir une photo'),
          ),
        ),
        Center(
          child: TextButton.icon(
            onPressed: busy ? null : onVideo,
            icon: const Icon(Icons.videocam_outlined, size: 18),
            label: const Text('Filmer jusqu’à 20 secondes'),
          ),
        ),
      ],
    ),
  );
}

class _FocusCornersPainter extends CustomPainter {
  const _FocusCornersPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = NalviumColors.primaryLight.withValues(alpha: .65)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    const length = 22.0;
    const inset = 18.0;
    final paths = [
      [
        Offset(inset, inset + length),
        Offset(inset, inset),
        Offset(inset + length, inset),
      ],
      [
        Offset(size.width - inset - length, inset),
        Offset(size.width - inset, inset),
        Offset(size.width - inset, inset + length),
      ],
      [
        Offset(inset, size.height - inset - length),
        Offset(inset, size.height - inset),
        Offset(inset + length, size.height - inset),
      ],
      [
        Offset(size.width - inset - length, size.height - inset),
        Offset(size.width - inset, size.height - inset),
        Offset(size.width - inset, size.height - inset - length),
      ],
    ];
    for (final points in paths) {
      canvas.drawPath(Path()..addPolygon(points, false), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RecentProblems extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  const _RecentProblems({required this.items});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Problèmes récents',
        style: TextStyle(
          color: NalviumColors.ink,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 14),
      SizedBox(
        height: 76,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (_, index) {
            final item = items[index];
            return Container(
              width: 190,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: NalviumColors.surface,
                borderRadius: BorderRadius.circular(NalviumRadii.md),
                border: Border.all(color: NalviumColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: NalviumColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.home_repair_service_outlined,
                      color: NalviumColors.primaryLight,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item['category']?.toString() ?? 'Problème domestique',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: NalviumColors.ink,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    ],
  );
}

class PreviewScreen extends StatefulWidget {
  final File file;
  final XFile pickedFile;
  final ImageSource source;
  final String? sessionId;
  final ApiClient api;
  final HistoryStore history;
  final String? equipmentId;
  const PreviewScreen({
    super.key,
    required this.file,
    required this.pickedFile,
    required this.source,
    required this.sessionId,
    required this.api,
    required this.history,
    this.equipmentId,
  });
  @override
  State<PreviewScreen> createState() => _PreviewState();
}

class _PreviewState extends State<PreviewScreen> {
  bool sending = false;
  Future<void> _usePhoto() async {
    setState(() => sending = true);
    try {
      final sessionId = widget.sessionId ?? await widget.api.createSession();
      final mediaId = await widget.api.upload(widget.pickedFile, sessionId);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => AnalysisScreen(
            sessionId: sessionId,
            mediaId: mediaId,
            api: widget.api,
            history: widget.history,
            localFile: widget.file,
            beforeMediaId: mediaId,
            equipmentId: widget.equipmentId,
          ),
        ),
      );
    } catch (error, stackTrace) {
      _logPhotoError(widget.source, error, stackTrace);
      if (mounted) _showError(context, _uploadErrorMessage(error));
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Votre photo'),
      leading: IconButton(
        tooltip: 'Retour',
        onPressed: sending ? null : () => Navigator.pop(context),
        icon: const Icon(Icons.close_rounded),
      ),
    ),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionLabel('Vérifiez le cadrage'),
            const SizedBox(height: 10),
            Text(
              'La zone importante est-elle bien visible ?',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child: Container(
                  width: double.infinity,
                  color: NalviumColors.ink,
                  child: Image.file(widget.file, fit: BoxFit.contain),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Vous pourrez ajouter une autre photo si un détail doit être vérifié.',
              style: TextStyle(
                color: NalviumColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: sending ? null : () => Navigator.pop(context),
                    child: const Text('Reprendre'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: sending ? null : _usePhoto,
                    icon: sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.auto_awesome),
                    label: Text(sending ? 'Envoi…' : 'Analyser cette photo'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class VideoPreviewScreen extends StatefulWidget {
  final XFile pickedFile;
  final ApiClient api;
  final HistoryStore history;
  final String? sessionId;
  final String? equipmentId;
  const VideoPreviewScreen({
    super.key,
    required this.pickedFile,
    required this.api,
    required this.history,
    this.sessionId,
    this.equipmentId,
  });
  @override
  State<VideoPreviewScreen> createState() => _VideoPreviewState();
}

class _VideoPreviewState extends State<VideoPreviewScreen> {
  bool sending = false;
  Future<void> _analyze() async {
    setState(() => sending = true);
    try {
      final session =
          widget.sessionId ??
          await widget.api.createSession(equipmentId: widget.equipmentId);
      final mediaId = await widget.api.uploadVideo(widget.pickedFile, session);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => AnalysisScreen(
            sessionId: session,
            mediaId: mediaId,
            api: widget.api,
            history: widget.history,
            equipmentId: widget.equipmentId,
          ),
        ),
      );
    } catch (error) {
      if (mounted) _showError(context, error.toString());
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Votre vidéo')),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionLabel('Courte vidéo'),
            const SizedBox(height: 12),
            Text(
              'Montrez uniquement le moment où le problème apparaît.',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: NalviumColors.surfaceAlternative,
                  borderRadius: BorderRadius.circular(26),
                ),
                child: const Center(
                  child: Icon(
                    Icons.videocam_outlined,
                    size: 64,
                    color: NalviumColors.primaryLight,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: sending ? null : _analyze,
                icon: const Icon(Icons.auto_awesome),
                label: Text(sending ? 'Envoi…' : 'Analyser cette vidéo'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class AnalysisScreen extends StatefulWidget {
  final String sessionId;
  final String? mediaId;
  final ApiClient api;
  final HistoryStore history;
  final String initialText;
  final File? localFile;
  final String? beforeMediaId;
  final String? equipmentId;
  const AnalysisScreen({
    super.key,
    required this.sessionId,
    required this.mediaId,
    required this.api,
    required this.history,
    this.initialText = '',
    this.localFile,
    this.beforeMediaId,
    this.equipmentId,
  });
  @override
  State<AnalysisScreen> createState() => _AnalysisState();
}

class _AnalysisState extends State<AnalysisScreen> {
  late Future<Map<String, dynamic>> result;
  final question = TextEditingController();
  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    result = widget.api.analyze(
      sessionId: widget.sessionId,
      mediaId: widget.mediaId,
      text: widget.initialText,
      equipmentId: widget.equipmentId,
    );
  }

  @override
  void dispose() {
    question.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Nalvium regarde'),
      leading: IconButton(
        tooltip: 'Retour',
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back_rounded),
      ),
    ),
    body: FutureBuilder<Map<String, dynamic>>(
      future: result,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return _AnalysisLoading(file: widget.localFile);
        }
        if (snapshot.hasError) {
          return _AnalysisError(onRetry: () => setState(_load));
        }
        return _AnalysisContent(
          data: snapshot.data!,
          widget: widget,
          question: question,
        );
      },
    ),
  );
}

class _AnalysisLoading extends StatefulWidget {
  final File? file;
  const _AnalysisLoading({this.file});
  @override
  State<_AnalysisLoading> createState() => _AnalysisLoadingState();
}

class _AnalysisLoadingState extends State<_AnalysisLoading> {
  int index = 0;
  late final ticker = Stream.periodic(const Duration(milliseconds: 1500))
      .listen((_) {
        if (mounted) setState(() => index = (index + 1) % messages.length);
      });
  static const messages = [
    'J’examine la photo…',
    'Je regarde les éléments visibles…',
    'Je vérifie ce qu’on peut faire en sécurité…',
  ];
  @override
  void dispose() {
    ticker.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.file != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: Image.file(
                widget.file!,
                width: double.infinity,
                height: 270,
                fit: BoxFit.cover,
              ),
            ),
          const SizedBox(height: 28),
          const Icon(
            Icons.auto_awesome,
            color: NalviumColors.primaryLight,
            size: 26,
          ),
          const SizedBox(height: 16),
          const Text(
            'Analyse en cours…',
            style: TextStyle(color: NalviumColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 10),
          Text(
            messages[index],
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          const SizedBox.shrink(),
        ],
      ),
    ),
  );
}

class _AnalysisError extends StatelessWidget {
  final VoidCallback onRetry;
  const _AnalysisError({required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            size: 54,
            color: NalviumColors.warning,
          ),
          const SizedBox(height: 18),
          Text(
            'L’analyse n’a pas abouti',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text(
            'Vérifiez votre connexion puis réessayez.',
            textAlign: TextAlign.center,
            style: TextStyle(color: NalviumColors.textSecondary),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onRetry,
              child: const Text('Réessayer'),
            ),
          ),
        ],
      ),
    ),
  );
}

class _AnalysisContent extends StatelessWidget {
  final Map<String, dynamic> data;
  final AnalysisScreen widget;
  final TextEditingController question;
  const _AnalysisContent({
    required this.data,
    required this.widget,
    required this.question,
  });
  bool get stopped =>
      data['risk']?['stop_diy'] == true ||
      data['next_action']?['type'] == 'safety_stop';
  Future<void> _readInstruction(String text) async {
    final tts = FlutterTts();
    await tts.setLanguage('fr-FR');
    await tts.speak(text);
  }

  Future<void> _newPhoto(BuildContext context) async {
    try {
      final photo = await ImagePicker().pickImage(
        source: ImageSource.camera,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 84,
      );
      if (photo == null || !context.mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PreviewScreen(
            file: File(photo.path),
            pickedFile: photo,
            source: ImageSource.camera,
            sessionId: widget.sessionId,
            api: widget.api,
            history: widget.history,
            equipmentId: widget.equipmentId,
          ),
        ),
      );
    } catch (error) {
      if (context.mounted) {
        _showError(context, _photoErrorMessage(ImageSource.camera, error));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final action = data['next_action'] as Map<String, dynamic>? ?? {};
    final type = action['type']?.toString();
    if (stopped) {
      return SafetyStopScreen(
        data: data,
        sessionId: widget.sessionId,
        api: widget.api,
      );
    }
    final observations = _strings(data['observations']);
    final hypotheses = (data['hypotheses'] as List? ?? [])
        .whereType<Map>()
        .map((item) => item['label']?.toString() ?? '')
        .where((item) => item.isNotEmpty)
        .toList();
    final missing = _strings(data['missing_information']);
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      children: [
        if (widget.localFile != null)
          SurfaceCard(
            padding: EdgeInsets.zero,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: SizedBox(
                height: 170,
                width: double.infinity,
                child: Image.file(widget.localFile!, fit: BoxFit.cover),
              ),
            ),
          ),
        if (widget.localFile != null) const SizedBox(height: 24),
        const SectionLabel('Ce que je vois'),
        const SizedBox(height: 10),
        Text(
          observations.isEmpty
              ? 'Je vois des éléments à vérifier.'
              : observations.first,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        if (observations.length > 1)
          ...observations
              .skip(1)
              .map(
                (item) => Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '• $item',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ),
        const SizedBox(height: 24),
        SurfaceCard(
          color: NalviumColors.surfaceAlternative,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.lightbulb_outline,
                    color: NalviumColors.primary,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Cause possible',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                hypotheses.isEmpty
                    ? 'Je n’ai pas encore assez d’éléments pour proposer une cause.'
                    : hypotheses.first,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: NalviumColors.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'C’est une hypothèse, pas une certitude. Nous allons vérifier un point.',
                style: TextStyle(
                  color: NalviumColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        if (missing.isNotEmpty) ...[
          const SizedBox(height: 24),
          const SectionLabel('À vérifier'),
          const SizedBox(height: 10),
          Text(missing.first, style: Theme.of(context).textTheme.bodyLarge),
        ],
        const SizedBox(height: 32),
        const SectionLabel('Voici ce qu’on va faire'),
        const SizedBox(height: 10),
        Text(
          action['instruction']?.toString() ?? 'Nous allons vérifier un point.',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        if ((action['required_items'] as List? ?? []).isNotEmpty) ...[
          const SizedBox(height: 16),
          const SectionLabel('Matériel éventuel'),
          const SizedBox(height: 8),
          Text(
            (action['required_items'] as List)
                .map(
                  (item) => item is Map
                      ? item['name']?.toString() ?? ''
                      : item.toString(),
                )
                .where((item) => item.isNotEmpty)
                .join('  •  '),
            style: const TextStyle(color: NalviumColors.textSecondary),
          ),
        ],
        TextButton.icon(
          onPressed: () =>
              _readInstruction(action['instruction']?.toString() ?? ''),
          icon: const Icon(Icons.volume_up_outlined),
          label: const Text('Lire l’étape'),
        ),
        const SizedBox(height: 24),
        if (type == 'request_photo')
          FilledButton.icon(
            onPressed: () => _newPhoto(context),
            icon: const Icon(Icons.photo_camera_outlined),
            label: const Text('Ajouter une photo'),
          )
        else if (type == 'ask_question') ...[
          TextField(
            controller: question,
            decoration: const InputDecoration(
              labelText: 'Votre réponse',
              hintText: 'Répondez avec vos mots',
            ),
          ),
          const SizedBox(height: 10),
          FilledButton(
            onPressed: () {
              if (question.text.trim().isEmpty) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => AnalysisScreen(
                    sessionId: widget.sessionId,
                    mediaId: null,
                    api: widget.api,
                    history: widget.history,
                    initialText: question.text.trim(),
                    equipmentId: widget.equipmentId,
                  ),
                ),
              );
            },
            child: const Text('Continuer'),
          ),
        ] else if (type == 'instruction' || type == 'verify')
          FilledButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => VerificationScreen(
                  sessionId: widget.sessionId,
                  api: widget.api,
                  history: widget.history,
                  beforeFile: widget.localFile,
                  beforeMediaId: widget.beforeMediaId,
                  equipmentId: widget.equipmentId,
                ),
              ),
            ),
            child: const Text('C’est fait'),
          ),
        const SizedBox(height: 10),
        SimilarCasesSection(sessionId: widget.sessionId, api: widget.api),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AssistantScreen(
                contextType: 'diagnostic',
                contextId: widget.sessionId,
                equipmentId: widget.equipmentId,
              ),
            ),
          ),
          icon: const Icon(Icons.auto_awesome_outlined),
          label: const Text('Continuer avec Nalvium'),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProfessionalDossierScreen(
                sessionId: widget.sessionId,
                api: widget.api,
                equipmentId: widget.equipmentId,
              ),
            ),
          ),
          icon: const Icon(Icons.handyman_outlined),
          label: const Text('Je n’y arrive pas'),
        ),
      ],
    );
  }
}

class SimilarCasesSection extends StatelessWidget {
  final String sessionId;
  final ApiClient api;
  const SimilarCasesSection({
    super.key,
    required this.sessionId,
    required this.api,
  });
  @override
  Widget build(
    BuildContext context,
  ) => FutureBuilder<List<Map<String, dynamic>>>(
    future: api.similarCases(sessionId),
    builder: (context, snapshot) {
      final cases = snapshot.data ?? const <Map<String, dynamic>>[];
      if (cases.isEmpty) return const SizedBox.shrink();
      return SurfaceCard(
        color: NalviumColors.surfaceAlternative,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionLabel('Cas similaires'),
            const SizedBox(height: 8),
            ...cases
                .take(3)
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      '${item['problem_summary'] ?? 'Problème similaire'} — ${item['solution_summary'] ?? 'résolution enregistrée'}',
                      style: const TextStyle(height: 1.35),
                    ),
                  ),
                ),
            const Text(
              'Un cas similaire n’est pas une confirmation de votre diagnostic.',
              style: TextStyle(color: NalviumColors.textTertiary, fontSize: 12),
            ),
          ],
        ),
      );
    },
  );
}

class SafetyStopScreen extends StatelessWidget {
  final Map<String, dynamic> data;
  final String? sessionId;
  final ApiClient? api;
  const SafetyStopScreen({
    super.key,
    required this.data,
    this.sessionId,
    this.api,
  });
  @override
  Widget build(BuildContext context) {
    final risk = data['risk'] as Map<String, dynamic>? ?? {};
    final flags = _strings(risk['flags']);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: NalviumColors.danger.withValues(alpha: .12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: NalviumColors.danger,
                size: 42,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'On s’arrête ici.',
              style: TextStyle(
                color: NalviumColors.ink,
                fontSize: 36,
                height: 1.05,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              flags.isEmpty
                  ? 'Situation potentiellement dangereuse'
                  : flags.first,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (sessionId != null && api != null) ...[
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProfessionalDossierScreen(
                        sessionId: sessionId!,
                        api: api!,
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.description_outlined),
                  label: const Text('Préparer une demande professionnelle'),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              data['assistant_message']?.toString() ?? 'Ne poursuivez pas cette intervention vous-même. Mettez-vous en sécurité et demandez l’aide appropriée.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: NalviumColors.danger,
                ),
                onPressed: () =>
                    Navigator.popUntil(context, (route) => route.isFirst),
                child: const Text('J’ai compris'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VerificationScreen extends StatelessWidget {
  final String sessionId;
  final ApiClient api;
  final HistoryStore history;
  final File? beforeFile;
  final String? beforeMediaId;
  final String? equipmentId;
  const VerificationScreen({
    super.key,
    required this.sessionId,
    required this.api,
    required this.history,
    this.beforeFile,
    this.beforeMediaId,
    this.equipmentId,
  });
  Future<void> _saveResolved(
    BuildContext context, {
    String? afterPath,
    String? afterMediaId,
  }) async {
    String? repairId;
    try {
      final repair = await api.createRepair({
        'session_id': sessionId,
        'equipment_id': equipmentId,
        'category': 'domestique',
        'title': 'Problème domestique résolu',
        'summary': 'Le problème a été indiqué comme résolu par l’utilisateur.',
        'before_media_id': beforeMediaId,
        'after_media_id': afterMediaId,
        'status': 'resolved',
        'steps_completed': <String>[],
        'professional_required': false,
      });
      repairId = repair['id']?.toString();
    } catch (_) {}
    await history.save({
      'session_id': sessionId,
      'status': 'resolved',
      'date': DateTime.now().toIso8601String(),
      'category': 'domestique',
      'title': 'Problème domestique résolu',
      'before_path': beforeFile?.path,
      'after_path': afterPath,
      'repair_id': repairId,
    });
    if (!context.mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => RepairCompleteScreen(
          beforeFile: beforeFile,
          afterPath: afterPath,
          api: api,
          repairId: repairId,
          beforeMediaId: beforeMediaId,
          afterMediaId: afterMediaId,
        ),
      ),
    );
  }

  Future<void> _resolved(BuildContext context) async => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => AfterPhotoScreen(
        sessionId: sessionId,
        api: api,
        history: history,
        beforeFile: beforeFile,
        equipmentId: equipmentId,
        onSkipped: () => _saveResolved(context),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: IconButton(
        tooltip: 'Retour',
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back_rounded),
      ),
    ),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Spacer(),
            Container(
              width: 66,
              height: 66,
              decoration: const BoxDecoration(
                color: NalviumColors.surfaceAlternative,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: NalviumColors.primary,
                size: 34,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Est-ce que le problème est résolu ?',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 16),
            Text(
              'Dites-le-moi pour que je sache quoi faire ensuite.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => _resolved(context),
                child: const Text('Oui, montrer le résultat'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _saveResolved(context),
                child: const Text('Passer la photo'),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Non, toujours pas'),
            ),
          ],
        ),
      ),
    ),
  );
}

class AfterPhotoScreen extends StatefulWidget {
  final String sessionId;
  final ApiClient api;
  final HistoryStore history;
  final File? beforeFile;
  final VoidCallback onSkipped;
  final String? equipmentId;
  const AfterPhotoScreen({
    super.key,
    required this.sessionId,
    required this.api,
    required this.history,
    required this.beforeFile,
    required this.onSkipped,
    this.equipmentId,
  });
  @override
  State<AfterPhotoScreen> createState() => _AfterPhotoScreenState();
}

class _AfterPhotoScreenState extends State<AfterPhotoScreen> {
  bool busy = false;
  void _skip() {
    Navigator.pop(context);
    widget.onSkipped();
  }

  Future<void> _pickAfter() async {
    setState(() => busy = true);
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.camera,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 84,
      );
      if (picked == null || !mounted) return;
      final file = File(picked.path);
      final mediaId = await widget.api.upload(picked, widget.sessionId);
      final verification = await widget.api.verifyRepair(
        widget.sessionId,
        mediaId,
      );
      final verificationStatus = verification['status']?.toString();
      if (verificationStatus != 'resolved') {
        if (mounted) {
          _showError(
            context,
            verificationStatus == 'worsened'
                ? 'La situation semble s’être aggravée. Arrêtez ici et demandez un professionnel.'
                : 'Je ne peux pas confirmer la résolution avec cette photo. Vous pouvez réessayer avec une vue plus proche.',
          );
        }
        return;
      }
      String? repairId;
      try {
        final repair = await widget.api.createRepair({
          'session_id': widget.sessionId,
          'equipment_id': widget.equipmentId,
          'category': 'domestique',
          'title': 'Problème domestique résolu',
          'summary':
              'Le problème visible semble corrigé après l’action guidée.',
          'after_media_id': mediaId,
          'status': 'resolved',
          'steps_completed': <String>[],
          'professional_required': false,
        });
        repairId = repair['id']?.toString();
      } catch (_) {}
      await widget.history.save({
        'session_id': widget.sessionId,
        'status': 'resolved',
        'date': DateTime.now().toIso8601String(),
        'category': 'domestique',
        'title': 'Problème domestique résolu',
        'before_path': widget.beforeFile?.path,
        'after_path': file.path,
        'repair_id': repairId,
      });
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => RepairCompleteScreen(
            beforeFile: widget.beforeFile,
            afterPath: file.path,
            api: widget.api,
            repairId: repairId,
            afterMediaId: mediaId,
          ),
        ),
      );
    } catch (error) {
      if (mounted) _showError(context, _uploadErrorMessage(error));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Le résultat'),
      leading: IconButton(
        tooltip: 'Retour',
        onPressed: busy ? null : () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back_rounded),
      ),
    ),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Spacer(),
            const Icon(
              Icons.compare_outlined,
              size: 54,
              color: NalviumColors.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Montrez-moi le résultat',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 12),
            Text(
              'Une photo après l’intervention est facultative. Elle permet simplement de comparer ce qui est visible.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: busy ? null : _pickAfter,
                icon: const Icon(Icons.photo_camera_outlined),
                label: Text('Prendre une photo après'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: busy ? null : _skip,
                child: const Text('Passer'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class RepairCompleteScreen extends StatelessWidget {
  final File? beforeFile;
  final String? afterPath;
  final ApiClient api;
  final String? repairId;
  final String? beforeMediaId;
  final String? afterMediaId;
  const RepairCompleteScreen({
    super.key,
    required this.beforeFile,
    required this.afterPath,
    required this.api,
    required this.repairId,
    this.beforeMediaId,
    this.afterMediaId,
  });

  @override
  Widget build(BuildContext context) {
    final hasComparison = beforeFile != null || afterPath != null;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 18),
              Row(
                children: [
                  const SectionLabel('Votre réparation'),
                  const Spacer(),
                  const StatusChip(
                    label: 'Résolu',
                    icon: Icons.check_circle_outline,
                    color: NalviumColors.success,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (hasComparison)
                Row(
                  children: [
                    if (beforeFile != null)
                      Expanded(
                        child: _ComparePhoto(label: 'AVANT', file: beforeFile!),
                      ),
                    if (beforeFile != null && afterPath != null)
                      const SizedBox(width: 10),
                    if (afterPath != null)
                      Expanded(
                        child: _ComparePhoto(
                          label: 'APRÈS',
                          file: File(afterPath!),
                        ),
                      ),
                  ],
                ),
              const Spacer(),
              const Icon(
                Icons.check_circle_rounded,
                color: NalviumColors.success,
                size: 62,
              ),
              const SizedBox(height: 20),
              Text(
                'Le problème visible semble résolu.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 10),
              const Text(
                'Cette comparaison ne constitue pas une certification de sécurité ou de conformité.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: NalviumColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 24),
              if (repairId != null)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final actor = await CommunityIdentity.id();
                      if (!context.mounted) return;
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CommunityCreatePostScreen(
                            api: api,
                            actorKey: actor,
                            repairId: repairId,
                            beforeMediaId: beforeMediaId,
                            afterMediaId: afterMediaId,
                            beforeFile: beforeFile,
                            afterFile: afterPath == null
                                ? null
                                : File(afterPath!),
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.ios_share_outlined),
                    label: const Text('Partager mon avant / après'),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () =>
                      Navigator.popUntil(context, (route) => route.isFirst),
                  child: const Text('Terminer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ComparePhoto extends StatelessWidget {
  final String label;
  final File file;
  const _ComparePhoto({required this.label, required this.file});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.1,
          color: NalviumColors.textSecondary,
        ),
      ),
      const SizedBox(height: 7),
      ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: AspectRatio(
          aspectRatio: .9,
          child: Image.file(file, fit: BoxFit.cover),
        ),
      ),
    ],
  );
}

class ShareRepairScreen extends StatefulWidget {
  final ApiClient api;
  final String repairId;
  const ShareRepairScreen({
    super.key,
    required this.api,
    required this.repairId,
  });
  @override
  State<ShareRepairScreen> createState() => _ShareRepairScreenState();
}

class _ShareRepairScreenState extends State<ShareRepairScreen> {
  bool busy = false;
  Future<void> _share() async {
    setState(() => busy = true);
    try {
      await widget.api.shareRepair(
        widget.repairId,
        includeBefore: false,
        includeAfter: false,
      );
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ShareDoneScreen()),
        );
      }
    } catch (_) {
      if (mounted) {
        _showError(
          context,
          'Le partage n’a pas pu être enregistré. Réessayez.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Partager anonymement')),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Spacer(),
            const Icon(
              Icons.public_outlined,
              color: NalviumColors.primary,
              size: 56,
            ),
            const SizedBox(height: 24),
            Text(
              'Cette réparation peut aider d’autres personnes.',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            Text(
              'Votre accord est nécessaire. Aucun nom, téléphone, adresse, code postal précis, donnée de lead ou EXIF/GPS ne sera publié.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 18),
            const SurfaceCard(
              color: NalviumColors.surfaceAlternative,
              child: Text(
                'Pour cette première version, seul le cas anonymisé est enregistré. Les médias privés restent privés tant qu’une dérivation publique contrôlée n’est pas configurée.',
                style: TextStyle(color: NalviumColors.ink, height: 1.4),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: busy ? null : _share,
                child: Text(
                  busy ? 'Enregistrement…' : 'J’accepte le partage anonyme',
                ),
              ),
            ),
            TextButton(
              onPressed: busy ? null : () => Navigator.pop(context),
              child: const Text('Non merci'),
            ),
          ],
        ),
      ),
    ),
  );
}

class ShareDoneScreen extends StatelessWidget {
  const ShareDoneScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: NalviumColors.success,
              size: 66,
            ),
            const SizedBox(height: 24),
            Text(
              'Merci pour ce partage.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            const Text(
              'Le cas a été enregistré anonymement. Vos médias privés restent protégés.',
              textAlign: TextAlign.center,
              style: TextStyle(color: NalviumColors.textSecondary),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () =>
                    Navigator.popUntil(context, (route) => route.isFirst),
                child: const Text('Terminer'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class SuccessScreen extends StatelessWidget {
  const SuccessScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 92,
              height: 92,
              decoration: const BoxDecoration(
                color: NalviumColors.surfaceAlternative,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: NalviumColors.success,
                size: 52,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Le problème semble résolu.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            Text(
              'Bien joué. Si la situation change, vous pourrez toujours reprendre une photo.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () =>
                    Navigator.popUntil(context, (route) => route.isFirst),
                child: const Text('Terminer'),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => HistoryScreen(history: HistoryStore()),
                ),
              ),
              child: const Text('Voir mon historique'),
            ),
          ],
        ),
      ),
    ),
  );
}

class ProfessionalDossierScreen extends StatefulWidget {
  final String sessionId;
  final ApiClient api;
  final String? equipmentId;
  const ProfessionalDossierScreen({
    super.key,
    required this.sessionId,
    required this.api,
    this.equipmentId,
  });
  @override
  State<ProfessionalDossierScreen> createState() => _ProfessionalDossierState();
}

class _ProfessionalDossierState extends State<ProfessionalDossierScreen> {
  late Future<Map<String, dynamic>> sessionFuture;
  final summary = TextEditingController();
  final firstName = TextEditingController(),
      phone = TextEditingController(),
      city = TextEditingController(),
      postal = TextEditingController(),
      window = TextEditingController();
  final selected = <String>{};
  bool consent = false;
  bool sending = false;
  @override
  void initState() {
    super.initState();
    sessionFuture = widget.api.getSession(widget.sessionId);
  }

  @override
  void dispose() {
    for (final item in [summary, firstName, phone, city, postal, window]) {
      item.dispose();
    }
    super.dispose();
  }

  Future<void> _create() async {
    if (!consent) {
      _showError(
        context,
        'Cochez la case pour confirmer ce qui sera transmis.',
      );
      return;
    }
    setState(() => sending = true);
    try {
      final result = await widget.api.createProfessionalDossier(
        sessionId: widget.sessionId,
        equipmentId: widget.equipmentId,
        mediaIds: selected.toList(),
        summary: summary.text.trim(),
        firstName: firstName.text.trim(),
        phone: phone.text.trim(),
        city: city.text.trim(),
        postalCode: postal.text.trim(),
        desiredTimeWindow: window.text.trim(),
        consent: true,
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => DossierReadyScreen(dossier: result)),
      );
    } catch (error) {
      if (mounted) _showError(context, error.toString());
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Préparer ma demande')),
    body: SafeArea(
      child: FutureBuilder<Map<String, dynamic>>(
        future: sessionFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final session = snapshot.data!;
          final media = (session['media'] as List? ?? [])
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
          final analyses = (session['messages'] as List? ?? [])
              .whereType<Map>()
              .map((item) => item['content'])
              .whereType<Map>()
              .map((item) => item['analysis'])
              .whereType<Map>()
              .toList();
          final analysis = analyses.isEmpty ? null : analyses.last;
          final observations = (analysis?['observations'] as List? ?? []).join(
            ' • ',
          );
          return ListView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            children: [
              const StatusChip(
                label: 'Dossier privé',
                icon: Icons.lock_outline,
                color: NalviumColors.primary,
              ),
              const SizedBox(height: 18),
              Text(
                'Ce qui sera préparé',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 18),
              const SectionLabel('Votre problème'),
              const SizedBox(height: 8),
              TextField(
                controller: summary,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Ajoutez un résumé si nécessaire',
                ),
              ),
              const SizedBox(height: 18),
              const SectionLabel('Ce que NALVIUM a observé'),
              const SizedBox(height: 8),
              Text(
                observations.isEmpty
                    ? 'Les observations structurées seront conservées si elles existent.'
                    : observations,
              ),
              const SizedBox(height: 20),
              const SectionLabel('Photos et vidéos sélectionnées'),
              const SizedBox(height: 6),
              if (media.isEmpty)
                const Text(
                  'Aucun média disponible.',
                  style: TextStyle(color: NalviumColors.textSecondary),
                ),
              ...media.map((item) {
                final id = item['id']?.toString() ?? '';
                return CheckboxListTile(
                  value: selected.contains(id),
                  onChanged: (value) => setState(() {
                    if (value == true) {
                      selected.add(id);
                    } else {
                      selected.remove(id);
                    }
                  }),
                  title: Text(
                    item['media_type']?.toString().startsWith('video/') == true
                        ? 'Vidéo du problème'
                        : 'Photo du problème',
                  ),
                  subtitle: Text(
                    id,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  contentPadding: EdgeInsets.zero,
                );
              }),
              const SizedBox(height: 14),
              const Text(
                'Ces éléments seront inclus dans votre demande.',
                style: TextStyle(
                  color: NalviumColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 22),
              const SectionLabel('Coordonnées nécessaires'),
              const SizedBox(height: 8),
              _Field(label: 'Prénom', controller: firstName),
              _Field(
                label: 'Téléphone',
                controller: phone,
                keyboardType: TextInputType.phone,
              ),
              Row(
                children: [
                  Expanded(
                    child: _Field(label: 'Code postal', controller: postal),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _Field(label: 'Ville', controller: city),
                  ),
                ],
              ),
              _Field(
                label: 'Créneau souhaité (facultatif)',
                controller: window,
              ),
              CheckboxListTile(
                value: consent,
                onChanged: (value) => setState(() => consent = value ?? false),
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'J’accepte que les informations sélectionnées soient utilisées pour transmettre ma demande à un professionnel.',
                ),
                subtitle: const Text(
                  'La demande restera prête tant qu’aucun réseau professionnel réel n’est connecté.',
                ),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: sending ? null : _create,
                child: Text(sending ? 'Préparation…' : 'Préparer ma demande'),
              ),
            ],
          );
        },
      ),
    ),
  );
}

class DossierReadyScreen extends StatelessWidget {
  final Map<String, dynamic> dossier;
  const DossierReadyScreen({super.key, required this.dossier});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Demande prête')),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Spacer(),
            const Icon(
              Icons.check_circle_outline,
              color: NalviumColors.primary,
              size: 54,
            ),
            const SizedBox(height: 22),
            Text(
              'Votre dossier est prêt.',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 12),
            const Text(
              'Aucun professionnel n’a été contacté. Le dossier reste privé jusqu’à une prochaine intégration de mise en relation.',
              style: TextStyle(
                color: NalviumColors.textSecondary,
                fontSize: 16,
                height: 1.4,
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () =>
                    Navigator.popUntil(context, (route) => route.isFirst),
                child: const Text('Terminer'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class ProfessionalForm extends StatefulWidget {
  final String sessionId;
  final ApiClient api;
  const ProfessionalForm({
    super.key,
    required this.sessionId,
    required this.api,
  });
  @override
  State<ProfessionalForm> createState() => _ProfessionalFormState();
}

class _ProfessionalFormState extends State<ProfessionalForm> {
  final firstName = TextEditingController(),
      phone = TextEditingController(),
      city = TextEditingController(),
      postal = TextEditingController(),
      window = TextEditingController();
  bool consent = false, sending = false;
  @override
  void dispose() {
    for (final c in [firstName, phone, city, postal, window]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> submit() async {
    if (!consent ||
        firstName.text.trim().isEmpty ||
        phone.text.trim().length < 8 ||
        city.text.trim().isEmpty ||
        postal.text.trim().isEmpty) {
      _showError(
        context,
        'Complétez les coordonnées et acceptez la transmission explicite.',
      );
      return;
    }
    setState(() => sending = true);
    try {
      await widget.api.createLead({
        'session_id': widget.sessionId,
        'first_name': firstName.text.trim(),
        'phone': phone.text.trim(),
        'city': city.text.trim(),
        'postal_code': postal.text.trim(),
        'desired_time_window': window.text.trim(),
        'trade': 'plombier',
        'summary': 'Problème domestique observé dans la session.',
        'urgency': 'normal',
        'consent': true,
        'media_ids': [],
      });
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LeadSentScreen()),
      );
    } catch (_) {
      if (mounted) {
        _showError(context, 'La demande n’a pas pu être envoyée. Réessayez.');
      }
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Trouver un professionnel'),
      leading: IconButton(
        tooltip: 'Retour',
        onPressed: sending ? null : () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back_rounded),
      ),
    ),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        children: [
          const StatusChip(
            label: 'Transmission contrôlée',
            icon: Icons.lock_outline,
            color: NalviumColors.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Ce problème nécessite probablement un professionnel.',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 10),
          Text(
            'Vous gardez le contrôle. Rien ne sera transmis avant votre accord explicite.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          const SurfaceCard(
            color: NalviumColors.surfaceAlternative,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionLabel('Ce qui pourra être envoyé'),
                SizedBox(height: 10),
                Text(
                  'Problème résumé, métier recommandé, zone, téléphone, créneau et uniquement les photos que vous choisissez.',
                  style: TextStyle(
                    color: NalviumColors.ink,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _Field(label: 'Prénom', controller: firstName),
          _Field(
            label: 'Téléphone',
            controller: phone,
            keyboardType: TextInputType.phone,
          ),
          Row(
            children: [
              Expanded(
                child: _Field(
                  label: 'Code postal',
                  controller: postal,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Field(label: 'Ville', controller: city),
              ),
            ],
          ),
          _Field(label: 'Créneau souhaité (facultatif)', controller: window),
          Container(
            decoration: BoxDecoration(
              color: NalviumColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: NalviumColors.border),
            ),
            child: CheckboxListTile(
              value: consent,
              onChanged: (value) => setState(() => consent = value ?? false),
              title: const Text(
                'J’accepte explicitement la transmission de ces données.',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Aucune transmission si cette case reste décochée.',
                style: TextStyle(fontSize: 12),
              ),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: sending ? null : submit,
            child: Text(sending ? 'Envoi sécurisé…' : 'Envoyer ma demande'),
          ),
        ],
      ),
    ),
  );
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  const _Field({
    required this.label,
    required this.controller,
    this.keyboardType,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(labelText: label),
    ),
  );
}

class LeadSentScreen extends StatelessWidget {
  const LeadSentScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.mark_email_read_outlined,
              color: NalviumColors.success,
              size: 70,
            ),
            const SizedBox(height: 24),
            Text(
              'Votre demande est enregistrée.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            Text(
              'Un professionnel n’est pas confirmé avant son acceptation réelle.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () =>
                    Navigator.popUntil(context, (route) => route.isFirst),
                child: const Text('Terminer'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class DescriptionScreen extends StatefulWidget {
  const DescriptionScreen({super.key});
  @override
  State<DescriptionScreen> createState() => _DescriptionState();
}

class _DescriptionState extends State<DescriptionScreen> {
  final controller = TextEditingController();
  final api = const ApiClient();
  final history = HistoryStore();
  bool sending = false;
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (controller.text.trim().isEmpty) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => sending = true);
    try {
      final sessionId = await api.createSession();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => AnalysisScreen(
            sessionId: sessionId,
            mediaId: null,
            api: api,
            history: history,
            initialText: controller.text.trim(),
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        _showError(context, 'Impossible de démarrer le diagnostic. Réessayez.');
      }
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Décrire le problème'),
      leading: IconButton(
        tooltip: 'Retour',
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back_rounded),
      ),
    ),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SectionLabel('Avec vos mots'),
          const SizedBox(height: 10),
          Text(
            'Que se passe-t-il ?',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            maxLines: 6,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Ex. Il y a de l’eau sous l’évier.',
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: sending ? null : submit,
            child: Text(sending ? 'Préparation…' : 'Analyser'),
          ),
        ],
      ),
    ),
  );
}

class HouseScreen extends StatefulWidget {
  final HistoryStore history;
  const HouseScreen({super.key, required this.history});
  @override
  State<HouseScreen> createState() => _HouseScreenState();
}

class _HouseScreenState extends State<HouseScreen> {
  final api = const ApiClient();
  late Future<List<Map<String, dynamic>>> future;
  @override
  void initState() {
    super.initState();
    future = api.listEquipment();
  }

  void _add() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EquipmentAddScreen(api: api, history: widget.history),
      ),
    );
    if (mounted) setState(() => future = api.listEquipment());
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: FutureBuilder<List<Map<String, dynamic>>>(
      future: future,
      builder: (context, snapshot) {
        final items = snapshot.data ?? const <Map<String, dynamic>>[];
        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          children: [
            Row(
              children: [
                const NalviumLogo(),
                const Spacer(),
                IconButton(
                  tooltip: 'Ajouter un équipement',
                  onPressed: _add,
                  icon: const Icon(
                    Icons.add_rounded,
                    color: NalviumColors.primaryLight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            Text('Ma Maison', style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 10),
            Text(
              'Les équipements et l’historique de votre maison.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 28),
            if (snapshot.connectionState == ConnectionState.waiting)
              const Padding(
                padding: EdgeInsets.only(top: 48),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (items.isEmpty) ...[
              const EmptyState(
                icon: Icons.home_work_outlined,
                title: 'Votre maison va se construire ici',
                body: 'Ajoutez un équipement avec une photo ou quelques informations.',
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _add,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Ajouter un équipement'),
              ),
            ] else
              ...items.map(
                (item) => _EquipmentRow(
                  api: api,
                  history: widget.history,
                  equipment: item,
                ),
              ),
          ],
        );
      },
    ),
  );
}

class _EquipmentRow extends StatefulWidget {
  final ApiClient api;
  final HistoryStore history;
  final Map<String, dynamic> equipment;
  const _EquipmentRow({
    required this.api,
    required this.history,
    required this.equipment,
  });
  @override
  State<_EquipmentRow> createState() => _EquipmentRowState();
}

class _EquipmentRowState extends State<_EquipmentRow> {
  File? photo;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final path = await EquipmentPhotoStore().pathFor(
      widget.equipment['primary_media_id']?.toString(),
    );
    if (mounted && path != null) setState(() => photo = File(path));
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: ListTile(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EquipmentDetailScreen(
              api: widget.api,
              history: widget.history,
              equipment: widget.equipment,
              localFile: photo,
            ),
          ),
        );
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(NalviumRadii.md),
        side: const BorderSide(color: NalviumColors.border),
      ),
      tileColor: NalviumColors.surface,
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 66,
          height: 66,
          child: photo != null
              ? Image.file(photo!, fit: BoxFit.cover)
              : Container(
                  color: NalviumColors.surfaceAlternative,
                  child: const Icon(
                    Icons.home_repair_service_outlined,
                    color: NalviumColors.primaryLight,
                  ),
                ),
        ),
      ),
      title: Text(
        widget.equipment['display_name']?.toString() ?? 'Équipement',
        style: const TextStyle(
          color: NalviumColors.ink,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 5),
        child: Text(
          [
            widget.equipment['brand']?.toString() ?? '',
            widget.equipment['room']?.toString() ?? '',
          ].where((value) => value.isNotEmpty).join('  •  '),
          style: const TextStyle(color: NalviumColors.textSecondary),
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: NalviumColors.textTertiary,
      ),
    ),
  );
}

class ActivityScreen extends StatelessWidget {
  final HistoryStore history;
  final ApiClient api = const ApiClient();
  const ActivityScreen({super.key, required this.history});
  Future<List<Map<String, dynamic>>> _load() async {
    try {
      final remote = await api.activity();
      return remote
          .map(
            (item) => {
              ...item,
              'category': item['title'] ?? item['type'],
              'date': item['date'],
              'status': item['status'] == 'resolved' ? 'resolved' : 'active',
            },
          )
          .toList();
    } catch (_) {
      return history.list();
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: FutureBuilder<List<Map<String, dynamic>>>(
      future: _load(),
      builder: (context, snapshot) {
        final items = snapshot.data ?? const <Map<String, dynamic>>[];
        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          children: [
            const NalviumLogo(),
            const SizedBox(height: 32),
            Text('Activité', style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 10),
            Text(
              'Vos analyses et échanges récents.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 30),
            if (items.isNotEmpty)
              const Text(
                'RÉCENT',
                style: TextStyle(
                  color: NalviumColors.textTertiary,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                ),
              ),
            if (items.isNotEmpty) const SizedBox(height: 12),
            if (items.isEmpty)
              const EmptyState(
                icon: Icons.timeline_outlined,
                title: 'Aucune activité pour le moment',
                body: 'Votre premier diagnostic apparaîtra ici.',
              )
            else
              ...items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _HistoryTile(item: item),
                ),
              ),
          ],
        );
      },
    ),
  );
}

class HistoryScreen extends StatelessWidget {
  final HistoryStore history;
  const HistoryScreen({super.key, required this.history});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Historique'),
      leading: IconButton(
        tooltip: 'Retour',
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back_rounded),
      ),
    ),
    body: FutureBuilder<List<Map<String, dynamic>>>(
      future: history.list(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snapshot.data!;
        if (items.isEmpty) {
          return const EmptyState(
            icon: Icons.history_rounded,
            title: 'Votre historique est vide',
            body: 'Vos diagnostics apparaîtront ici au fur et à mesure.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(24),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (_, index) => _HistoryTile(item: items[index]),
        );
      },
    ),
  );
}

class _HistoryTile extends StatelessWidget {
  final Map<String, dynamic> item;
  const _HistoryTile({required this.item});
  @override
  Widget build(BuildContext context) {
    final status = item['status']?.toString() ?? 'Session';
    final resolved = status == 'resolved';
    final date = item['date']?.toString() ?? '';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: NalviumColors.surfaceElevated,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              resolved
                  ? Icons.check_rounded
                  : Icons.home_repair_service_outlined,
              color: NalviumColors.primaryLight,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['category']?.toString() ?? 'Diagnostic domestique',
                  style: const TextStyle(
                    color: NalviumColors.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  date.length >= 10 ? date.substring(0, 10) : date,
                  style: const TextStyle(
                    color: NalviumColors.textTertiary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          StatusChip(
            label: resolved ? 'Résolu' : 'En cours',
            icon: resolved ? Icons.check_circle_outline : Icons.timelapse,
            color: resolved ? NalviumColors.success : NalviumColors.warning,
          ),
        ],
      ),
    );
  }
}

List<String> _strings(Object? value) => (value as List? ?? [])
    .map((item) => item.toString())
    .where((item) => item.trim().isNotEmpty)
    .toList();
void _showError(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

String _photoErrorMessage(ImageSource source, Object error) {
  if (error is ApiException) return error.message;
  if (error is PlatformException &&
      (error.code == 'camera_access_denied' ||
          error.code == 'photo_access_denied' ||
          error.code == 'permission_denied')) {
    return source == ImageSource.camera
        ? 'Accès à la caméra refusé. Autorisez la caméra dans les réglages Android.'
        : 'La sélection de photos a été refusée. Autorisez son accès dans les réglages Android.';
  }
  if (error is FileSystemException) {
    return 'La photo n’est plus accessible. Reprenez-la ou choisissez-la à nouveau.';
  }
  return source == ImageSource.camera
      ? 'La prise de photo a échoué. Réessayez.'
      : 'La sélection de la photo a échoué. Réessayez.';
}

String _uploadErrorMessage(Object error) {
  if (error is ApiException) return error.message;
  if (error is FileSystemException) {
    return 'La photo n’est plus accessible. Reprenez-la ou choisissez-la à nouveau.';
  }
  return 'La photo n’a pas pu être envoyée. Réessayez.';
}

void _logPhotoError(ImageSource source, Object error, StackTrace stackTrace) {
  if (kDebugMode) {
    debugPrint(
      'NALVIUM media flow failed (${source.name}): ${error.runtimeType}',
    );
    debugPrintStack(stackTrace: stackTrace);
  }
}
