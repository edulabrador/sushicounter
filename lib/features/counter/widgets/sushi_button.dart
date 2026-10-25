import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/art/sushi_art.dart';

/// A tappable kawaii salmon-nigiri character.
///
/// Recreated in vector (CustomPaint) rather than embedding a bitmap so it
/// scales crisply at any size and carries no asset weight. Each tap fires a
/// little jump-and-flip animation, a burst of fireworks and a rising "+1".
/// The tap that beats [record] sets off a bigger golden burst, a "New
/// record!" badge and a strong vibration.
class SushiButton extends StatefulWidget {
  const SushiButton({
    super.key,
    required this.onTap,
    required this.onLongPress,
    this.size = 200,
    this.enabled = true,
    this.mood = SushiMood.happy,
    this.count = 0,
    this.record = 0,
  });

  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final double size;
  final bool enabled;

  /// The face it pulls; starry while the session beats the record.
  final SushiMood mood;

  /// The session's count and the best saved session, to celebrate the moment
  /// the count first goes past the record.
  final int count;
  final int record;

  @override
  State<SushiButton> createState() => _SushiButtonState();
}

class _SushiButtonState extends State<SushiButton>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final AnimationController _celebration;
  final List<AnimationController> _floaters = [];
  List<_Spark> _bigSparks = const [];
  final FocusNode _focusNode = FocusNode(debugLabel: 'Sushi counter button');
  final math.Random _rnd = math.Random();
  List<_Spark> _sparks = const [];
  bool _showFocus = false;

  static const _sparkColors = [
    Color(0xFFFF6B6B), // red
    Color(0xFFFFD93D), // yellow
    Color(0xFFFF9F43), // orange
    Color(0xFF6BCB77), // green
    Color(0xFF4D96FF), // blue
    Color(0xFFB983FF), // purple
    Color(0xFFFF7BAC), // pink
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _celebration = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
  }

  @override
  void didUpdateWidget(SushiButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    final record = widget.record;
    if (record > 0 && oldWidget.count <= record && widget.count == record + 1) {
      _celebrate();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _celebration.dispose();
    for (final floater in _floaters) {
      floater.dispose();
    }
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context) && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 0;
      _sparks = const [];
    }
  }

  void _spawnSparks() {
    const count = 16;
    _sparks = List.generate(count, (i) {
      final angle = (i / count) * 2 * math.pi + _rnd.nextDouble() * 0.4;
      final distance = widget.size * (0.48 + _rnd.nextDouble() * 0.38);
      final radius = widget.size * (0.012 + _rnd.nextDouble() * 0.02);
      final color = _sparkColors[_rnd.nextInt(_sparkColors.length)];
      return _Spark(
        angle: angle,
        distance: distance,
        radius: radius,
        color: color,
      );
    });
  }

  void _handleTap() {
    if (!widget.enabled) return;
    widget.onTap();
    // Lets the user count without looking at the screen.
    HapticFeedback.lightImpact();
    // Honour the platform's accessibility preference. The counter still works;
    // only the non-essential celebratory motion is skipped.
    if (MediaQuery.disableAnimationsOf(context)) return;
    _spawnSparks();
    // Replay from the start on every tap, even mid-flight, so rapid tapping
    // keeps hopping and sparking.
    _controller.forward(from: 0);
    _float();
  }

  /// A "+1" that rises and fades; several can be in the air at once.
  void _float() {
    final floater = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
    floater.addStatusListener((status) {
      if (status != AnimationStatus.completed || !mounted) return;
      setState(() => _floaters.remove(floater));
      floater.dispose();
    });
    setState(() => _floaters.add(floater));
    floater.forward();
  }

  void _celebrate() {
    HapticFeedback.heavyImpact();
    const count = 36;
    _bigSparks = List.generate(count, (i) {
      final angle = (i / count) * 2 * math.pi + _rnd.nextDouble() * 0.3;
      return _Spark(
        angle: angle,
        distance: widget.size * (0.7 + _rnd.nextDouble() * 0.5),
        radius: widget.size * (0.016 + _rnd.nextDouble() * 0.022),
        color: _goldColors[_rnd.nextInt(_goldColors.length)],
      );
    });
    // With reduced motion only the badge shows, without the burst.
    if (MediaQuery.disableAnimationsOf(context)) _bigSparks = const [];
    _celebration.forward(from: 0);
  }

  static const _goldColors = [
    Color(0xFFFFD93D),
    Color(0xFFFFC107),
    Color(0xFFF7A072),
    Color(0xFFFFF3B0),
  ];

  void _handleLongPress() {
    if (!widget.enabled) return;
    widget.onLongPress();
    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Semantics(
      button: true,
      excludeSemantics: true,
      enabled: widget.enabled,
      label: l10n.sushiButtonLabel,
      hint: l10n.sushiButtonHint,
      onTap: widget.enabled ? _handleTap : null,
      onLongPress: widget.enabled ? _handleLongPress : null,
      child: FocusableActionDetector(
        focusNode: _focusNode,
        enabled: widget.enabled,
        mouseCursor: widget.enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.forbidden,
        shortcuts: const <ShortcutActivator, Intent>{
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        },
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              _handleTap();
              return null;
            },
          ),
        },
        onShowFocusHighlight: (showFocus) =>
            setState(() => _showFocus = showFocus),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.size / 2),
            border: _showFocus
                ? Border.all(color: context.colors.text, width: 3)
                : null,
          ),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.enabled
                ? () {
                    _focusNode.requestFocus();
                    _handleTap();
                  }
                : null,
            onLongPress: widget.enabled ? _handleLongPress : null,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final v = _controller.value;
                // Parabolic hop: 0 -> up -> 0.
                final jump = -math.sin(math.pi * v) * (widget.size * 0.18);
                // One full somersault over the hop.
                final spin = v * 2 * math.pi;
                // A touch of squash-and-stretch for bounce.
                final scale = 1 + math.sin(math.pi * v) * 0.06;
                return SizedBox(
                  width: widget.size,
                  height: widget.size,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      // Fireworks burst radiating from behind the sushi.
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _FireworksPainter(v, _sparks),
                        ),
                      ),
                      Positioned.fill(
                        child: AnimatedBuilder(
                          animation: _celebration,
                          builder: (context, _) => CustomPaint(
                            painter: _FireworksPainter(
                              _celebration.value,
                              _bigSparks,
                            ),
                          ),
                        ),
                      ),
                      Transform.translate(
                        offset: Offset(0, jump),
                        child: Transform.rotate(
                          angle: spin,
                          child: Transform.scale(scale: scale, child: child),
                        ),
                      ),
                      for (final floater in _floaters)
                        _PlusOne(animation: floater, size: widget.size),
                      _RecordBadge(
                        animation: _celebration,
                        size: widget.size,
                        label: l10n.recordBurst,
                      ),
                    ],
                  ),
                );
              },
              child: SizedBox(
                width: widget.size,
                height: widget.size,
                child: CustomPaint(painter: NigiriPainter(mood: widget.mood)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// "+1" rising from the top of the nigiri.
class _PlusOne extends StatelessWidget {
  const _PlusOne({required this.animation, required this.size});

  final Animation<double> animation;
  final double size;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final v = Curves.easeOut.transform(animation.value);
        return Positioned(
          top: -size * 0.05 - v * size * 0.3,
          child: Opacity(
            opacity: (1 - animation.value).clamp(0, 1),
            child: child,
          ),
        );
      },
      child: ExcludeSemantics(
        child: Text(
          '+1',
          style: TextStyle(
            color: context.colors.accent,
            fontSize: size * 0.14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

/// "New record!" popping above the nigiri, then fading.
class _RecordBadge extends StatelessWidget {
  const _RecordBadge({
    required this.animation,
    required this.size,
    required this.label,
  });

  final Animation<double> animation;
  final double size;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final v = animation.value;
        if (animation.status != AnimationStatus.forward) {
          return const SizedBox.shrink();
        }
        final pop = Curves.elasticOut.transform((v / 0.3).clamp(0, 1));
        final fade = v < 0.8 ? 1.0 : (1 - (v - 0.8) / 0.2);
        return Positioned(
          top: -size * 0.32,
          child: Opacity(
            opacity: fade.clamp(0, 1),
            child: Transform.scale(scale: 0.6 + 0.4 * pop, child: child),
          ),
        );
      },
      child: Semantics(
        liveRegion: true,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.accent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star_rounded, size: 18, color: colors.onAccent),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: colors.onAccent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A single firework particle.
class _Spark {
  const _Spark({
    required this.angle,
    required this.distance,
    required this.radius,
    required this.color,
  });

  final double angle;
  final double distance;
  final double radius;
  final Color color;
}

class _FireworksPainter extends CustomPainter {
  _FireworksPainter(this.progress, this.sparks);

  final double progress;
  final List<_Spark> sparks;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1 || sparks.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final eased = Curves.easeOut.transform(progress);
    final fade = (1 - Curves.easeIn.transform(progress)).clamp(0.0, 1.0);
    final gravity = size.height * 0.22 * progress * progress;

    for (final s in sparks) {
      final dx = math.cos(s.angle) * s.distance * eased;
      final dy = math.sin(s.angle) * s.distance * eased + gravity;
      final pos = center + Offset(dx, dy);
      final tail = Offset.lerp(center, pos, 0.72)!;

      // Streak trailing the spark.
      canvas.drawLine(
        tail,
        pos,
        Paint()
          ..color = s.color.withAlpha((fade * 130).round())
          ..strokeWidth = s.radius * 0.9
          ..strokeCap = StrokeCap.round,
      );
      // The spark head.
      canvas.drawCircle(
        pos,
        s.radius * (1 - progress * 0.35),
        Paint()..color = s.color.withAlpha((fade * 255).round()),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FireworksPainter old) =>
      old.progress != progress || old.sparks != sparks;
}
