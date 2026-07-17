import 'dart:convert';

enum AppLanguage { russian, english }

enum Currency { rub }

enum AppThemeMode { standard, laboratory, aperture, chamber }

enum ScheduleType { threeThree, twoTwo, fiveTwo, weekdays }

enum ShiftKind { scheduled, extra }

class WorkTime {
  const WorkTime(this.hour, this.minute);

  final int hour;
  final int minute;

  int get minutesSinceMidnight => hour * 60 + minute;

  String format() =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  Map<String, dynamic> toJson() => {'hour': hour, 'minute': minute};

  factory WorkTime.fromJson(Map<String, dynamic> json) => WorkTime(
    (json['hour'] as num?)?.toInt() ?? 9,
    (json['minute'] as num?)?.toInt() ?? 0,
  );
}

class AppSettings {
  const AppSettings({
    required this.language,
    required this.currency,
    required this.themeMode,
    required this.onboardingComplete,
    required this.notificationsEnabled,
  });

  final AppLanguage language;
  final Currency currency;
  final AppThemeMode themeMode;
  final bool onboardingComplete;
  final bool notificationsEnabled;

  AppSettings copyWith({
    AppLanguage? language,
    Currency? currency,
    AppThemeMode? themeMode,
    bool? onboardingComplete,
    bool? notificationsEnabled,
  }) => AppSettings(
    language: language ?? this.language,
    currency: currency ?? this.currency,
    themeMode: themeMode ?? this.themeMode,
    onboardingComplete: onboardingComplete ?? this.onboardingComplete,
    notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
  );

  Map<String, dynamic> toJson() => {
    'language': language.name,
    'currency': currency.name,
    'themeMode': themeMode.name,
    'onboardingComplete': onboardingComplete,
    'notificationsEnabled': notificationsEnabled,
  };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
    language: AppLanguage.values.byName(
      json['language'] as String? ?? 'russian',
    ),
    // Backups created before RUB-only mode may contain "usd". Keep them
    // readable while normalising all monetary values to the supported currency.
    currency: Currency.rub,
    themeMode: AppThemeMode.values.byName(
      json['themeMode'] as String? ?? 'standard',
    ),
    onboardingComplete: json['onboardingComplete'] as bool? ?? false,
    notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
  );
}

class Schedule {
  const Schedule({
    required this.type,
    required this.anchorDate,
    required this.weekdays,
    required this.start,
    required this.end,
  });

  final ScheduleType type;
  final DateTime anchorDate;
  final Set<int> weekdays;
  final WorkTime start;
  final WorkTime end;

  Schedule copyWith({
    ScheduleType? type,
    DateTime? anchorDate,
    Set<int>? weekdays,
    WorkTime? start,
    WorkTime? end,
  }) => Schedule(
    type: type ?? this.type,
    anchorDate: anchorDate ?? this.anchorDate,
    weekdays: weekdays ?? this.weekdays,
    start: start ?? this.start,
    end: end ?? this.end,
  );

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'anchorDate': anchorDate.toIso8601String(),
    'weekdays': weekdays.toList(),
    'start': start.toJson(),
    'end': end.toJson(),
  };

  factory Schedule.fromJson(Map<String, dynamic> json) => Schedule(
    type: ScheduleType.values.byName(json['type'] as String? ?? 'twoTwo'),
    anchorDate:
        DateTime.tryParse(json['anchorDate'] as String? ?? '') ??
        DateTime.now(),
    weekdays: ((json['weekdays'] as List<dynamic>?) ?? const <dynamic>[])
        .map((value) => (value as num).toInt())
        .toSet(),
    start: WorkTime.fromJson(
      Map<String, dynamic>.from(json['start'] as Map? ?? const {}),
    ),
    end: WorkTime.fromJson(
      Map<String, dynamic>.from(json['end'] as Map? ?? const {}),
    ),
  );
}

class PaymentSettings {
  const PaymentSettings({
    required this.dailyRateMinor,
    required this.revenuePercent,
    required this.advanceDay,
    required this.salaryDay,
  });

  final int dailyRateMinor;
  final double revenuePercent;
  final int advanceDay;
  final int salaryDay;

  PaymentSettings copyWith({
    int? dailyRateMinor,
    double? revenuePercent,
    int? advanceDay,
    int? salaryDay,
  }) => PaymentSettings(
    dailyRateMinor: dailyRateMinor ?? this.dailyRateMinor,
    revenuePercent: revenuePercent ?? this.revenuePercent,
    advanceDay: advanceDay ?? this.advanceDay,
    salaryDay: salaryDay ?? this.salaryDay,
  );

  Map<String, dynamic> toJson() => {
    'dailyRateMinor': dailyRateMinor,
    'revenuePercent': revenuePercent,
    'advanceDay': advanceDay,
    'salaryDay': salaryDay,
  };

  factory PaymentSettings.fromJson(Map<String, dynamic> json) =>
      PaymentSettings(
        dailyRateMinor: (json['dailyRateMinor'] as num?)?.toInt() ?? 300000,
        revenuePercent: (json['revenuePercent'] as num?)?.toDouble() ?? 5,
        advanceDay: (json['advanceDay'] as num?)?.toInt() ?? 15,
        salaryDay: (json['salaryDay'] as num?)?.toInt() ?? 30,
      );
}

class Colleague {
  const Colleague({
    required this.id,
    required this.name,
    required this.colorValue,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final int colorValue;
  final DateTime createdAt;
  final DateTime updatedAt;

  Colleague copyWith({String? name, int? colorValue, DateTime? updatedAt}) =>
      Colleague(
        id: id,
        name: name ?? this.name,
        colorValue: colorValue ?? this.colorValue,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'colorValue': colorValue,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory Colleague.fromJson(Map<String, dynamic> json) => Colleague(
    id: json['id'] as String,
    name: json['name'] as String,
    colorValue: (json['colorValue'] as num?)?.toInt() ?? 0xFF2F80ED,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );
}

class Shift {
  const Shift({
    required this.id,
    required this.date,
    required this.kind,
    required this.actualStart,
    required this.actualEnd,
    required this.colleagueIds,
    required this.revenueMinor,
    required this.earningsMinor,
    required this.comment,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final DateTime date;
  final ShiftKind kind;
  final DateTime actualStart;
  final DateTime actualEnd;
  final List<String> colleagueIds;
  final int revenueMinor;
  final int earningsMinor;
  final String comment;
  final DateTime createdAt;
  final DateTime updatedAt;

  Shift copyWith({
    DateTime? date,
    ShiftKind? kind,
    DateTime? actualStart,
    DateTime? actualEnd,
    List<String>? colleagueIds,
    int? revenueMinor,
    int? earningsMinor,
    String? comment,
    DateTime? updatedAt,
  }) => Shift(
    id: id,
    date: date ?? this.date,
    kind: kind ?? this.kind,
    actualStart: actualStart ?? this.actualStart,
    actualEnd: actualEnd ?? this.actualEnd,
    colleagueIds: colleagueIds ?? this.colleagueIds,
    revenueMinor: revenueMinor ?? this.revenueMinor,
    earningsMinor: earningsMinor ?? this.earningsMinor,
    comment: comment ?? this.comment,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'kind': kind.name,
    'actualStart': actualStart.toIso8601String(),
    'actualEnd': actualEnd.toIso8601String(),
    'colleagueIds': colleagueIds,
    'revenueMinor': revenueMinor,
    'earningsMinor': earningsMinor,
    'comment': comment,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory Shift.fromJson(Map<String, dynamic> json) => Shift(
    id: json['id'] as String,
    date: DateTime.parse(json['date'] as String),
    kind: ShiftKind.values.byName(json['kind'] as String? ?? 'scheduled'),
    actualStart: DateTime.parse(json['actualStart'] as String),
    actualEnd: DateTime.parse(json['actualEnd'] as String),
    colleagueIds: List<String>.from(
      json['colleagueIds'] as List<dynamic>? ?? const [],
    ),
    revenueMinor: (json['revenueMinor'] as num?)?.toInt() ?? 0,
    earningsMinor: (json['earningsMinor'] as num?)?.toInt() ?? 0,
    comment: json['comment'] as String? ?? '',
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );
}

class AppState {
  const AppState({
    required this.settings,
    required this.schedule,
    required this.payment,
    required this.colleagues,
    required this.shifts,
  });

  final AppSettings settings;
  final Schedule schedule;
  final PaymentSettings payment;
  final List<Colleague> colleagues;
  final List<Shift> shifts;

  factory AppState.initial() {
    final now = DateTime.now();
    return AppState(
      settings: const AppSettings(
        language: AppLanguage.russian,
        currency: Currency.rub,
        themeMode: AppThemeMode.standard,
        onboardingComplete: false,
        notificationsEnabled: true,
      ),
      schedule: Schedule(
        type: ScheduleType.twoTwo,
        anchorDate: DateTime(now.year, now.month, now.day),
        weekdays: const {
          DateTime.monday,
          DateTime.tuesday,
          DateTime.wednesday,
          DateTime.thursday,
          DateTime.friday,
        },
        start: const WorkTime(9, 0),
        end: const WorkTime(21, 0),
      ),
      payment: const PaymentSettings(
        dailyRateMinor: 300000,
        revenuePercent: 5,
        advanceDay: 15,
        salaryDay: 30,
      ),
      colleagues: const [],
      shifts: const [],
    );
  }

  AppState copyWith({
    AppSettings? settings,
    Schedule? schedule,
    PaymentSettings? payment,
    List<Colleague>? colleagues,
    List<Shift>? shifts,
  }) => AppState(
    settings: settings ?? this.settings,
    schedule: schedule ?? this.schedule,
    payment: payment ?? this.payment,
    colleagues: colleagues ?? this.colleagues,
    shifts: shifts ?? this.shifts,
  );

  Map<String, dynamic> toJson() => {
    'schemaVersion': 1,
    'settings': settings.toJson(),
    'schedule': schedule.toJson(),
    'payment': payment.toJson(),
    'colleagues': colleagues.map((item) => item.toJson()).toList(),
    'shifts': shifts.map((item) => item.toJson()).toList(),
  };

  String toBackupJson() => const JsonEncoder.withIndent('  ').convert(toJson());

  factory AppState.fromJson(Map<String, dynamic> json) {
    if (json['schemaVersion'] != 1) {
      throw const FormatException('Unsupported backup version.');
    }
    return AppState(
      settings: AppSettings.fromJson(
        Map<String, dynamic>.from(json['settings'] as Map),
      ),
      schedule: Schedule.fromJson(
        Map<String, dynamic>.from(json['schedule'] as Map),
      ),
      payment: PaymentSettings.fromJson(
        Map<String, dynamic>.from(json['payment'] as Map),
      ),
      colleagues: (json['colleagues'] as List<dynamic>? ?? const [])
          .map(
            (item) =>
                Colleague.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
      shifts: (json['shifts'] as List<dynamic>? ?? const [])
          .map((item) => Shift.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(),
    );
  }
}
