import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../domain/models.dart';
import '../../domain/schedule_service.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();
  static const _endNotificationId = 1000;
  static const _firstRepeatNotificationId = 1001;
  static const _repeatReminderCount = 96;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final ScheduleService _schedule = const ScheduleService();

  Future<void> initialize() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Europe/Moscow'));
    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.requestNotificationsPermission();
  }

  /// Schedules the end notification and 30-minute reminders for the next two
  /// days. Saving a shift updates [AppState], which cancels the batch; opening
  /// the app with an unfinished shift refreshes the two-day reminder window.
  Future<void> scheduleNextEndReminder(AppState state) async {
    await _cancelShiftReminders();
    if (!state.settings.notificationsEnabled) return;

    final now = DateTime.now();
    final target = _nextIncompleteShiftEnd(state, now);
    if (target == null) return;

    final isRussian = state.settings.language == AppLanguage.russian;
    if (target.isAfter(now)) {
      await _plugin.zonedSchedule(
        _endNotificationId,
        isRussian ? 'Смена закончилась' : 'Shift has ended',
        isRussian
            ? 'Заполните коллег, выручку и комментарий за смену.'
            : 'Add colleagues, revenue, and an optional comment.',
        tz.TZDateTime.from(target, tz.local),
        _notificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }

    final firstReminder = target.isAfter(now)
        ? target.add(const Duration(minutes: 30))
        : nextHalfHourAfter(now);
    for (var index = 0; index < _repeatReminderCount; index++) {
      await _plugin.zonedSchedule(
        _firstRepeatNotificationId + index,
        isRussian ? 'Заполните данные о смене' : 'Complete shift details',
        isRussian
            ? 'Напоминание: укажите коллег и выручку за завершённую смену.'
            : 'Reminder: add colleagues and revenue for the finished shift.',
        tz.TZDateTime.from(
          firstReminder.add(Duration(minutes: 30 * index)),
          tz.local,
        ),
        _notificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  Future<void> _cancelShiftReminders() async {
    for (
      var id = _endNotificationId;
      id < _firstRepeatNotificationId + _repeatReminderCount;
      id++
    ) {
      await _plugin.cancel(id);
    }
  }

  DateTime? _nextIncompleteShiftEnd(AppState state, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    for (final day in <DateTime>[
      today,
      today.subtract(const Duration(days: 1)),
    ]) {
      if (_schedule.isWorkDay(state.schedule, day) &&
          !_hasCompletedShift(state, day)) {
        final end = _schedule.endAt(state.schedule, day);
        if (!end.isAfter(now)) return end;
      }
    }

    for (var offset = 0; offset < 370; offset++) {
      final day = today.add(Duration(days: offset));
      if (_schedule.isWorkDay(state.schedule, day) &&
          !_hasCompletedShift(state, day)) {
        return _schedule.endAt(state.schedule, day);
      }
    }
    return null;
  }

  bool _hasCompletedShift(AppState state, DateTime day) => state.shifts.any(
    (shift) =>
        shift.date.year == day.year &&
        shift.date.month == day.month &&
        shift.date.day == day.day,
  );

  static DateTime nextHalfHourAfter(DateTime value) {
    final minute = value.minute < 30 ? 30 : 60;
    return DateTime(value.year, value.month, value.day, value.hour, minute);
  }

  static const _notificationDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'shift_end',
      'Shift end reminders',
      channelDescription: 'Reminders to complete a finished shift',
      importance: Importance.high,
      priority: Priority.high,
    ),
  );
}
