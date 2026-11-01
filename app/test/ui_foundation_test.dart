import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mal4_campaign_approval_app/core/models/campaign_state.dart';
import 'package:mal4_campaign_approval_app/core/design_system/widgets/status_badge.dart';
import 'package:mal4_campaign_approval_app/core/design_system/widgets/app_button.dart';
import 'package:mal4_campaign_approval_app/core/design_system/widgets/stage_progress_bar.dart';
import 'package:mal4_campaign_approval_app/core/design_system/widgets/field_diff_tile.dart';
import 'package:mal4_campaign_approval_app/core/design_system/widgets/persona_switcher_bar.dart';
import 'package:mal4_campaign_approval_app/app.dart';

void main() {
  group('Phase 1: UI Foundation & Component Library Tests', () {
    testWidgets('AppShell renders with PersonaSwitcherBar and navigation', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: Mal4CampaignApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify PersonaSwitcherBar is mounted
      expect(find.byType(PersonaSwitcherBar), findsOneWidget);
      expect(find.text('ACTIVE EVALUATION PERSONA'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(PersonaSwitcherBar),
          matching: find.textContaining('Alex Chen'),
        ),
        findsOneWidget,
      );

      // Verify bottom navigation bar destinations
      expect(find.text('Campaigns'), findsOneWidget);
      expect(find.text('Review Queue'), findsOneWidget);
      expect(find.text('Audit Trail'), findsOneWidget);
    });

    testWidgets('StatusBadge renders correct labels and icons for all states', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                StatusBadge(state: CampaignState.draft),
                StatusBadge(state: CampaignState.pendingReview, stageIndex: 1),
                StatusBadge(state: CampaignState.pendingReview, stageIndex: 2),
                StatusBadge(state: CampaignState.pendingReview, stageIndex: 3),
                StatusBadge(state: CampaignState.changesRequested),
                StatusBadge(state: CampaignState.approved),
                StatusBadge(state: CampaignState.scheduled),
                StatusBadge(state: CampaignState.rejected),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Draft'), findsOneWidget);
      expect(find.text('Pending: Creative (S1)'), findsOneWidget);
      expect(find.text('Pending: Compliance (S2)'), findsOneWidget);
      expect(find.text('Pending: Finance (S3)'), findsOneWidget);
      expect(find.text('Changes Requested'), findsOneWidget);
      expect(find.text('Approved'), findsOneWidget);
      expect(find.text('Scheduled'), findsOneWidget);
      expect(find.text('Rejected'), findsOneWidget);
    });

    testWidgets('StageProgressBar displays 3 sequential gates and version tag', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StageProgressBar(
              state: CampaignState.pendingReview,
              currentStage: 2,
              version: 2,
            ),
          ),
        ),
      );

      expect(find.text('APPROVAL PIPELINE'), findsOneWidget);
      expect(find.text('Snapshot v2'), findsOneWidget);
      expect(find.text('Creative'), findsOneWidget);
      expect(find.text('Compliance'), findsOneWidget);
      expect(find.text('Finance'), findsOneWidget);
    });

    testWidgets('FieldDiffTile renders old value, new value, and materiality badge', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FieldDiffTile(
              fieldName: 'Budget Amount',
              oldValue: '\$15,000 USD',
              newValue: '\$12,500 USD',
              isMaterial: true,
              rationale: 'Budget reduced by 15% per finance request.',
            ),
          ),
        ),
      );

      expect(find.text('BUDGET AMOUNT'), findsOneWidget);
      expect(find.text('MATERIAL'), findsOneWidget);
      expect(find.text('\$15,000 USD'), findsOneWidget);
      expect(find.text('\$12,500 USD'), findsOneWidget);
    });

    testWidgets('AppButton enforces minimum touch target height', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppButton(
              label: 'Approve Stage 1',
              onPressed: () {},
            ),
          ),
        ),
      );

      final buttonFinder = find.byType(ElevatedButton);
      expect(buttonFinder, findsOneWidget);
      final size = tester.getSize(buttonFinder);
      expect(size.height, greaterThanOrEqualTo(48.0));
    });
  });
}

