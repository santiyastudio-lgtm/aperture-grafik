import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'application/app_controller.dart';
import 'core/notifications/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'domain/models.dart';
import 'presentation/app_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();
  await NotificationService.instance.initialize();
  runApp(const ProviderScope(child: ApertureApp()));
}

class ApertureApp extends ConsumerStatefulWidget {
  const ApertureApp({super.key});

  @override
  ConsumerState<ApertureApp> createState() => _ApertureAppState();
}

class _ApertureAppState extends ConsumerState<ApertureApp> {
  late final ProviderSubscription<AsyncValue<AppState>> _stateSubscription;

  @override
  void initState() {
    super.initState();
    _stateSubscription = ref.listenManual(appControllerProvider, (
      previous,
      next,
    ) {
      final data = next.asData?.value;
      if (data != null) {
        unawaited(NotificationService.instance.scheduleNextEndReminder(data));
      }
    }, fireImmediately: true);
  }

  @override
  void dispose() {
    _stateSubscription.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appControllerProvider);
    final data = state.asData?.value;
    return MaterialApp(
      title: 'Aperture Grafik',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.forMode(
        data?.settings.themeMode ?? AppThemeMode.standard,
      ),
      locale: data?.settings.language == AppLanguage.english
          ? const Locale('en')
          : const Locale('ru'),
      supportedLocales: const [Locale('ru'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: state.when(
        loading: () => const _Splash(),
        error: (error, _) => _StartupError(error: error),
        data: (loaded) => loaded.settings.onboardingComplete
            ? const AppShell()
            : const OnboardingScreen(),
      ),
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}

class _StartupError extends ConsumerWidget {
  const _StartupError({required this.error});
  final Object error;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 16),
            Text(
              'Не удалось открыть локальные данные.\n$error',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () =>
                  ref.read(appControllerProvider.notifier).initialize(),
              child: const Text('Повторить'),
            ),
          ],
        ),
      ),
    ),
  );
}
