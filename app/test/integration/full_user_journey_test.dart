import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mal4_campaign_approval_app/app.dart';
import 'package:mal4_campaign_approval_app/core/design_system/widgets/persona_switcher_bar.dart';
import 'package:mal4_campaign_approval_app/core/models/mock_persona.dart';
import 'package:mal4_campaign_approval_app/core/providers/persona_provider.dart';
import 'package:mal4_campaign_approval_app/features/campaign_management/presentation/screens/campaign_detail_screen.dart';

void main() {
  group('Full User Journey Integration Tests', () {
    testWidgets('Full End-to-End Persona & Approval Workflow Journey', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: Mal4CampaignApp(),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Marketer Dashboard Verification
      expect(find.byType(PersonaSwitcherBar), findsOneWidget);
      expect(find.text('Campaign Governance'), findsOneWidget);
      expect(find.text('Q4 Global Holiday Omni-Channel Surge'), findsOneWidget);

      // 2. Switch persona to Elena Rostova (Creative Director, Stage 1)
      final elenaPersona = MockPersona.all.firstWhere((p) => p.name == 'Elena Rostova');
      final container = ProviderScope.containerOf(tester.element(find.byType(PersonaSwitcherBar)));
      container.read(currentPersonaProvider.notifier).state = elenaPersona;
      await tester.pumpAndSettle();

      expect(find.textContaining('Elena Rostova'), findsOneWidget);

      // 3. Switch to Review Queue Tab (index 1)
      await tester.tap(find.text('Review Queue'));
      await tester.pumpAndSettle();

      expect(find.text('Pending Approvals'), findsOneWidget);
      expect(find.text('Q4 Global Holiday Omni-Channel Surge'), findsOneWidget);

      // 4. Tap on Campaign to open CampaignDetailScreen
      await tester.tap(find.text('Q4 Global Holiday Omni-Channel Surge'));
      await tester.pumpAndSettle();

      expect(find.byType(CampaignDetailScreen), findsOneWidget);
      expect(find.text('Review Stage 1: Creative & Brand'), findsOneWidget);

      // 5. Open ReviewActionSheet and Approve Stage 1
      await tester.tap(find.text('Review Stage 1: Creative & Brand'));
      await tester.pumpAndSettle();

      expect(find.text('Review Decision Sheet'), findsOneWidget);
      expect(find.text('Confirm Stage 1 Approval'), findsOneWidget);

      await tester.tap(find.text('Confirm Stage 1 Approval'));
      await tester.pumpAndSettle();

      // 6. Verify Campaign is now advanced to Stage 2: Legal & Compliance
      expect(find.text('Active: Stage 2: Legal & Compliance'), findsOneWidget);

      // 7. Pop back to Shell
      await tester.pageBack();
      await tester.pumpAndSettle();

      // 8. Switch to Audit Trail Tab
      await tester.tap(find.text('Audit Trail'));
      await tester.pumpAndSettle();

      expect(find.text('Cryptographic Audit Trail'), findsOneWidget);
      expect(find.text('STAGE_1_APPROVED'), findsWidgets);
    });
  });
}
