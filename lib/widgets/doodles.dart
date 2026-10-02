import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../theme/app_theme.dart';

/// Line-art food doodles from the moodboard (assets/doodles), each on its offset colour blob.
class Doodles {
  static const names = [
    'dosa', 'idli', 'biryani', 'naan', 'jalebi', 'gulab_jamun',
    'paneer_tikka', 'paratha', 'pav', 'vada_pav', 'lassi', 'coconut_water',
    'pineapple', 'watermelon', 'banana', 'orange', 'strawberry', 'lemon',
    'tomato', 'carrot', 'corn', 'broccoli', 'brinjal', 'onion',
    'fried_egg', 'chicken_leg', 'dal', 'pizza', 'noodles', 'ice_cream',
    'samosa', 'chai', 'chilli', 'mango', 'avocado', 'momo',
  ];

  static String asset(String name) => 'assets/doodles/$name.png';

  /// Loads every doodle up front so the wallpaper and loaders never pop in.
  static void precache(BuildContext context) {
    for (final n in names) {
      precacheImage(AssetImage(asset(n)), context);
    }
  }
}

/// Precaches all doodles once the app has a context (wrap the app with it).
class DoodlePrecacher extends StatefulWidget {
  const DoodlePrecacher({super.key, required this.child});
  final Widget child;

  @override
  State<DoodlePrecacher> createState() => _DoodlePrecacherState();
}

class _DoodlePrecacherState extends State<DoodlePrecacher> {
  bool _done = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_done) return;
    _done = true;
    Doodles.precache(context);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Scattered doodles behind a page, like a wallpaper. Layout is seeded, so it
/// stays put across rebuilds.
class DoodleWallpaper extends StatelessWidget {
  const DoodleWallpaper({super.key, this.opacity = 0.3, this.seed = 7});

  final double opacity;
  final int seed;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: LayoutBuilder(builder: (context, c) {
          final rng = Random(seed);
          const cellW = 108.0, cellH = 118.0;
          final cols = (c.maxWidth / cellW).ceil() + 1;
          final rows = (c.maxHeight / cellH).ceil() + 1;
          final order = [...Doodles.names]..shuffle(rng);
          final children = <Widget>[];
          var i = 0;
          for (var r = 0; r < rows; r++) {
            for (var col = 0; col < cols; col++) {
              final size = 50.0 + rng.nextDouble() * 18;
              // Offset alternate rows so the pattern doesn't read as a grid.
              final x = col * cellW + (r.isOdd ? cellW / 2 : 0) + rng.nextDouble() * 22 - 11 - size / 2;
              final y = r * cellH + rng.nextDouble() * 26 - 13;
              children.add(Positioned(
                left: x,
                top: y,
                child: Transform.rotate(
                  angle: (rng.nextDouble() - 0.5) * 0.45,
                  child: Image.asset(Doodles.asset(order[i++ % order.length]), width: size, height: size),
                ),
              ));
              // A few sparkles between doodles, as on the moodboard.
              if (rng.nextDouble() < 0.28) {
                children.add(Positioned(
                  left: x + size + 8 + rng.nextDouble() * 14,
                  top: y + rng.nextDouble() * 30,
                  child: Sparkle(
                    size: 14 + rng.nextDouble() * 6,
                    color: AppColors.blobs[rng.nextInt(AppColors.blobs.length)],
                  ),
                ));
              }
            }
          }
          return Opacity(opacity: opacity, child: Stack(clipBehavior: Clip.hardEdge, children: children));
        }),
      ),
    );
  }
}

/// Four-point sparkle with an ink outline, from the moodboard.
class Sparkle extends StatelessWidget {
  const Sparkle({super.key, required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => CustomPaint(size: Size.square(size), painter: _SparklePainter(color));
}

class _SparklePainter extends CustomPainter {
  _SparklePainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size s) {
    final c = s.center(Offset.zero);
    final r = s.width / 2, k = r * 0.22;
    final path = Path()
      ..moveTo(c.dx, c.dy - r)
      ..quadraticBezierTo(c.dx + k, c.dy - k, c.dx + r, c.dy)
      ..quadraticBezierTo(c.dx + k, c.dy + k, c.dx, c.dy + r)
      ..quadraticBezierTo(c.dx - k, c.dy + k, c.dx - r, c.dy)
      ..quadraticBezierTo(c.dx - k, c.dy - k, c.dx, c.dy - r)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(1.2, s.width / 12)
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_SparklePainter old) => old.color != color;
}

/// Loading animation: random doodles parade across the screen from left to
/// right along a wave, a new one joining every so often.
class DoodleLoader extends StatefulWidget {
  const DoodleLoader({
    super.key,
    this.title,
    this.subtitle,
    this.height = 150,
    this.doodleSize = 64,
    this.compact = false,
  });

  /// Small inline version (e.g. "Understanding…" under an input).
  const DoodleLoader.compact({super.key, this.title})
      : subtitle = null,
        height = 64,
        doodleSize = 34,
        compact = true;

  final String? title;
  final String? subtitle;
  final double height;
  final double doodleSize;
  final bool compact;

  @override
  State<DoodleLoader> createState() => _DoodleLoaderState();
}

class _Traveller {
  _Traveller(this.name, this.start, this.size, this.spin);
  final String name;
  final double start; // seconds
  final double size;
  final double spin;
}

class _DoodleLoaderState extends State<DoodleLoader> with SingleTickerProviderStateMixin {
  static const _travelSeconds = 4.6; // time to cross the screen
  static const _spacingSeconds = 0.95; // a new doodle joins this often
  final _rng = Random();
  final _travellers = <_Traveller>[];
  final _recent = <String>[];
  late final Ticker _ticker;
  double _now = 0;
  double _nextSpawn = 0;

  String _pickName() {
    String n;
    do {
      n = Doodles.names[_rng.nextInt(Doodles.names.length)];
    } while (_recent.contains(n));
    _recent.add(n);
    if (_recent.length > 8) _recent.removeAt(0);
    return n;
  }

  void _spawn(double at) => _travellers.add(_Traveller(
        _pickName(),
        at,
        widget.doodleSize * (0.85 + _rng.nextDouble() * 0.3),
        (_rng.nextDouble() - 0.5) * 0.6,
      ));

  @override
  void initState() {
    super.initState();
    // Start mid-parade so the band is never empty on the first frame.
    for (var t = -_travelSeconds + _spacingSeconds; t <= 0; t += _spacingSeconds) {
      _spawn(t);
    }
    _nextSpawn = _spacingSeconds;
    _ticker = createTicker((elapsed) {
      _now = elapsed.inMicroseconds / 1e6;
      if (_now >= _nextSpawn) {
        _spawn(_nextSpawn);
        _nextSpawn += _spacingSeconds;
      }
      _travellers.removeWhere((t) => _now - t.start > _travelSeconds);
      setState(() {});
    })..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final band = SizedBox(
      height: widget.height,
      child: LayoutBuilder(builder: (context, c) {
        final w = c.maxWidth;
        final mid = widget.height / 2;
        final amp = widget.height * 0.22;
        final children = <Widget>[];
        for (final t in _travellers) {
          final p = reduceMotion ? 0.5 : (_now - t.start) / _travelSeconds; // 0 -> 1 across
          final x = -t.size + p * (w + t.size);
          final phase = 2 * pi * 1.5 * p;
          final y = mid + amp * sin(phase) - t.size / 2;
          // Tilt with the slope of the wave, plus a little personal spin.
          final tilt = atan(amp * 2 * pi * 1.5 / (w + t.size) * cos(phase)) * 0.8 + t.spin * sin(phase * 0.5);
          children.add(Positioned(
            left: x,
            top: y,
            child: Transform.rotate(
              angle: tilt,
              child: Image.asset(Doodles.asset(t.name), width: t.size, height: t.size),
            ),
          ));
        }
        return ClipRect(child: Stack(clipBehavior: Clip.none, children: children));
      }),
    );

    if (widget.compact) {
      return Column(mainAxisSize: MainAxisSize.min, children: [
        band,
        if (widget.title != null)
          Text(widget.title!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.ink, fontWeight: FontWeight.w600)),
      ]);
    }
    return Column(mainAxisSize: MainAxisSize.min, children: [
      band,
      if (widget.title != null) ...[
        const SizedBox(height: 18),
        Text(widget.title!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.4)),
      ],
      if (widget.subtitle != null) ...[
        const SizedBox(height: 6),
        Text(widget.subtitle!,
            textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted)),
      ],
    ]);
  }
}
