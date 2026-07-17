import 'package:aperture_grafik/domain/finance_service.dart';
import 'package:aperture_grafik/domain/models.dart';
import 'package:aperture_grafik/domain/revenue_recommendation_service.dart';
import 'package:aperture_grafik/domain/schedule_service.dart';
import 'package:aperture_grafik/core/notifications/notification_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

void main() {
  group('ScheduleService', () {
    const service = ScheduleService();
    final schedule = Schedule(
      type: ScheduleType.twoTwo,
      anchorDate: DateTime(2026, 7, 1),
      weekdays: const {},
      start: const WorkTime(21, 0),
      end: const WorkTime(5, 0),
    );

    test('builds a 2/2 pattern and supports an overnight shift', () {
      expect(service.isWorkDay(schedule, DateTime(2026, 7, 1)), isTrue);
      expect(service.isWorkDay(schedule, DateTime(2026, 7, 2)), isTrue);
      expect(service.isWorkDay(schedule, DateTime(2026, 7, 3)), isFalse);
      expect(
        service.endAt(schedule, DateTime(2026, 7, 1)),
        DateTime(2026, 7, 2, 5),
      );
    });
  });

  test('earnings include fixed rate and revenue percentage in minor units', () {
    const service = FinanceService();
    const payment = PaymentSettings(
      dailyRateMinor: 300000,
      revenuePercent: 5,
      advanceDay: 15,
      salaryDay: 30,
    );
    expect(service.earnings(revenueMinor: 5000000, payment: payment), 550000);
  });

  test(
    'Russian and English date symbols are available before rendering',
    () async {
      await initializeDateFormatting();

      expect(
        DateFormat.yMMMMEEEEd('ru_RU').format(DateTime(2026, 7, 17)),
        isNotEmpty,
      );
      expect(
        DateFormat.yMMMMEEEEd('en_US').format(DateTime(2026, 7, 17)),
        isNotEmpty,
      );
    },
  );

  test('reminders resume on the next half-hour after a completed shift', () {
    expect(
      NotificationService.nextHalfHourAfter(DateTime(2026, 7, 17, 21, 6)),
      DateTime(2026, 7, 17, 21, 30),
    );
    expect(
      NotificationService.nextHalfHourAfter(DateTime(2026, 7, 17, 21, 42)),
      DateTime(2026, 7, 17, 22),
    );
  });

  test('recommendation uses history and flags a higher weekday pattern', () {
    final shifts = [
      _shift(DateTime(2026, 7, 3), 2000000),
      _shift(DateTime(2026, 7, 6), 1000000),
      _shift(DateTime(2026, 7, 10), 2200000),
      _shift(DateTime(2026, 7, 13), 1100000),
      _shift(DateTime(2026, 7, 17), 2400000),
      _shift(DateTime(2026, 7, 20), 1100000),
    ];
    final recommendation = const RevenueRecommendationService().recommend(
      shifts: shifts,
      targetDate: DateTime(2026, 7, 24),
    );

    expect(recommendation, isNotNull);
    expect(recommendation!.hasEnoughData, isTrue);
    expect(recommendation.referenceMinor, greaterThan(1800000));
    expect(recommendation.usuallyHigherOnThisWeekday, isTrue);
  });
}

Shift _shift(DateTime date, int revenueMinor) => Shift(
  id: date.toIso8601String(),
  date: date,
  kind: ShiftKind.scheduled,
  actualStart: date.add(const Duration(hours: 9)),
  actualEnd: date.add(const Duration(hours: 21)),
  colleagueIds: const [],
  revenueMinor: revenueMinor,
  earningsMinor: 0,
  comment: '',
  createdAt: date,
  updatedAt: date,
);
