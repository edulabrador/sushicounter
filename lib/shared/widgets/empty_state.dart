import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../art/sushi_art.dart';

/// A sleepy nigiri with a message, for screens with nothing to show yet.
class EmptyState extends StatelessWidget {
  const EmptyState({required this.title, this.hint, super.key});

  final String title;
  final String? hint;

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SushiArt(size: 132, mood: SushiMood.sleepy),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (hint != null) ...[
            const SizedBox(height: 6),
            Text(
              hint!,
              textAlign: TextAlign.center,
              style: TextStyle(color: context.colors.textMuted),
            ),
          ],
        ],
      ),
    ),
  );
}
