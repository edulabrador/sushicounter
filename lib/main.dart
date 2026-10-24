import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/storage/hive_repository.dart';
import 'core/providers/storage_provider.dart';
import 'core/theme/app_theme.dart';
import 'l10n/l10n.dart';
import 'shared/widgets/bottom_nav.dart';
import 'shared/widgets/launch_action_controller.dart';
import 'shared/widgets/screen_awake_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const StartupApp());
}

/// Shared by the startup screens and the app so both speak the same language.
MaterialApp _localizedApp({required Widget home, String? title}) => MaterialApp(
  title: title ?? 'Sushi Tracker',
  theme: AppTheme.darkTheme,
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
        return _localizedApp(
          home: const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
        );
      }
      return ProviderScope(
        overrides: [storageProvider.overrideWithValue(snapshot.data!)],
        child: const SushiScoreApp(),
      );
    },
  );
}

class _StartupError extends StatelessWidget {
  const _StartupError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.storage_outlined, size: 48),
            const SizedBox(height: 16),
            Text(context.l10n.storageError, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onRetry,
              child: Text(context.l10n.tryAgain),
            ),
          ],
        ),
      ),
    ),
  );
}

class SushiScoreApp extends StatelessWidget {
  const SushiScoreApp({super.key});

  @override
  Widget build(BuildContext context) => _localizedApp(
    title: 'Sushi Tracker',
    home: const LaunchActionController(
      child: ScreenAwakeController(child: RootNavigation()),
    ),
  );
}
