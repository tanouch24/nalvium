import 'package:flutter/material.dart';

import '../theme/nalvium_theme.dart';

class NalviumLogo extends StatelessWidget {
  final bool compact;
  const NalviumLogo({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: compact ? 28 : 34,
        height: compact ? 28 : 34,
        decoration: BoxDecoration(
          color: NalviumColors.surfaceElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: NalviumColors.border),
        ),
        child: const Icon(
          Icons.auto_awesome,
          color: NalviumColors.primaryLight,
          size: 17,
        ),
      ),
      const SizedBox(width: 10),
      Text(
        'NALVIUM',
        style: TextStyle(
          color: NalviumColors.ink,
          fontSize: compact ? 15 : 17,
          fontWeight: FontWeight.w800,
          letterSpacing: 2.4,
        ),
      ),
    ],
  );
}

class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: const TextStyle(
      color: NalviumColors.textTertiary,
      fontSize: 11,
      fontWeight: FontWeight.w800,
      letterSpacing: 1.1,
    ),
  );
}

class SurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  const SurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(NalviumSpacing.lg),
    this.color,
  });

  @override
  Widget build(BuildContext context) => Card(
    color: color,
    child: Padding(padding: padding, child: child),
  );
}

class StatusChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const StatusChip({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.11),
      borderRadius: BorderRadius.circular(NalviumRadii.pill),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class SafetyBanner extends StatelessWidget {
  const SafetyBanner({super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(NalviumSpacing.md),
    decoration: BoxDecoration(
      color: NalviumColors.surfaceAlternative,
      borderRadius: BorderRadius.circular(NalviumRadii.md),
    ),
    child: const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.shield_outlined, color: NalviumColors.primary, size: 21),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            'En cas de gaz, fumée ou électricité exposée, ne touchez à rien et demandez de l’aide.',
            style: TextStyle(
              color: NalviumColors.primaryDark,
              fontSize: 13,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

class PhotoThumbnail extends StatelessWidget {
  final ImageProvider image;
  final double size;
  const PhotoThumbnail({super.key, required this.image, this.size = 70});

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(NalviumRadii.sm),
    child: Image(
      image: image,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => Container(
        width: size,
        height: size,
        color: NalviumColors.surfaceAlternative,
        child: const Icon(Icons.image_not_supported_outlined),
      ),
    ),
  );
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(NalviumSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: const BoxDecoration(
              color: NalviumColors.surfaceAlternative,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: NalviumColors.primary, size: 30),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            body,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    ),
  );
}

class ScanIndicator extends StatefulWidget {
  const ScanIndicator({super.key});

  @override
  State<ScanIndicator> createState() => _ScanIndicatorState();
}

class _ScanIndicatorState extends State<ScanIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1900),
  )..repeat();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, child) => Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 154,
          height: 154,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: NalviumColors.surfaceAlternative,
            border: Border.all(
              color: NalviumColors.primary.withValues(
                alpha: 0.18 + controller.value * 0.2,
              ),
              width: 2,
            ),
          ),
        ),
        Transform.rotate(
          angle: controller.value * 6.28,
          child: Container(
            width: 104,
            height: 104,
            decoration: BoxDecoration(
              color: NalviumColors.primary,
              borderRadius: BorderRadius.circular(32),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x442864FF),
                  blurRadius: 24,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.center_focus_strong_outlined,
              color: Colors.white,
              size: 43,
            ),
          ),
        ),
      ],
    ),
  );
}
