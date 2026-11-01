import 'dart:convert';
import 'package:crypto/crypto.dart';

class HashUtil {
  /// Computes a canonical SHA-256 digest over the campaign snapshot attributes.
  static String computeSnapshotHash({
    required String campaignId,
    required int version,
    required String name,
    required String objective,
    required double budgetAmount,
    required String costCenter,
    required String segmentName,
    required List<String> channels,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final sortedChannels = List<String>.from(channels)..sort();
    final canonicalString = [
      'id:$campaignId',
      'ver:$version',
      'name:${name.trim()}',
      'obj:${objective.trim()}',
      'budget:${budgetAmount.toStringAsFixed(2)}',
      'cc:${costCenter.trim()}',
      'seg:${segmentName.trim()}',
      'channels:${sortedChannels.join(",")}',
      'start:${startDate.toIso8601String()}',
      'end:${endDate.toIso8601String()}',
    ].join('|');

    return sha256.convert(utf8.encode(canonicalString)).toString();
  }
}

