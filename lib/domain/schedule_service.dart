import 'models.dart';

class ScheduleService {
  const ScheduleService();

  DateTime day(DateTime value) => DateTime(value.year, value.month, value.day);

  bool isWorkDay(Schedule schedule, DateTime date) {
    final target = day(date);
    final anchor = day(schedule.anchorDate);
    if (target.isBefore(anchor)) return false;
    if (schedule.type == ScheduleType.weekdays) {
      return schedule.weekdays.contains(target.weekday);
    }
    final days = target.difference(anchor).inDays;
    final (work, rest) = switch (schedule.type) {
      ScheduleType.threeThree => (3, 3),
      ScheduleType.twoTwo => (2, 2),
      ScheduleType.fiveTwo => (5, 2),
      ScheduleType.weekdays => throw StateError('Handled above'),
    };
    return days % (work + rest) < work;
  }

  DateTime startAt(Schedule schedule, DateTime date) => DateTime(
    date.year,
    date.month,
    date.day,
    schedule.start.hour,
    schedule.start.minute,
  );

  DateTime endAt(Schedule schedule, DateTime date) {
    final end = DateTime(
      date.year,
      date.month,
      date.day,
      schedule.end.hour,
      schedule.end.minute,
    );
    return schedule.end.minutesSinceMidnight <=
            schedule.start.minutesSinceMidnight
        ? end.add(const Duration(days: 1))
        : end;
  }

  DateTime? nextWorkDay(Schedule schedule, DateTime from) {
    for (var offset = 0; offset < 370; offset++) {
      final candidate = day(from).add(Duration(days: offset));
      if (isWorkDay(schedule, candidate)) return candidate;
    }
    return null;
  }
}
