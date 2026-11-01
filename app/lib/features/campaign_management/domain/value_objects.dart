import 'package:intl/intl.dart';

class BudgetAllocation {
  final double amount;
  final String currency;
  final String costCenter;
  final int doaTier; // 1: <= $10k (Manager), 2: <= $50k (Director), 3: > $50k (VP/C-Level)

  const BudgetAllocation({
    required this.amount,
    this.currency = 'USD',
    required this.costCenter,
    required this.doaTier,
  });

  static int calculateDoaTier(double amount) {
    if (amount <= 10000.0) return 1;
    if (amount <= 50000.0) return 2;
    return 3;
  }

  String get doaTierLabel {
    switch (doaTier) {
      case 1:
        return 'Tier 1 (Marketing Lead - Up to \$10k)';
      case 2:
        return 'Tier 2 (Director - Up to \$50k)';
      case 3:
      default:
        return 'Tier 3 (VP / Executive - Over \$50k)';
    }
  }

  String get formattedAmount {
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    return '${formatter.format(amount)} $currency';
  }

  bool isMaterialDelta(BudgetAllocation other) {
    if (currency != other.currency || costCenter != other.costCenter) return true;
    if (doaTier != other.doaTier) return true;
    final percentageDelta = (amount - other.amount).abs() / amount;
    return percentageDelta >= 0.10; // 10% threshold
  }
}

class AudienceCriteria {
  final String segmentName;
  final List<String> targetRegions;
  final List<String> channels;
  final int estimatedReach;

  const AudienceCriteria({
    required this.segmentName,
    required this.targetRegions,
    required this.channels,
    required this.estimatedReach,
  });

  String get formattedReach {
    final formatter = NumberFormat.compact();
    return formatter.format(estimatedReach);
  }

  bool isMaterialDelta(AudienceCriteria other) {
    if (segmentName != other.segmentName) return true;
    if (targetRegions.length != other.targetRegions.length) return true;
    for (final region in targetRegions) {
      if (!other.targetRegions.contains(region)) return true;
    }
    final variance = (estimatedReach - other.estimatedReach).abs() / estimatedReach;
    return variance > 0.15; // 15% reach variance
  }
}

class ScheduleWindow {
  final DateTime startDate;
  final DateTime endDate;

  const ScheduleWindow({
    required this.startDate,
    required this.endDate,
  });

  String get formattedRange {
    final formatter = DateFormat('MMM dd, yyyy');
    return '${formatter.format(startDate)} – ${formatter.format(endDate)}';
  }

  int get durationDays => endDate.difference(startDate).inDays;

  bool isMaterialShift(ScheduleWindow other) {
    final startShift = startDate.difference(other.startDate).inHours.abs();
    final endShift = endDate.difference(other.endDate).inHours.abs();
    return startShift > 72 || endShift > 72; // 72 hours
  }
}

