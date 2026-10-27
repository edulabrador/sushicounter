import 'package:flutter/material.dart';

import '../../features/counter/views/counter_view.dart';
import '../../features/history/views/history_view.dart';
import '../../features/stats/views/stats_view.dart';
import '../../l10n/l10n.dart';

class RootNavigation extends StatefulWidget {
  const RootNavigation({super.key});

  /// A side rail instead of the bottom bar on tablets and on phones held
  /// sideways, where height is the scarce dimension.
  static bool useRail(Size size) =>
      size.width >= 840 || (size.width >= 600 && size.height < 500);

  @override
  State<RootNavigation> createState() => _RootNavigationState();
}

class _RootNavigationState extends State<RootNavigation> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [CounterView(), HistoryView(), StatsView()];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final destinations = [
      (Icons.touch_app, l10n.navCounter),
      (Icons.history, l10n.navHistory),
      (Icons.bar_chart, l10n.navStats),
    ];
    void select(int index) => setState(() => _currentIndex = index);
    final pages = IndexedStack(index: _currentIndex, children: _pages);
    if (RootNavigation.useRail(MediaQuery.sizeOf(context))) {
      return Scaffold(
        body: Row(
          children: [
            SafeArea(
              right: false,
              child: NavigationRail(
                selectedIndex: _currentIndex,
                onDestinationSelected: select,
                labelType: NavigationRailLabelType.all,
                groupAlignment: 0,
                destinations: [
                  for (final (icon, label) in destinations)
                    NavigationRailDestination(
                      icon: Icon(icon),
                      label: Text(label),
                    ),
                ],
              ),
            ),
            const VerticalDivider(width: 1),
            // The rail covers the left edge; keep pages clear of the rest.
            Expanded(child: SafeArea(left: false, top: false, child: pages)),
          ],
        ),
      );
    }
    return Scaffold(
      body: pages,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: select,
        destinations: [
          for (final (icon, label) in destinations)
            NavigationDestination(icon: Icon(icon), label: label),
        ],
      ),
    );
  }
}
