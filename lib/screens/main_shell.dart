// 5.1 Khung chính.
// Bottom bar with three tabs: Hôm nay / Thói quen / Tiến độ (ADR-0002). While a session runs, the
// running-session banner sits just above the bar (spec 001 FR-008). The level-up dialog is parked
// (ADR-0004).
// 5.7 The guided tour (spec 022) is drawn over the whole shell, tab bar included.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../data/guided_tour.dart';
import '../l10n/app_strings.dart';
import '../providers/tour_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/running_session_banner.dart';
import '../widgets/tour/guided_tour_overlay.dart';
import '../widgets/tour/tour_keys.dart';

class MainShell extends ConsumerWidget {
  const MainShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    // A waiting tour starts once Hôm nay is on screen (spec 022 FR-001).
    if (navigationShell.currentIndex == 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) ref.read(guidedTourProvider.notifier).startIfPending();
      });
    }

    // 5.1 (spec 010): the tab bar floats over the content, inset from the edges with rounded
    // corners; the body runs behind it and screens pad their last controls by
    // MediaQuery.paddingOf(context).bottom.
    final shell = Scaffold(
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(borderRadius: AppRadius.cardBorder, child: const RunningSessionBanner()),
              const SizedBox(height: AppSpacing.xs),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainer,
                  borderRadius: AppRadius.pillBorder,
                  border: Border.all(color: theme.colorScheme.outline),
                ),
                child: ClipRRect(
                  borderRadius: AppRadius.pillBorder,
                  child: NavigationBar(
                    height: AppShell.tabBarHeight,
                    backgroundColor: AppColors.transparent,
                    elevation: 0,
                    selectedIndex: navigationShell.currentIndex,
                    onDestinationSelected: (index) => navigationShell.goBranch(
                      index,
                      // Bấm lại tab đang mở thì quay về đầu tab đó.
                      initialLocation: index == navigationShell.currentIndex,
                    ),
                    destinations: [
                      const NavigationDestination(
                        icon: Icon(AppIcons.home),
                        label: AppStrings.tabToday,
                      ),
                      TourKeys.mark(
                        TourTarget.habitsTab,
                        const NavigationDestination(
                          icon: Icon(AppIcons.habits),
                          label: AppStrings.tabHabits,
                        ),
                      ),
                      TourKeys.mark(
                        TourTarget.progressTab,
                        const NavigationDestination(
                          icon: Icon(AppIcons.stats),
                          label: AppStrings.tabProgress,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return Stack(
      fit: StackFit.expand,
      children: [
        shell,
        const Positioned.fill(child: GuidedTourOverlay()),
      ],
    );
  }
}
