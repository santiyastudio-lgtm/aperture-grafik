import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../application/app_controller.dart';
import '../core/l10n/strings.dart';
import '../domain/models.dart';
import '../domain/revenue_recommendation_service.dart';
import '../domain/schedule_service.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(appControllerProvider).requireValue;
    final strings = Strings(data.settings.language);
    final pages = [
      HomePage(data: data),
      CalendarPage(data: data),
      StatisticsPage(data: data),
      ProfilePage(data: data),
    ];
    return Scaffold(
      body: SafeArea(child: pages[index]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: strings.home,
          ),
          NavigationDestination(
            icon: const Icon(Icons.calendar_month_outlined),
            selectedIcon: const Icon(Icons.calendar_month),
            label: strings.calendar,
          ),
          NavigationDestination(
            icon: const Icon(Icons.bar_chart_outlined),
            selectedIcon: const Icon(Icons.bar_chart),
            label: strings.statistics,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person),
            label: strings.profile,
          ),
        ],
      ),
    );
  }
}

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _step = 0;
  AppLanguage _language = AppLanguage.russian;
  ScheduleType _type = ScheduleType.twoTwo;
  WorkTime _start = const WorkTime(9, 0);
  WorkTime _end = const WorkTime(21, 0);
  final _rate = TextEditingController(text: '3000');
  final _percent = TextEditingController(text: '5');
  final _colleagues = TextEditingController();
  final _names = <String>[];
  final _weekdays = <int>{
    DateTime.monday,
    DateTime.tuesday,
    DateTime.wednesday,
    DateTime.thursday,
    DateTime.friday,
  };

  @override
  void dispose() {
    _rate.dispose();
    _percent.dispose();
    _colleagues.dispose();
    super.dispose();
  }

  Future<void> _pickTime(bool start) async {
    final current = start ? _start : _end;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current.hour, minute: current.minute),
    );
    if (picked != null) {
      setState(
        () => start
            ? _start = WorkTime(picked.hour, picked.minute)
            : _end = WorkTime(picked.hour, picked.minute),
      );
    }
  }

  Future<void> _finish() async {
    final now = DateTime.now();
    final rate = ((num.tryParse(_rate.text.replaceAll(',', '.')) ?? 0) * 100)
        .round();
    final percent =
        num.tryParse(_percent.text.replaceAll(',', '.'))?.toDouble() ?? 0;
    await ref
        .read(appControllerProvider.notifier)
        .completeOnboarding(
          language: _language,
          schedule: Schedule(
            type: _type,
            anchorDate: DateTime(now.year, now.month, now.day),
            weekdays: _weekdays,
            start: _start,
            end: _end,
          ),
          payment: PaymentSettings(
            dailyRateMinor: rate,
            revenuePercent: percent,
            advanceDay: 15,
            salaryDay: 30,
          ),
          colleagueNames: _names,
        );
  }

  @override
  Widget build(BuildContext context) {
    final isRu = _language == AppLanguage.russian;
    final titles = [
      'Aperture Grafik',
      isRu ? 'Ваш график' : 'Your schedule',
      isRu ? 'Ставка и выручка' : 'Rate and revenue',
      isRu ? 'Коллеги' : 'Colleagues',
      isRu ? 'Время работы' : 'Working hours',
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_step]),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(child: Text('${_step + 1}/5')),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: _page(isRu)),
            FilledButton(
              onPressed: _step == 4
                  ? _finish
                  : () => setState(() => _step += 1),
              child: Text(
                _step == 4
                    ? (isRu ? 'Начать' : 'Start')
                    : (isRu ? 'Далее' : 'Next'),
              ),
            ),
            if (_step > 0)
              TextButton(
                onPressed: () => setState(() => _step -= 1),
                child: Text(isRu ? 'Назад' : 'Back'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _page(bool isRu) => switch (_step) {
    0 => Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.schedule_rounded,
          size: 88,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 20),
        Text(
          isRu
              ? 'Ваш личный график работы и заработок'
              : 'Your personal work schedule and pay',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 32),
        SegmentedButton<AppLanguage>(
          segments: const [
            ButtonSegment(value: AppLanguage.russian, label: Text('Русский')),
            ButtonSegment(value: AppLanguage.english, label: Text('English')),
          ],
          selected: {_language},
          onSelectionChanged: (set) => setState(() => _language = set.first),
        ),
      ],
    ),
    1 => ListView(
      children: [
        for (final type in ScheduleType.values)
          Card(
            child: ListTile(
              leading: Icon(
                type == _type
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
              ),
              title: Text(_scheduleName(type, isRu)),
              subtitle: Text(_scheduleDescription(type, isRu)),
              onTap: () => setState(() => _type = type),
            ),
          ),
        if (_type == ScheduleType.weekdays)
          Wrap(
            spacing: 6,
            children: List.generate(7, (index) {
              final weekday = index + 1;
              final labels = isRu
                  ? ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс']
                  : ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];
              return FilterChip(
                label: Text(labels[index]),
                selected: _weekdays.contains(weekday),
                onSelected: (value) => setState(
                  () => value
                      ? _weekdays.add(weekday)
                      : _weekdays.remove(weekday),
                ),
              );
            }),
          ),
      ],
    ),
    2 => Column(
      children: [
        TextField(
          controller: _rate,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: isRu ? 'Дневная ставка, ₽' : 'Daily rate, ₽',
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _percent,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: isRu ? 'Процент от выручки' : 'Revenue percentage',
            suffixText: '%',
          ),
        ),
        const SizedBox(height: 20),
        _InfoCard(
          icon: Icons.calculate_outlined,
          title: isRu ? 'Пример расчёта' : 'Calculation example',
          text: isRu
              ? 'Ставка + процент от выручки за смену.'
              : 'Daily rate plus a percentage of shift revenue.',
        ),
      ],
    ),
    3 => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          isRu ? 'С кем вы обычно работаете?' : 'Who do you usually work with?',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _colleagues,
                decoration: InputDecoration(
                  hintText: isRu ? 'Имя коллеги' : 'Colleague name',
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: () => setState(() {
                if (_colleagues.text.trim().isNotEmpty) {
                  _names.add(_colleagues.text.trim());
                }
                _colleagues.clear();
              }),
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _names
              .map(
                (name) => InputChip(
                  label: Text(name),
                  onDeleted: () => setState(() => _names.remove(name)),
                ),
              )
              .toList(),
        ),
      ],
    ),
    _ => Column(
      children: [
        _TimeTile(
          label: isRu ? 'Начало' : 'Start',
          value: _start.format(),
          onTap: () => _pickTime(true),
        ),
        const SizedBox(height: 16),
        _TimeTile(
          label: isRu ? 'Конец' : 'End',
          value: _end.format(),
          onTap: () => _pickTime(false),
        ),
        const SizedBox(height: 16),
        Text(
          isRu
              ? 'Смена может заканчиваться на следующий день.'
              : 'A shift may end on the next day.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    ),
  };
}

class HomePage extends ConsumerWidget {
  const HomePage({required this.data, super.key});
  final AppState data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = Strings(data.settings.language);
    final schedule = const ScheduleService();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final planned = schedule.isWorkDay(data.schedule, today);
    final existing = data.shifts
        .where((shift) => _sameDay(shift.date, today))
        .firstOrNull;
    final starts = schedule.startAt(data.schedule, today);
    final ends = schedule.endAt(data.schedule, today);
    final recommendation = const RevenueRecommendationService().recommend(
      shifts: data.shifts,
      targetDate: today,
    );
    final active =
        planned &&
        now.isAfter(starts) &&
        now.isBefore(ends) &&
        existing == null;
    final yesterday = today.subtract(const Duration(days: 1));
    final yesterdayShift = data.shifts
        .where((shift) => _sameDay(shift.date, yesterday))
        .firstOrNull;
    final yesterdayEnd = schedule.endAt(data.schedule, yesterday);
    final pendingDay = planned && now.isAfter(ends) && existing == null
        ? today
        : (schedule.isWorkDay(data.schedule, yesterday) &&
                  yesterdayEnd.day != yesterday.day &&
                  now.isAfter(yesterdayEnd) &&
                  yesterdayShift == null
              ? yesterday
              : null);
    final completionDate = planned && existing == null ? today : pendingDay;
    return _PageScaffold(
      title: strings.home,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          Text(
            DateFormat.yMMMMEEEEd(strings.isRu ? 'ru_RU' : 'en_US').format(now),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          _HeroCard(
            title: planned
                ? (active
                      ? (strings.isRu ? 'Смена идёт' : 'Shift in progress')
                      : (strings.isRu ? 'Рабочий день' : 'Work day'))
                : (strings.isRu ? 'Сегодня выходной' : 'Day off'),
            subtitle: planned
                ? '${data.schedule.start.format()} – ${data.schedule.end.format()}'
                : (strings.isRu
                      ? 'Следующая смена появится в календаре'
                      : 'Your next shift is in the calendar'),
            icon: planned
                ? Icons.work_history_outlined
                : Icons.weekend_outlined,
          ),
          if (recommendation != null) ...[
            const SizedBox(height: 8),
            _RevenueRecommendationCard(
              recommendation: recommendation,
              data: data,
              isRussian: strings.isRu,
            ),
          ],
          const SizedBox(height: 20),
          if (completionDate != null)
            _InlineShiftCompletionForm(
              data: data,
              date: completionDate,
              kind: ShiftKind.scheduled,
            )
          else if (existing != null)
            _SummaryCard(shift: existing, data: data)
          else
            FilledButton.icon(
              onPressed: () => showShiftEditor(
                context,
                data: data,
                date: today,
                kind: planned ? ShiftKind.scheduled : ShiftKind.extra,
              ),
              icon: Icon(
                planned ? Icons.check_circle_outline : Icons.add_circle_outline,
              ),
              label: Text(
                planned
                    ? strings.completeDay
                    : (strings.isRu ? 'Добавить смену' : 'Add shift'),
              ),
            ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => showShiftEditor(
              context,
              data: data,
              date: today,
              kind: ShiftKind.extra,
            ),
            icon: const Icon(Icons.add),
            label: Text(strings.isRu ? 'Внеплановая смена' : 'Extra shift'),
          ),
        ],
      ),
    );
  }
}

class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({required this.data, super.key});
  final AppState data;

  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage> {
  late DateTime month = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final strings = Strings(data.settings.language);
    final schedule = const ScheduleService();
    final first = DateTime(month.year, month.month, 1);
    final leading = first.weekday - 1;
    final lastDay = DateTime(month.year, month.month + 1, 0).day;
    final days = List<Widget>.generate(leading + lastDay, (index) {
      if (index < leading) return const SizedBox.shrink();
      final date = DateTime(month.year, month.month, index - leading + 1);
      final shift = data.shifts
          .where((item) => _sameDay(item.date, date))
          .firstOrNull;
      final planned = schedule.isWorkDay(data.schedule, date);
      final today = _sameDay(date, DateTime.now());
      return InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => showShiftEditor(
          context,
          data: data,
          date: date,
          kind: planned ? ShiftKind.scheduled : ShiftKind.extra,
          existing: shift,
        ),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: shift != null
                ? Theme.of(context).colorScheme.primaryContainer
                : planned
                ? Theme.of(context).colorScheme.secondaryContainer
                : null,
            borderRadius: BorderRadius.circular(16),
            border: today
                ? Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  )
                : null,
          ),
          child: Text(
            '${date.day}',
            style: TextStyle(
              fontWeight: shift != null || today
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
          ),
        ),
      );
    });
    final history =
        data.shifts
            .where(
              (item) =>
                  item.date.year == month.year &&
                  item.date.month == month.month,
            )
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));
    return _PageScaffold(
      title: strings.calendar,
      actions: [
        IconButton(
          onPressed: () => showShiftEditor(
            context,
            data: data,
            date: DateTime.now(),
            kind: ShiftKind.extra,
          ),
          icon: const Icon(Icons.add),
        ),
      ],
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => setState(
                  () => month = DateTime(month.year, month.month - 1),
                ),
                icon: const Icon(Icons.chevron_left),
              ),
              Text(
                DateFormat.yMMMM(
                  strings.isRu ? 'ru_RU' : 'en_US',
                ).format(month),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              IconButton(
                onPressed: () => setState(
                  () => month = DateTime(month.year, month.month + 1),
                ),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children:
                (strings.isRu
                        ? ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс']
                        : ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'])
                    .map(
                      (item) => Expanded(
                        child: Center(
                          child: Text(
                            item,
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ),
                      ),
                    )
                    .toList(),
          ),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: days,
          ),
          const SizedBox(height: 28),
          Text(
            strings.isRu ? 'Завершённые смены' : 'Completed shifts',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          if (history.isEmpty)
            _EmptyCard(
              text: strings.isRu
                  ? 'В этом месяце пока нет записей.'
                  : 'No completed shifts this month.',
            ),
          ...history.map(
            (shift) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _HistoryRow(
                shift: shift,
                data: data,
                onTap: () => showShiftEditor(
                  context,
                  data: data,
                  date: shift.date,
                  kind: shift.kind,
                  existing: shift,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class StatisticsPage extends ConsumerStatefulWidget {
  const StatisticsPage({required this.data, super.key});
  final AppState data;

  @override
  ConsumerState<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends ConsumerState<StatisticsPage> {
  int range = 1;

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final strings = Strings(data.settings.language);
    final now = DateTime.now();
    final from = switch (range) {
      0 => now.subtract(const Duration(days: 7)),
      1 => DateTime(now.year, now.month, 1),
      _ => DateTime(now.year, 1, 1),
    };
    final shifts = data.shifts
        .where(
          (item) =>
              !item.date.isBefore(DateTime(from.year, from.month, from.day)),
        )
        .toList();
    final revenue = shifts.fold<int>(0, (sum, item) => sum + item.revenueMinor);
    final earnings = shifts.fold<int>(
      0,
      (sum, item) => sum + item.earningsMinor,
    );
    final points = <int, int>{};
    for (final shift in shifts) {
      points.update(
        shift.date.day,
        (value) => value + shift.earningsMinor,
        ifAbsent: () => shift.earningsMinor,
      );
    }
    final entries = points.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return _PageScaffold(
      title: strings.statistics,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          SegmentedButton<int>(
            segments: [
              ButtonSegment(
                value: 0,
                label: Text(strings.isRu ? 'Неделя' : 'Week'),
              ),
              ButtonSegment(
                value: 1,
                label: Text(strings.isRu ? 'Месяц' : 'Month'),
              ),
              ButtonSegment(
                value: 2,
                label: Text(strings.isRu ? 'Год' : 'Year'),
              ),
            ],
            selected: {range},
            onSelectionChanged: (set) => setState(() => range = set.first),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  label: strings.revenue,
                  value: money(data, revenue),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  label: strings.earnings,
                  value: money(data, earnings),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
              child: SizedBox(
                height: 210,
                child: entries.isEmpty
                    ? Center(
                        child: Text(
                          strings.isRu
                              ? 'Нет данных за выбранный период'
                              : 'No data for this period',
                        ),
                      )
                    : BarChart(
                        BarChartData(
                          borderData: FlBorderData(show: false),
                          gridData: const FlGridData(show: false),
                          titlesData: const FlTitlesData(show: false),
                          barGroups: entries.asMap().entries.map((entry) {
                            return BarChartGroupData(
                              x: entry.key,
                              barRods: [
                                BarChartRodData(
                                  toY: entry.value.value / 100,
                                  color: Theme.of(context).colorScheme.primary,
                                  width: 14,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(6),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _InfoCard(
            icon: Icons.event_available_outlined,
            title: strings.isRu
                ? '${shifts.length} смен'
                : '${shifts.length} shifts',
            text: shifts.isEmpty
                ? (strings.isRu
                      ? 'Добавьте первую завершённую смену.'
                      : 'Add your first completed shift.')
                : (strings.isRu
                      ? 'Средний заработок: ${money(data, earnings ~/ shifts.length)}'
                      : 'Average earnings: ${money(data, earnings ~/ shifts.length)}'),
          ),
        ],
      ),
    );
  }
}

class ProfilePage extends ConsumerWidget {
  const ProfilePage({required this.data, super.key});
  final AppState data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = Strings(data.settings.language);
    final controller = ref.read(appControllerProvider.notifier);
    return _PageScaffold(
      title: strings.profile,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          _SectionTitle(strings.isRu ? 'Настройки' : 'Settings'),
          _SettingsTile(
            icon: Icons.language,
            title: strings.isRu ? 'Язык' : 'Language',
            subtitle: data.settings.language == AppLanguage.russian
                ? 'Русский'
                : 'English',
            onTap: () => _selectLanguage(context, data, controller),
          ),
          _SettingsTile(
            icon: Icons.palette_outlined,
            title: strings.isRu ? 'Дизайн' : 'Design',
            subtitle: _themeName(data.settings.themeMode, strings.isRu),
            onTap: () => _selectTheme(context, data, controller),
          ),
          SwitchListTile.adaptive(
            value: data.settings.notificationsEnabled,
            onChanged: (value) => controller.updateSettings(
              data.settings.copyWith(notificationsEnabled: value),
            ),
            secondary: const Icon(Icons.notifications_outlined),
            title: Text(
              strings.isRu
                  ? 'Напоминание в конце смены'
                  : 'End-of-shift reminder',
            ),
          ),
          const SizedBox(height: 18),
          _SectionTitle(strings.isRu ? 'Работа' : 'Work'),
          _SettingsTile(
            icon: Icons.schedule,
            title: strings.isRu ? 'График' : 'Schedule',
            subtitle:
                '${_scheduleName(data.schedule.type, strings.isRu)} · ${data.schedule.start.format()}–${data.schedule.end.format()}',
            onTap: () => _editSchedule(context, data, controller),
          ),
          _SettingsTile(
            icon: Icons.payments_outlined,
            title: strings.isRu ? 'Ставка и выручка' : 'Pay and revenue',
            subtitle:
                '${money(data, data.payment.dailyRateMinor)} + ${data.payment.revenuePercent}%',
            onTap: () => _editPayment(context, data, controller),
          ),
          _SettingsTile(
            icon: Icons.people_outline,
            title: strings.isRu ? 'Коллеги' : 'Colleagues',
            subtitle: strings.isRu
                ? '${data.colleagues.length} в справочнике'
                : '${data.colleagues.length} in directory',
            onTap: () => _manageColleagues(context, controller),
          ),
          const SizedBox(height: 18),
          _SectionTitle(
            strings.isRu ? 'Поддержка проекта' : 'Support the project',
          ),
          _SettingsTile(
            icon: Icons.volunteer_activism_outlined,
            title: strings.isRu
                ? 'Поддержать разработку'
                : 'Support development',
            subtitle: strings.isRu
                ? 'BTC, ETH, SOL и USDT (Solana)'
                : 'BTC, ETH, SOL, and USDT (Solana)',
            onTap: () => _showSupport(context, strings.isRu),
          ),
          const SizedBox(height: 18),
          _SectionTitle(strings.isRu ? 'Данные' : 'Data'),
          _SettingsTile(
            icon: Icons.upload_file_outlined,
            title: strings.isRu ? 'Экспорт backup' : 'Export backup',
            subtitle: strings.isRu
                ? 'JSON-файл без шифрования'
                : 'Unencrypted JSON file',
            onTap: () => _export(context, controller, strings.isRu),
          ),
          _SettingsTile(
            icon: Icons.download_outlined,
            title: strings.isRu ? 'Импорт backup' : 'Import backup',
            subtitle: strings.isRu
                ? 'Заменит все локальные данные'
                : 'Replaces all local data',
            onTap: () => _import(context, controller, strings.isRu),
          ),
        ],
      ),
    );
  }
}

Future<void> showShiftEditor(
  BuildContext context, {
  required AppState data,
  required DateTime date,
  required ShiftKind kind,
  Shift? existing,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) =>
        _ShiftEditor(data: data, date: date, kind: kind, existing: existing),
  );
}

class _ShiftEditor extends ConsumerStatefulWidget {
  const _ShiftEditor({
    required this.data,
    required this.date,
    required this.kind,
    this.existing,
  });
  final AppState data;
  final DateTime date;
  final ShiftKind kind;
  final Shift? existing;

  @override
  ConsumerState<_ShiftEditor> createState() => _ShiftEditorState();
}

class _ShiftEditorState extends ConsumerState<_ShiftEditor> {
  late final TextEditingController revenue = TextEditingController(
    text: widget.existing == null
        ? ''
        : (widget.existing!.revenueMinor / 100).toStringAsFixed(2),
  );
  late final TextEditingController comment = TextEditingController(
    text: widget.existing?.comment ?? '',
  );
  late DateTime start =
      widget.existing?.actualStart ??
      const ScheduleService().startAt(widget.data.schedule, widget.date);
  late DateTime end =
      widget.existing?.actualEnd ??
      const ScheduleService().endAt(widget.data.schedule, widget.date);
  late Set<String> people = widget.existing?.colleagueIds.toSet() ?? <String>{};

  @override
  void dispose() {
    revenue.dispose();
    comment.dispose();
    super.dispose();
  }

  Future<void> _time(bool isStart) async {
    final value = isStart ? start : end;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(value),
    );
    if (picked != null) {
      setState(() {
        final result = DateTime(
          widget.date.year,
          widget.date.month,
          widget.date.day,
          picked.hour,
          picked.minute,
        );
        if (isStart) {
          start = result;
        } else {
          end = result;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = Strings(widget.data.settings.language);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: ListView(
        shrinkWrap: true,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.existing == null
                      ? strings.completeDay
                      : (strings.isRu ? 'Изменить смену' : 'Edit shift'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          Text(
            DateFormat.yMMMMd(
              strings.isRu ? 'ru_RU' : 'en_US',
            ).format(widget.date),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _TimeTile(
                  label: strings.isRu ? 'Начало' : 'Start',
                  value: DateFormat.Hm().format(start),
                  onTap: () => _time(true),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _TimeTile(
                  label: strings.isRu ? 'Конец' : 'End',
                  value: DateFormat.Hm().format(end),
                  onTap: () => _time(false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            strings.isRu ? 'С кем работали' : 'Who worked with you',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 6),
          ...widget.data.colleagues.map(
            (person) => CheckboxListTile(
              value: people.contains(person.id),
              onChanged: (selected) => setState(
                () => selected == true
                    ? people.add(person.id)
                    : people.remove(person.id),
              ),
              title: Text(person.name),
              secondary: _Avatar(person: person),
              controlAffinity: ListTileControlAffinity.trailing,
            ),
          ),
          TextField(
            controller: revenue,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: strings.revenue,
              suffixText: '₽',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: comment,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: strings.isRu
                  ? 'Комментарий (необязательно)'
                  : 'Comment (optional)',
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () async {
              final amount =
                  ((num.tryParse(revenue.text.replaceAll(',', '.')) ?? 0) * 100)
                      .round();
              await ref
                  .read(appControllerProvider.notifier)
                  .saveShift(
                    id: widget.existing?.id,
                    date: widget.date,
                    kind: widget.kind,
                    start: start,
                    end: end,
                    colleagueIds: people.toList(),
                    revenueMinor: amount,
                    comment: comment.text,
                  );
              if (context.mounted) Navigator.pop(context);
            },
            child: Text(strings.save),
          ),
          if (widget.existing != null)
            TextButton.icon(
              onPressed: () async {
                await ref
                    .read(appControllerProvider.notifier)
                    .deleteShift(widget.existing!.id);
                if (context.mounted) Navigator.pop(context);
              },
              icon: const Icon(Icons.delete_outline),
              label: Text(strings.isRu ? 'Удалить смену' : 'Delete shift'),
            ),
        ],
      ),
    );
  }
}

class _PageScaffold extends StatelessWidget {
  const _PageScaffold({required this.title, required this.child, this.actions});
  final String title;
  final Widget child;
  final List<Widget>? actions;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title), actions: actions),
    body: child,
  );
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.title,
    required this.subtitle,
    required this.icon,
  });
  final String title;
  final String subtitle;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(subtitle),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Text(value, style: Theme.of(context).textTheme.titleLarge),
        ],
      ),
    ),
  );
}

class _InlineShiftCompletionForm extends ConsumerStatefulWidget {
  const _InlineShiftCompletionForm({
    required this.data,
    required this.date,
    required this.kind,
  });

  final AppState data;
  final DateTime date;
  final ShiftKind kind;

  @override
  ConsumerState<_InlineShiftCompletionForm> createState() =>
      _InlineShiftCompletionFormState();
}

class _InlineShiftCompletionFormState
    extends ConsumerState<_InlineShiftCompletionForm> {
  late final TextEditingController _revenue = TextEditingController();
  late final TextEditingController _comment = TextEditingController();
  late DateTime _start = const ScheduleService().startAt(
    widget.data.schedule,
    widget.date,
  );
  late DateTime _end = const ScheduleService().endAt(
    widget.data.schedule,
    widget.date,
  );
  final Set<String> _colleagueIds = <String>{};

  @override
  void dispose() {
    _revenue.dispose();
    _comment.dispose();
    super.dispose();
  }

  Future<void> _pickTime(bool isStart) async {
    final current = isStart ? _start : _end;
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (selected == null) return;
    setState(() {
      final result = DateTime(
        widget.date.year,
        widget.date.month,
        widget.date.day,
        selected.hour,
        selected.minute,
      );
      if (isStart) {
        _start = result;
      } else {
        _end = result;
      }
    });
  }

  Future<void> _save() async {
    final revenueMinor =
        ((num.tryParse(_revenue.text.replaceAll(',', '.')) ?? 0) * 100).round();
    await ref
        .read(appControllerProvider.notifier)
        .saveShift(
          date: widget.date,
          kind: widget.kind,
          start: _start,
          end: _end,
          colleagueIds: _colleagueIds.toList(),
          revenueMinor: revenueMinor,
          comment: _comment.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final strings = Strings(widget.data.settings.language);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.isRu ? 'Заполните смену' : 'Fill in shift',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _TimeTile(
                    label: strings.isRu ? 'Начало' : 'Start',
                    value: DateFormat.Hm().format(_start),
                    onTap: () => _pickTime(true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TimeTile(
                    label: strings.isRu ? 'Конец' : 'End',
                    value: DateFormat.Hm().format(_end),
                    onTap: () => _pickTime(false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              strings.isRu ? 'С кем работали' : 'Who worked with you',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 10),
            if (widget.data.colleagues.isEmpty)
              Text(
                strings.isRu
                    ? 'Добавьте коллег в профиле.'
                    : 'Add colleagues from Profile.',
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.data.colleagues.map((person) {
                  final selected = _colleagueIds.contains(person.id);
                  return FilterChip(
                    selected: selected,
                    onSelected: (value) => setState(
                      () => value
                          ? _colleagueIds.add(person.id)
                          : _colleagueIds.remove(person.id),
                    ),
                    avatar: _Avatar(person: person),
                    label: Text(person.name),
                  );
                }).toList(),
              ),
            const SizedBox(height: 20),
            TextField(
              controller: _revenue,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: strings.revenue,
                suffixText: '₽',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _comment,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: strings.isRu
                    ? 'Комментарий (необязательно)'
                    : 'Comment (optional)',
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check_circle_outline),
              label: Text(strings.isRu ? 'Заполнить' : 'Complete'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RevenueRecommendationCard extends StatelessWidget {
  const _RevenueRecommendationCard({
    required this.recommendation,
    required this.data,
    required this.isRussian,
  });

  final RevenueRecommendation recommendation;
  final AppState data;
  final bool isRussian;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = recommendation.hasEnoughData
        ? (isRussian ? 'Рекомендация по выручке' : 'Revenue recommendation')
        : (isRussian
              ? 'Рекомендация появится после 3 заполненных смен'
              : 'Recommendation is available after 3 completed shifts');
    return Card(
      color: scheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_graph_rounded,
                  color: scheme.onSecondaryContainer,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    text,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (recommendation.hasEnoughData) ...[
              Text(
                money(data, recommendation.referenceMinor),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              Text(
                isRussian
                    ? 'Обычный диапазон: ${money(data, recommendation.lowerMinor)} – ${money(data, recommendation.upperMinor)}'
                    : 'Typical range: ${money(data, recommendation.lowerMinor)} – ${money(data, recommendation.upperMinor)}',
              ),
              if (recommendation.usuallyHigherOnThisWeekday ||
                  recommendation.latestWasUnusuallyHigh) ...[
                const SizedBox(height: 12),
                _RecommendationAlert(
                  isRussian: isRussian,
                  usuallyHigherOnThisWeekday:
                      recommendation.usuallyHigherOnThisWeekday,
                  latestWasUnusuallyHigh: recommendation.latestWasUnusuallyHigh,
                ),
              ],
            ] else
              Text(
                isRussian
                    ? 'Уже учтено смен: ${recommendation.sampleSize}. Заполняйте выручку после каждой смены.'
                    : 'Completed shifts recorded: ${recommendation.sampleSize}. Add revenue after each shift.',
              ),
          ],
        ),
      ),
    );
  }
}

class _RecommendationAlert extends StatelessWidget {
  const _RecommendationAlert({
    required this.isRussian,
    required this.usuallyHigherOnThisWeekday,
    required this.latestWasUnusuallyHigh,
  });

  final bool isRussian;
  final bool usuallyHigherOnThisWeekday;
  final bool latestWasUnusuallyHigh;

  @override
  Widget build(BuildContext context) {
    final message = usuallyHigherOnThisWeekday
        ? (isRussian
              ? 'В этот день недели обычно выручка заметно выше средней.'
              : 'This weekday usually has noticeably higher revenue.')
        : latestWasUnusuallyHigh
        ? (isRussian
              ? 'Последняя заполненная смена была выше обычного диапазона.'
              : 'The latest completed shift was above the usual range.')
        : '';
    return Row(
      children: [
        const Icon(Icons.trending_up_rounded),
        const SizedBox(width: 8),
        Expanded(child: Text(message)),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.shift, required this.data});
  final Shift shift;
  final AppState data;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            Strings(data.settings.language).isRu
                ? 'Смена завершена'
                : 'Shift completed',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Text(
            '${Strings(data.settings.language).revenue}: ${money(data, shift.revenueMinor)}',
          ),
          Text(
            '${Strings(data.settings.language).earnings}: ${money(data, shift.earningsMinor)}',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ),
  );
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({
    required this.shift,
    required this.data,
    required this.onTap,
  });
  final Shift shift;
  final AppState data;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      onTap: onTap,
      title: Text(
        DateFormat.MMMMd(
          Strings(data.settings.language).isRu ? 'ru_RU' : 'en_US',
        ).format(shift.date),
      ),
      subtitle: Text(
        '${Strings(data.settings.language).revenue}: ${money(data, shift.revenueMinor)}',
      ),
      trailing: Text(
        money(data, shift.earningsMinor),
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    ),
  );
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.text,
  });
  final IconData icon;
  final String title;
  final String text;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(text),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Text(text, textAlign: TextAlign.center),
    ),
  );
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.person});
  final Colleague person;
  @override
  Widget build(BuildContext context) => CircleAvatar(
    backgroundColor: Color(person.colorValue),
    child: Text(
      person.name.isEmpty ? '?' : person.name.characters.first.toUpperCase(),
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    ),
  );
}

class _TimeTile extends StatelessWidget {
  const _TimeTile({
    required this.label,
    required this.value,
    required this.onTap,
  });
  final String label;
  final String value;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(14),
    child: InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: const Icon(Icons.schedule),
      ),
      child: Text(value, style: Theme.of(context).textTheme.titleMedium),
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.value);
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(value, style: Theme.of(context).textTheme.titleSmall),
  );
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      onTap: onTap,
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
    ),
  );
}

Future<void> _selectLanguage(
  BuildContext context,
  AppState data,
  AppController controller,
) async {
  final result = await showDialog<AppLanguage>(
    context: context,
    builder: (context) => SimpleDialog(
      title: const Text('Language'),
      children: AppLanguage.values
          .map(
            (item) => SimpleDialogOption(
              onPressed: () => Navigator.pop(context, item),
              child: Text(item == AppLanguage.russian ? 'Русский' : 'English'),
            ),
          )
          .toList(),
    ),
  );
  if (result != null) {
    await controller.updateSettings(data.settings.copyWith(language: result));
  }
}

Future<void> _selectTheme(
  BuildContext context,
  AppState data,
  AppController controller,
) async {
  final ru = data.settings.language == AppLanguage.russian;
  final result = await showDialog<AppThemeMode>(
    context: context,
    builder: (context) => SimpleDialog(
      title: Text(ru ? 'Дизайн' : 'Design'),
      children: AppThemeMode.values
          .map(
            (item) => SimpleDialogOption(
              onPressed: () => Navigator.pop(context, item),
              child: Text(_themeName(item, ru)),
            ),
          )
          .toList(),
    ),
  );
  if (result != null) {
    await controller.updateSettings(data.settings.copyWith(themeMode: result));
  }
}

Future<void> _showSupport(BuildContext context, bool isRussian) async {
  const endpoints = [
    _SupportAddress(
      titleRu: 'Bitcoin (BTC)',
      titleEn: 'Bitcoin (BTC)',
      networkRu: 'Сеть Bitcoin',
      networkEn: 'Bitcoin network',
      value: 'bc1qhft9dxkn0g07zm9ht8zrfqyrh85djhueu4q49k',
    ),
    _SupportAddress(
      titleRu: 'Ethereum (ETH)',
      titleEn: 'Ethereum (ETH)',
      networkRu: 'Сеть Ethereum',
      networkEn: 'Ethereum network',
      value: '0x5311B0318A24F63196A572b447609bc336A4C7b2',
    ),
    _SupportAddress(
      titleRu: 'Solana (SOL)',
      titleEn: 'Solana (SOL)',
      networkRu: 'Сеть Solana',
      networkEn: 'Solana network',
      value: '9i76uPGouNh8KVB8LtippfFY7p6kG2ZSLbtLwPqb6i76',
    ),
    _SupportAddress(
      titleRu: 'USDT (Tether)',
      titleEn: 'USDT (Tether)',
      networkRu: 'Только сеть Solana (SPL)',
      networkEn: 'Solana network (SPL) only',
      value: '9i76uPGouNh8KVB8LtippfFY7p6kG2ZSLbtLwPqb6i76',
    ),
  ];
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(isRussian ? 'Поддержать разработку' : 'Support development'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isRussian
                    ? 'Проверяйте сеть перед отправкой. Нажмите на значок, чтобы скопировать адрес.'
                    : 'Verify the network before sending. Tap the icon to copy an address.',
              ),
              const SizedBox(height: 12),
              ...endpoints.map(
                (endpoint) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(isRussian ? endpoint.titleRu : endpoint.titleEn),
                  subtitle: Text(
                    '${isRussian ? endpoint.networkRu : endpoint.networkEn}\n${endpoint.value}',
                  ),
                  isThreeLine: true,
                  trailing: IconButton(
                    tooltip: isRussian ? 'Скопировать адрес' : 'Copy address',
                    onPressed: () async {
                      await Clipboard.setData(
                        ClipboardData(text: endpoint.value),
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isRussian ? 'Адрес скопирован' : 'Address copied',
                            ),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.copy_outlined),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(isRussian ? 'Закрыть' : 'Close'),
        ),
      ],
    ),
  );
}

class _SupportAddress {
  const _SupportAddress({
    required this.titleRu,
    required this.titleEn,
    required this.networkRu,
    required this.networkEn,
    required this.value,
  });

  final String titleRu;
  final String titleEn;
  final String networkRu;
  final String networkEn;
  final String value;
}

Future<void> _editSchedule(
  BuildContext context,
  AppState data,
  AppController controller,
) async {
  ScheduleType type = data.schedule.type;
  WorkTime start = data.schedule.start;
  WorkTime end = data.schedule.end;
  final days = {...data.schedule.weekdays};
  final result = await showDialog<Schedule>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('График'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<ScheduleType>(
                initialValue: type,
                items: ScheduleType.values
                    .map(
                      (item) => DropdownMenuItem(
                        value: item,
                        child: Text(_scheduleName(item, true)),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => type = value!),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _TimeTile(
                      label: 'Начало',
                      value: start.format(),
                      onTap: () async {
                        final value = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay(
                            hour: start.hour,
                            minute: start.minute,
                          ),
                        );
                        if (value != null) {
                          setState(
                            () => start = WorkTime(value.hour, value.minute),
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _TimeTile(
                      label: 'Конец',
                      value: end.format(),
                      onTap: () async {
                        final value = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay(
                            hour: end.hour,
                            minute: end.minute,
                          ),
                        );
                        if (value != null) {
                          setState(
                            () => end = WorkTime(value.hour, value.minute),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
              if (type == ScheduleType.weekdays)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Wrap(
                    spacing: 4,
                    children: List.generate(7, (index) {
                      final day = index + 1;
                      return FilterChip(
                        label: Text(
                          ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'][index],
                        ),
                        selected: days.contains(day),
                        onSelected: (value) => setState(
                          () => value ? days.add(day) : days.remove(day),
                        ),
                      );
                    }),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              context,
              data.schedule.copyWith(
                type: type,
                start: start,
                end: end,
                weekdays: days,
              ),
            ),
            child: const Text('Сохранить'),
          ),
        ],
      ),
    ),
  );
  if (result != null) {
    await controller.updateSchedule(result);
  }
}

Future<void> _editPayment(
  BuildContext context,
  AppState data,
  AppController controller,
) async {
  final rate = TextEditingController(
    text: (data.payment.dailyRateMinor / 100).toStringAsFixed(2),
  );
  final percent = TextEditingController(text: '${data.payment.revenuePercent}');
  final result = await showDialog<PaymentSettings>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Ставка и выручка'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: rate,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Дневная ставка'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: percent,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Процент от выручки',
              suffixText: '%',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            PaymentSettings(
              dailyRateMinor:
                  ((num.tryParse(rate.text.replaceAll(',', '.')) ?? 0) * 100)
                      .round(),
              revenuePercent:
                  num.tryParse(percent.text.replaceAll(',', '.'))?.toDouble() ??
                  0,
              advanceDay: data.payment.advanceDay,
              salaryDay: data.payment.salaryDay,
            ),
          ),
          child: const Text('Сохранить'),
        ),
      ],
    ),
  );
  rate.dispose();
  percent.dispose();
  if (result != null) {
    await controller.updatePayment(result);
  }
}

Future<void> _manageColleagues(
  BuildContext context,
  AppController controller,
) async {
  final text = TextEditingController();
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Consumer(
        builder: (context, ref, _) {
          final latest = ref.watch(appControllerProvider).requireValue;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Коллеги', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: latest.colleagues
                      .map(
                        (person) => ListTile(
                          leading: _Avatar(person: person),
                          title: Text(person.name),
                          trailing: IconButton(
                            onPressed: () =>
                                controller.deleteColleague(person.id),
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: text,
                      decoration: const InputDecoration(
                        hintText: 'Имя коллеги',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: () async {
                      await controller.addColleague(text.text);
                      text.clear();
                    },
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    ),
  );
  text.dispose();
}

Future<void> _export(
  BuildContext context,
  AppController controller,
  bool ru,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(ru ? 'Экспорт backup' : 'Export backup'),
      content: Text(
        ru
            ? 'Резервная копия создаётся в незашифрованном JSON-файле. Не передавайте его посторонним.'
            : 'The backup is an unencrypted JSON file. Do not share it with people you do not trust.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(ru ? 'Отмена' : 'Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(ru ? 'Продолжить' : 'Continue'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;
  try {
    final directory = await getTemporaryDirectory();
    final file = File(
      '${directory.path}${Platform.pathSeparator}aperture_grafik_backup_${DateTime.now().toIso8601String().replaceAll(':', '-')}.json',
    );
    await file.writeAsString(controller.exportBackup());
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: ru
            ? 'Резервная копия Aperture Grafik. Файл не зашифрован.'
            : 'Aperture Grafik backup. This file is unencrypted.',
      ),
    );
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ru
                ? 'Не удалось экспортировать backup.'
                : 'Could not export backup.',
          ),
        ),
      );
    }
  }
}

Future<void> _import(
  BuildContext context,
  AppController controller,
  bool ru,
) async {
  final picked = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: const ['json'],
    withData: true,
  );
  if (!context.mounted) return;
  if (picked == null || picked.files.single.bytes == null) return;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(ru ? 'Заменить данные?' : 'Replace data?'),
      content: Text(
        ru
            ? 'Текущие локальные данные будут заменены содержимым backup.'
            : 'Current local data will be replaced by this backup.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(ru ? 'Отмена' : 'Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(ru ? 'Импортировать' : 'Import'),
        ),
      ],
    ),
  );
  if (confirmed != true) return;
  try {
    await controller.importBackup(
      String.fromCharCodes(picked.files.single.bytes!),
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ru ? 'Данные восстановлены.' : 'Data restored.'),
        ),
      );
    }
  } on FormatException {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ru
                ? 'Неверный или несовместимый backup.'
                : 'Invalid or incompatible backup.',
          ),
        ),
      );
    }
  }
}

bool _sameDay(DateTime left, DateTime right) =>
    left.year == right.year &&
    left.month == right.month &&
    left.day == right.day;
String money(AppState data, int minor) => NumberFormat.currency(
  locale: data.settings.language == AppLanguage.russian ? 'ru_RU' : 'en_US',
  symbol: '₽',
  decimalDigits: 2,
).format(minor / 100);
String _scheduleName(ScheduleType type, bool ru) => switch (type) {
  ScheduleType.threeThree => '3/3',
  ScheduleType.twoTwo => '2/2',
  ScheduleType.fiveTwo => '5/2',
  ScheduleType.weekdays => ru ? 'По дням недели' : 'Weekdays',
};
String _scheduleDescription(ScheduleType type, bool ru) => switch (type) {
  ScheduleType.threeThree =>
    ru ? 'Три рабочих / три выходных' : 'Three on / three off',
  ScheduleType.twoTwo => ru ? 'Два рабочих / два выходных' : 'Two on / two off',
  ScheduleType.fiveTwo =>
    ru ? 'Пять рабочих / два выходных' : 'Five on / two off',
  ScheduleType.weekdays => ru ? 'Выберите нужные дни' : 'Choose your days',
};
String _themeName(AppThemeMode mode, bool ru) => switch (mode) {
  AppThemeMode.standard => ru ? 'Обычная Material 3' : 'Standard Material 3',
  AppThemeMode.laboratory => ru ? 'Лабораторная' : 'Laboratory',
  AppThemeMode.aperture => ru ? 'Сине-оранжевая' : 'Blue and orange',
  AppThemeMode.chamber => ru ? 'Контрастная камера' : 'Contrast chamber',
};
