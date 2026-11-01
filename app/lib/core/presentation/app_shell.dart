import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../design_system/colors.dart';
import '../design_system/widgets/persona_switcher_bar.dart';

final appShellTabProvider = StateProvider<int>((ref) => 0);

class AppShell extends ConsumerWidget {
  final List<Widget> tabs;

  const AppShell({
    super.key,
    required this.tabs,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTab = ref.watch(appShellTabProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const PersonaSwitcherBar(),
            Expanded(
              child: IndexedStack(
                index: activeTab,
                children: tabs,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 1.0,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: activeTab,
          onDestinationSelected: (index) {
            ref.read(appShellTabProvider.notifier).state = index;
          },
          backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          indicatorColor: AppColors.defenseGreen.withValues(alpha: 0.15),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.campaign_outlined),
              selectedIcon: Icon(Icons.campaign_rounded, color: AppColors.defenseGreen),
              label: 'Campaigns',
            ),
            NavigationDestination(
              icon: Icon(Icons.fact_check_outlined),
              selectedIcon: Icon(Icons.fact_check_rounded, color: AppColors.defenseGreen),
              label: 'Review Queue',
            ),
            NavigationDestination(
              icon: Icon(Icons.history_edu_outlined),
              selectedIcon: Icon(Icons.history_edu_rounded, color: AppColors.defenseGreen),
              label: 'Audit Trail',
            ),
          ],
        ),
      ),
    );
  }
}

