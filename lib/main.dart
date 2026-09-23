import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/storage/hive_repository.dart';
import 'core/providers/storage_provider.dart';
import 'core/theme/app_theme.dart';
import 'shared/widgets/bottom_nav.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const StartupApp());
}

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
        return MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.storage_outlined, size: 48),
                    const SizedBox(height: 16),
                    const Text('Could not open your saved data.'),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _retry,
                      child: const Text('Try again'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }
      if (!snapshot.hasData) {
        return MaterialApp(
          theme: AppTheme.darkTheme,
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

class SushiScoreApp extends StatelessWidget {
  const SushiScoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sushi Tracker',
      theme: AppTheme.darkTheme,
      home: const RootNavigation(),
      debugShowCheckedModeBanner: false,
    );
  }
}
