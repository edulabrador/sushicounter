import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/storage/hive_repository.dart';
import 'core/providers/storage_provider.dart';
import 'core/theme/app_theme.dart';
import 'shared/widgets/bottom_nav.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive
  final hiveRepo = HiveRepository();
  await hiveRepo.init();

  runApp(
    ProviderScope(
      overrides: [
        storageProvider.overrideWithValue(hiveRepo),
      ],
      child: const SushiScoreApp(),
    ),
  );
}

class SushiScoreApp extends StatelessWidget {
  const SushiScoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sushi Score',
      theme: AppTheme.darkTheme,
      home: const RootNavigation(),
      debugShowCheckedModeBanner: false,
    );
  }
}
