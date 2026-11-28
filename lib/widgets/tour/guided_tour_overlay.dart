// 5.7 Hướng dẫn lần đầu (spec 022): the screen around the feature being shown is dimmed and
// blurred; the feature itself stays sharp inside a glowing spotlight, and Gret explains it in a
// card. Tap anywhere or "Tiếp nhé" for the next step; "Bỏ qua" or Back ends the tour.
import 'dart:ui' show ImageFilter;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/guided_tour.dart';
import '../../data/mascot_mood.dart';
import '../../l10n/app_strings.dart';
import '../../providers/tour_providers.dart';
import '../../theme/app_theme.dart';
import '../mascot/mascot_view.dart';
import 'tour_keys.dart';

class GuidedTourOverlay extends ConsumerStatefulWidget {
  const GuidedTourOverlay({super.key});

  @override
  ConsumerState<GuidedTourOverlay> createState() => _GuidedTourOverlayState();
}

class _GuidedTourOverlayState extends ConsumerState<GuidedTourOverlay> {
  /// The spotlight, in this overlay's coordinates; null until the target was found.
  Rect? _hole;
  int? _located;

  static bool _isShown(TourTarget target) => TourKeys.of(target).currentContext != null;

  /// Scrolls the target into view, then measures it once the scroll has settled.
  Future<void> _locate(int step) async {
    final notifier = ref.read(guidedTourProvider.notifier);
    final shown = GuidedTour.firstShown(step, _isShown);
    if (shown == null) {
      await notifier.finish();
      return;
    }
    if (shown != step) {
      notifier.goTo(shown);
      return;
    }
    final target = TourKeys.of(GuidedTour.steps[step].target).currentContext!;
    final animationsOff = MediaQuery.disableAnimationsOf(context);
    await Scrollable.ensureVisible(
      target,
      alignment: 0.4,
      duration: animationsOff ? Duration.zero : AppMotion.tourMove,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || ref.read(guidedTourProvider) != step) return;
      final targetBox =
          TourKeys.of(GuidedTour.steps[step].target).currentContext?.findRenderObject()
              as RenderBox?;
      final overlayBox = context.findRenderObject() as RenderBox?;
      if (targetBox == null || overlayBox == null || !targetBox.hasSize) return;
      final topLeft = targetBox.localToGlobal(Offset.zero, ancestor: overlayBox);
      setState(() => _hole = (topLeft & targetBox.size).inflate(AppTour.spotlightPadding));
    });
    // Without a scroll there may be no next frame to run the callback above.
    WidgetsBinding.instance.scheduleFrame();
  }

  void _next(int step) {
    final next = GuidedTour.firstShown(step + 1, _isShown);
    final notifier = ref.read(guidedTourProvider.notifier);
    if (next == null) {
      notifier.finish();
    } else {
      notifier.goTo(next);
    }
  }

  void _back(int step) {
    final previous = step == 0 ? null : GuidedTour.lastShown(step - 1, _isShown);
    if (previous != null) ref.read(guidedTourProvider.notifier).goTo(previous);
  }

  @override
  Widget build(BuildContext context) {
    final step = ref.watch(guidedTourProvider);
    if (step == null) {
      _located = null;
      _hole = null;
      return const SizedBox.shrink();
    }
    if (_located != step) {
      _located = step;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _locate(step);
      });
    }
    final animationsOff = MediaQuery.disableAnimationsOf(context);
    final duration = animationsOff ? Duration.zero : AppMotion.tourMove;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) ref.read(guidedTourProvider.notifier).finish();
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          Widget scene(Rect? hole) => Stack(
            fit: StackFit.expand,
            children: [
              // Tapping the dimmed screen goes on; nothing underneath can be pressed.
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _next(step),
                child: ClipPath(
                  clipper: _HoleClipper(hole),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: AppTour.blurSigma, sigmaY: AppTour.blurSigma),
                    child: const ColoredBox(color: AppColors.tourScrim),
                  ),
                ),
              ),
              if (hole != null)
                Positioned.fromRect(
                  rect: hole,
                  // Only the outline glows: a BoxShadow would fill the inside and hide the
                  // feature being shown.
                  child: const IgnorePointer(child: CustomPaint(painter: SpotlightGlowPainter())),
                ),
              _placeCard(
                constraints.biggest,
                hole,
                _TourCard(
                  key: ValueKey(step),
                  step: step,
                  onNext: () => _next(step),
                  onBack: step == 0 ? null : () => _back(step),
                  onSkip: () => ref.read(guidedTourProvider.notifier).finish(),
                ),
              ),
            ],
          );
          final hole = _hole;
          if (hole == null) return scene(null);
          // The spotlight glides from one feature to the next.
          return TweenAnimationBuilder<Rect?>(
            tween: RectTween(end: hole),
            duration: duration,
            curve: Curves.easeOutCubic,
            builder: (context, rect, _) => scene(rect),
          );
        },
      ),
    );
  }

  /// Below the spotlight when it sits in the top half of the screen, above it otherwise.
  Widget _placeCard(Size size, Rect? hole, Widget card) {
    const gap = AppSpacing.md;
    final padding = MediaQuery.paddingOf(context);
    final sized = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: AppTour.cardMaxWidth),
      child: card,
    );
    if (hole == null) return Center(child: sized);
    final below = hole.center.dy <= size.height / 2;
    return Positioned(
      left: gap,
      right: gap,
      top: below ? hole.bottom + gap : padding.top + gap,
      bottom: below ? padding.bottom + gap : size.height - hole.top + gap,
      child: Align(
        alignment: below ? Alignment.topCenter : Alignment.bottomCenter,
        child: SingleChildScrollView(child: sized),
      ),
    );
  }
}

/// The glowing outline of the spotlight: a soft blurred stroke plus a crisp one, nothing inside.
class SpotlightGlowPainter extends CustomPainter {
  const SpotlightGlowPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final outline = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(AppTour.spotlightRadius),
    );
    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = AppTour.glowWidth * 2
      ..color = AppColors.tourGlow
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, AppTour.glowBlur / 2);
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = AppTour.glowWidth
      ..color = AppColors.tourGlow;
    canvas
      ..drawRRect(outline, glow)
      ..drawRRect(outline, edge);
  }

  @override
  bool shouldRepaint(SpotlightGlowPainter oldDelegate) => false;
}

/// Everything except a rounded hole around the feature being shown.
class _HoleClipper extends CustomClipper<Path> {
  const _HoleClipper(this.hole);

  final Rect? hole;

  @override
  Path getClip(Size size) {
    final screen = Path()..addRect(Offset.zero & size);
    if (hole == null) return screen;
    final spot = Path()
      ..addRRect(RRect.fromRectAndRadius(hole!, const Radius.circular(AppTour.spotlightRadius)));
    return Path.combine(PathOperation.difference, screen, spot);
  }

  @override
  bool shouldReclip(_HoleClipper oldClipper) => oldClipper.hole != hole;
}

class _TourCard extends StatelessWidget {
  const _TourCard({
    required this.step,
    required this.onNext,
    required this.onSkip,
    this.onBack,
    super.key,
  });

  final int step;
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tour = GuidedTour.steps[step];
    final isLast = GuidedTour.next(step) == null;
    final animationsOff = MediaQuery.disableAnimationsOf(context);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: animationsOff ? 1 : 0, end: 1),
      duration: animationsOff ? Duration.zero : AppMotion.entrance,
      curve: Curves.easeOutBack,
      builder: (context, value, child) => Opacity(
        opacity: value.clamp(0, 1),
        child: Transform.scale(scale: 0.9 + 0.1 * value, child: child),
      ),
      child: Semantics(
        liveRegion: true,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const MascotView(mood: MascotMood.happy, size: AppTour.mascotSize),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tour.title, style: theme.textTheme.titleMedium),
                          const SizedBox(height: AppSpacing.xs),
                          Text(tour.body, style: theme.textTheme.bodyMedium),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Text(
                      AppStrings.tourProgress(step + 1, GuidedTour.steps.length),
                      style: theme.textTheme.labelLarge,
                    ),
                    const Spacer(),
                    if (!isLast)
                      TextButton(onPressed: onSkip, child: const Text(AppStrings.tourSkip)),
                    if (onBack != null)
                      IconButton(
                        tooltip: AppStrings.tourBack,
                        onPressed: onBack,
                        icon: const Icon(AppIcons.previous),
                      ),
                    FilledButton(
                      onPressed: onNext,
                      child: Text(isLast ? AppStrings.tourDone : AppStrings.tourNext),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
