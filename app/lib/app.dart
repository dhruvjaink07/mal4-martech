import 'package:flutter/material.dart';
import 'core/design_system/theme.dart';
import 'core/presentation/app_shell.dart';
import 'features/campaign_management/presentation/screens/campaign_dashboard_screen.dart';
import 'features/multi_stage_review/presentation/screens/review_queue_screen.dart';
import 'features/audit_and_governance/presentation/screens/audit_timeline_screen.dart';

class Mal4CampaignApp extends StatelessWidget {
  final Widget? homeOverride;

  const Mal4CampaignApp({super.key, this.homeOverride});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MAL4 MarTech Campaign Review & Approval',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark, // Default to Dark Architectural SaaS theme
      home: homeOverride ?? const _DefaultAppEntry(),
    );
  }
}

class _DefaultAppEntry extends StatelessWidget {
  const _DefaultAppEntry();

  @override
  Widget build(BuildContext context) {
    return const AppShell(
      tabs: [
        CampaignDashboardScreen(),
        ReviewQueueScreen(),
        AuditTimelineScreen(),
      ],
    );
  }
}
