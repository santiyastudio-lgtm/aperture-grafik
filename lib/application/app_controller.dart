import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:uuid/uuid.dart';

import '../data/app_repository.dart';
import '../data/sqlite_app_repository.dart';
import '../domain/finance_service.dart';
import '../domain/models.dart';

final appRepositoryProvider = Provider<AppRepository>(
  (ref) => SqliteAppRepository(),
);

final appControllerProvider =
    StateNotifierProvider<AppController, AsyncValue<AppState>>(
      (ref) => AppController(ref.read(appRepositoryProvider)),
    );

class AppController extends StateNotifier<AsyncValue<AppState>> {
  AppController(this._repository) : super(const AsyncValue.loading()) {
    initialize();
  }

  final AppRepository _repository;
  final _uuid = const Uuid();
  final _finance = const FinanceService();

  Future<void> initialize() async {
    try {
      state = AsyncValue.data(await _repository.load());
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  AppState get _data => state.requireValue;

  Future<void> _save(AppState value) async {
    state = AsyncValue.data(value);
    try {
      await _repository.save(value);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> completeOnboarding({
    required AppLanguage language,
    required Schedule schedule,
    required PaymentSettings payment,
    required List<String> colleagueNames,
  }) async {
    final now = DateTime.now();
    final colors = <int>[
      0xFF2F80ED,
      0xFF9B51E0,
      0xFFF2994A,
      0xFF27AE60,
      0xFFEB5757,
    ];
    final colleagues = colleagueNames
        .where((name) => name.trim().isNotEmpty)
        .toList()
        .asMap()
        .entries
        .map((entry) {
          return Colleague(
            id: _uuid.v4(),
            name: entry.value.trim(),
            colorValue: colors[entry.key % colors.length],
            createdAt: now,
            updatedAt: now,
          );
        })
        .toList();
    await _save(
      _data.copyWith(
        settings: _data.settings.copyWith(
          language: language,
          onboardingComplete: true,
        ),
        schedule: schedule,
        payment: payment,
        colleagues: colleagues,
      ),
    );
  }

  Future<void> updateSettings(AppSettings settings) =>
      _save(_data.copyWith(settings: settings));

  Future<void> updateSchedule(Schedule schedule) =>
      _save(_data.copyWith(schedule: schedule));

  Future<void> updatePayment(PaymentSettings payment) =>
      _save(_data.copyWith(payment: payment));

  Future<void> addColleague(String name) async {
    if (name.trim().isEmpty) return;
    final now = DateTime.now();
    const colors = <int>[
      0xFF2F80ED,
      0xFF9B51E0,
      0xFFF2994A,
      0xFF27AE60,
      0xFFEB5757,
    ];
    final colleague = Colleague(
      id: _uuid.v4(),
      name: name.trim(),
      colorValue: colors[_data.colleagues.length % colors.length],
      createdAt: now,
      updatedAt: now,
    );
    await _save(_data.copyWith(colleagues: [..._data.colleagues, colleague]));
  }

  Future<void> deleteColleague(String id) async {
    await _save(
      _data.copyWith(
        colleagues: _data.colleagues.where((item) => item.id != id).toList(),
        shifts: _data.shifts
            .map(
              (shift) => shift.copyWith(
                colleagueIds: shift.colleagueIds
                    .where((colleagueId) => colleagueId != id)
                    .toList(),
              ),
            )
            .toList(),
      ),
    );
  }

  Future<void> saveShift({
    String? id,
    required DateTime date,
    required ShiftKind kind,
    required DateTime start,
    required DateTime end,
    required List<String> colleagueIds,
    required int revenueMinor,
    required String comment,
  }) async {
    final now = DateTime.now();
    final shift = Shift(
      id: id ?? _uuid.v4(),
      date: DateTime(date.year, date.month, date.day),
      kind: kind,
      actualStart: start,
      actualEnd: end.isBefore(start) ? end.add(const Duration(days: 1)) : end,
      colleagueIds: colleagueIds,
      revenueMinor: revenueMinor,
      earningsMinor: _finance.earnings(
        revenueMinor: revenueMinor,
        payment: _data.payment,
      ),
      comment: comment.trim(),
      createdAt: id == null
          ? now
          : _data.shifts.firstWhere((item) => item.id == id).createdAt,
      updatedAt: now,
    );
    final others = _data.shifts.where((item) => item.id != shift.id).toList();
    await _save(
      _data.copyWith(
        shifts: [...others, shift]..sort((a, b) => b.date.compareTo(a.date)),
      ),
    );
  }

  Future<void> deleteShift(String id) => _save(
    _data.copyWith(
      shifts: _data.shifts.where((item) => item.id != id).toList(),
    ),
  );

  Future<void> importBackup(String source) async {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Backup must contain an object.');
    }
    final parsed = AppState.fromJson(decoded);
    await _repository.replace(parsed);
    state = AsyncValue.data(parsed);
  }

  String exportBackup() => _data.toBackupJson();
}
