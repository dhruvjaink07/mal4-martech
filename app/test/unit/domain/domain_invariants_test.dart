import 'package:flutter_test/flutter_test.dart';
import 'package:mal4_campaign_approval_app/core/utils/hash_util.dart';
import 'package:mal4_campaign_approval_app/features/campaign_management/domain/value_objects.dart';

void main() {
  group('Domain Invariants: BudgetAllocation & DOA Tiers', () {
    test('Calculates correct DOA Tiers based on threshold limits', () {
      expect(BudgetAllocation.calculateDoaTier(5000), equals(1));
      expect(BudgetAllocation.calculateDoaTier(10000), equals(1));
      expect(BudgetAllocation.calculateDoaTier(10001), equals(2));
      expect(BudgetAllocation.calculateDoaTier(50000), equals(2));
      expect(BudgetAllocation.calculateDoaTier(50001), equals(3));
      expect(BudgetAllocation.calculateDoaTier(150000), equals(3));
    });

    test('Materiality: Delta < 10% is non-material; Delta >= 10% is material', () {
      final initial = BudgetAllocation(
        amount: 20000,
        costCenter: 'CC-MKTG-GLOBAL',
        doaTier: BudgetAllocation.calculateDoaTier(20000),
      );

      // +5% change ($21,000)
      final minorChange = BudgetAllocation(
        amount: 21000,
        costCenter: 'CC-MKTG-GLOBAL',
        doaTier: BudgetAllocation.calculateDoaTier(21000),
      );
      expect(initial.isMaterialDelta(minorChange), isFalse);

      // +15% change ($23,000)
      final materialChange = BudgetAllocation(
        amount: 23000,
        costCenter: 'CC-MKTG-GLOBAL',
        doaTier: BudgetAllocation.calculateDoaTier(23000),
      );
      expect(initial.isMaterialDelta(materialChange), isTrue);

      // Cost center change is always material
      final costCenterChange = BudgetAllocation(
        amount: 20000,
        costCenter: 'CC-RETENTION',
        doaTier: BudgetAllocation.calculateDoaTier(20000),
      );
      expect(initial.isMaterialDelta(costCenterChange), isTrue);
    });
  });

  group('Domain Invariants: AudienceCriteria Reach Variance', () {
    test('Reach variance <= 15% is non-material; > 15% is material', () {
      const initial = AudienceCriteria(
        segmentName: 'Global Shoppers',
        targetRegions: ['NA', 'EU'],
        channels: ['Meta', 'Google'],
        estimatedReach: 100000,
      );

      // +10% reach (110k)
      const minor = AudienceCriteria(
        segmentName: 'Global Shoppers',
        targetRegions: ['NA', 'EU'],
        channels: ['Meta', 'Google'],
        estimatedReach: 110000,
      );
      expect(initial.isMaterialDelta(minor), isFalse);

      // +25% reach (125k)
      const material = AudienceCriteria(
        segmentName: 'Global Shoppers',
        targetRegions: ['NA', 'EU'],
        channels: ['Meta', 'Google'],
        estimatedReach: 125000,
      );
      expect(initial.isMaterialDelta(material), isTrue);
    });
  });

  group('Domain Invariants: ScheduleWindow Date Shifts', () {
    test('Flight shifts <= 72h are non-material; > 72h are material', () {
      final now = DateTime.now();
      final initial = ScheduleWindow(
        startDate: now,
        endDate: now.add(const Duration(days: 30)),
      );

      // 24 hour shift
      final minorShift = ScheduleWindow(
        startDate: now.add(const Duration(hours: 24)),
        endDate: now.add(const Duration(days: 30, hours: 24)),
      );
      expect(initial.isMaterialShift(minorShift), isFalse);

      // 96 hour shift (4 days)
      final materialShift = ScheduleWindow(
        startDate: now.add(const Duration(hours: 96)),
        endDate: now.add(const Duration(days: 30)),
      );
      expect(initial.isMaterialShift(materialShift), isTrue);
    });
  });

  group('Domain Invariants: HashUtil SHA-256 Digest', () {
    test('Computes deterministic canonical snapshot hash', () {
      final now = DateTime(2026, 11, 1, 12, 0, 0);
      final hash1 = HashUtil.computeSnapshotHash(
        campaignId: 'cmp_test',
        version: 1,
        name: 'Test Campaign',
        objective: 'Test Objective',
        budgetAmount: 50000,
        costCenter: 'CC-TEST',
        segmentName: 'Segment A',
        channels: ['Google', 'Meta'],
        startDate: now,
        endDate: now.add(const Duration(days: 30)),
      );

      final hash2 = HashUtil.computeSnapshotHash(
        campaignId: 'cmp_test',
        version: 1,
        name: 'Test Campaign',
        objective: 'Test Objective',
        budgetAmount: 50000,
        costCenter: 'CC-TEST',
        segmentName: 'Segment A',
        channels: ['Meta', 'Google'], // different array order, sorted canonically
        startDate: now,
        endDate: now.add(const Duration(days: 30)),
      );

      expect(hash1, equals(hash2));
      expect(hash1.length, equals(64)); // SHA-256 hex string length
    });
  });
}

