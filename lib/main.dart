import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/storage/hive_repository.dart';
import 'core/providers/storage_provider.dart';
import 'core/theme/app_theme.dart';
import 'l10n/l10n.dart';
import 'features/settings/providers/preferences_provider.dart';
import 'shared/art/sushi_art.dart';
import 'shared/widgets/bottom_nav.dart';
import 'shared/widgets/home_widget_sync.dart';
import 'shared/widgets/launch_action_controller.dart';
import 'shared/widgets/screen_awake_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Draw behind the status and navigation bars, as Android 15 requires;
  // screens keep their content clear of them with safe-area padding.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  runApp(const StartupApp());
}

/// Shared by the startup screens and the app so both speak the same language.
MaterialApp _localizedApp({
  required Widget home,
  String? title,
  ThemeMode themeMode = ThemeMode.dark,
}) => MaterialApp(
  title: title ?? 'Sushi Tracker',
  theme: AppTheme.lightTheme,
  darkTheme: AppTheme.darkTheme,
  themeMode: themeMode,
  home: home,
  debugShowCheckedModeBanner: false,
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: AppLocalizations.supportedLocales,
);

/// Keeps a storage failure visible and retryable instead of exiting before the
/// user gets a screen to recover from it.
class StartupApp extends StatefulWidget {
  const StartupApp({super.key, this.createRepository});

  final HiveRepository Function()? createRepository;

  @override
  State<StartupApp> createState() => _StartupAppState();
}

class _StartupAppState extends State<StartupApp> {
  late Future<HiveRepository> _startup;

  @override
  void initState() {
    super.initState();
    _startup = _initialize();
  }

  Future<HiveRepository> _initialize() async {
    final repository = widget.createRepository?.call() ?? HiveRepository();
    await repository.init();
    return repository;
  }

  void _retry() => setState(() => _startup = _initialize());

  @override
  Widget build(BuildContext context) => FutureBuilder<HiveRepository>(
    future: _startup,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return _localizedApp(home: _StartupError(onRetry: _retry));
      }
      if (!snapshot.hasData) {
        return _localizedApp(home: const _StartupLoading());
      }
      return ProviderScope(
        overrides: [storageProvider.overrideWithValue(snapshot.data!)],
        child: const SushiScoreApp(),
      );
    },
  );
}

class _StartupLoading extends StatelessWidget {
  const _StartupLoading();

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SushiArt(size: 120),
          const SizedBox(height: 20),
          const SizedBox(
            width: 120,
            child: LinearProgressIndicator(minHeight: 4),
          ),
          const SizedBox(height: 12),
          Text(
            context.l10n.loadingData,
            style: TextStyle(color: context.colors.textMuted),
          ),
        ],
      ),
    ),
  );
}

class _StartupError extends StatelessWidget {
  const _StartupError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SushiArt(size: 120, mood: SushiMood.worried),
              const SizedBox(height: 20),
              Text(
                context.l10n.storageError,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(context.l10n.tryAgain),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class SushiScoreApp extends ConsumerWidget {
  const SushiScoreApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => _localizedApp(
    title: 'Sushi Tracker',
    themeMode: ref.watch(themeModeProvider),
    home: const LaunchActionController(
      child: HomeWidgetSync(
        child: ScreenAwakeController(child: RootNavigation()),
      ),
    ),
  );
}
