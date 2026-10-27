import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/platform/home_widget.dart';
import '../../features/counter/providers/counter_provider.dart';

/// Keeps the home screen widget's count in step with the counter. Quick
/// taps are batched into one update, and the latest count is always sent
/// when the app goes to the background.
class HomeWidgetSync extends ConsumerStatefulWidget {
  const HomeWidgetSync({required this.child, super.key});

  final Widget child;

  /// How long taps are batched before the widget is told.
  static const delay = Duration(milliseconds: 400);

  @override
  ConsumerState<HomeWidgetSync> createState() => _HomeWidgetSyncState();
}

class _HomeWidgetSyncState extends ConsumerState<HomeWidgetSync>
    with WidgetsBindingObserver {
  late final Future<void> Function(int) _update;
  late final ProviderSubscription<int> _subscription;
  Timer? _timer;
  int? _sent;
  int _latest = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _update = ref.read(homeWidgetProvider);
    _subscription = ref.listenManual<int>(
      counterProvider.select((state) => state.count),
      (_, next) {
        _latest = next;
        _timer?.cancel();
        _timer = Timer(HomeWidgetSync.delay, _flush);
      },
      fireImmediately: true,
    );
    _flush();
  }

  void _flush() {
    _timer?.cancel();
    _timer = null;
    if (_sent == _latest) return;
    _sent = _latest;
    _update(_latest);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _flush();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _subscription.close();
    _flush();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
