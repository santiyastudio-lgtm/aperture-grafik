import 'dart:math' as math;

import 'models.dart';

class RevenueRecommendation {
  const RevenueRecommendation({
    required this.referenceMinor,
    required this.lowerMinor,
    required this.upperMinor,
    required this.sampleSize,
    required this.usuallyHigherOnThisWeekday,
    required this.latestWasUnusuallyHigh,
  });

  final int referenceMinor;
  final int lowerMinor;
  final int upperMinor;
  final int sampleSize;
  final bool usuallyHigherOnThisWeekday;
  final bool latestWasUnusuallyHigh;

  bool get hasEnoughData => sampleSize >= 3;
}

/// Transparent on-device recommendation based on completed shifts only.
/// It is a weighted-average rule that runs entirely inside the application.
class RevenueRecommendationService {
  const RevenueRecommendationService();

  RevenueRecommendation? recommend({
    required List<Shift> shifts,
    required DateTime targetDate,
  }) {
    final history =
        shifts
            .where((shift) => shift.revenueMinor > 0)
            .where((shift) => shift.date.isBefore(_day(targetDate)))
            .toList()
          ..sort((left, right) => left.date.compareTo(right.date));
    if (history.isEmpty) return null;

    final recent = history.reversed.take(12).toList().reversed.toList();
    final overall = _weightedAverage(recent);
    final weekday = history
        .where((shift) => shift.date.weekday == targetDate.weekday)
        .toList();
    final weekdayAverage = weekday.isEmpty ? overall : _average(weekday);
    final reference = weekday.length >= 2
        ? (weekdayAverage * .65 + overall * .35).round()
        : overall.round();
    final deviation = _standardDeviation(recent, overall).round();
    final range = math.max(deviation, (reference * .15).round()).toInt();
    final latest = history.last;
    final unusualThreshold = overall + math.max(deviation * 1.5, overall * .25);

    return RevenueRecommendation(
      referenceMinor: reference,
      lowerMinor: math.max(0, reference - range),
      upperMinor: reference + range,
      sampleSize: history.length,
      usuallyHigherOnThisWeekday: reference > overall * 1.2,
      latestWasUnusuallyHigh: latest.revenueMinor > unusualThreshold,
    );
  }

  DateTime _day(DateTime date) => DateTime(date.year, date.month, date.day);

  double _weightedAverage(List<Shift> shifts) {
    var weightedTotal = 0.0;
    var weights = 0;
    for (var index = 0; index < shifts.length; index++) {
      final weight = index + 1;
      weightedTotal += shifts[index].revenueMinor * weight;
      weights += weight;
    }
    return weightedTotal / weights;
  }

  double _average(List<Shift> shifts) =>
      shifts
          .map((shift) => shift.revenueMinor)
          .reduce((a, b) => a + b)
          .toDouble() /
      shifts.length;

  double _standardDeviation(List<Shift> shifts, double mean) {
    if (shifts.length < 2) return 0;
    final variance =
        shifts
            .map((shift) => math.pow(shift.revenueMinor - mean, 2))
            .reduce((a, b) => a + b) /
        shifts.length;
    return math.sqrt(variance.toDouble());
  }
}
