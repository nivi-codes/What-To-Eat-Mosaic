import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

/// "W2E" bottle-cap badge: ink tick edge, chilli ring with
/// "WHAT TO EAT * DECIDE IN 60 SECONDS" around it, tilted W2E in the middle.
class W2ELogo extends StatefulWidget {
  const W2ELogo({super.key, this.size = 160});
  final double size;

  @override
  State<W2ELogo> createState() => _W2ELogoState();
}

class _W2ELogoState extends State<W2ELogo> {
  static final _font = GoogleFonts.courierPrime(fontWeight: FontWeight.w700);

  @override
  void initState() {
    super.initState();
    // Text is painted on a canvas, so repaint once the typewriter font arrives.
    GoogleFonts.pendingFonts([_font]).then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'What To Eat logo',
        child: CustomPaint(size: Size.square(widget.size), painter: _BadgePainter(_font)),
      );
}

class _BadgePainter extends CustomPainter {
  _BadgePainter(this.font);
  final TextStyle font;

  static const _ring = '*WHAT TO EAT * DECIDE IN 60 SECONDS ';

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final c = Offset(r, r);
    final ink = Paint()..color = AppColors.ink;

    // Tick-mark edge.
    const ticks = 64;
    final tickW = r * 0.05, tickIn = r * 0.9;
    for (var i = 0; i < ticks; i++) {
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(2 * pi * i / ticks);
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTRB(-tickW / 2, -r, tickW / 2, -tickIn), Radius.circular(tickW * 0.2)),
        ink,
      );
      canvas.restore();
    }
    canvas.drawCircle(c, r * 0.885, Paint()..color = AppColors.cream);

    // Chilli ring with ink outlines.
    final stroke = r * 0.03;
    canvas.drawCircle(c, r * 0.84, Paint()..color = AppColors.chilli);
    canvas.drawCircle(c, r * 0.84, Paint()
      ..color = AppColors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke);

    // Ring text, clockwise from just below 9 o'clock.
    final textR = r * 0.69;
    final step = 2 * pi / _ring.length;
    final ringStyle = font.copyWith(fontSize: r * 0.13, color: AppColors.cream, height: 1);
    for (var i = 0; i < _ring.length; i++) {
      final ch = _ring[i];
      if (ch == ' ') continue;
      final angle = pi + 0.18 + i * step;
      final tp = TextPainter(text: TextSpan(text: ch, style: ringStyle), textDirection: TextDirection.ltr)..layout();
      canvas.save();
      canvas.translate(c.dx + textR * cos(angle), c.dy + textR * sin(angle));
      canvas.rotate(angle + pi / 2);
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }

    // Cream centre with ink outline and tilted W2E.
    canvas.drawCircle(c, r * 0.53, Paint()..color = AppColors.cream);
    canvas.drawCircle(c, r * 0.53, Paint()
      ..color = AppColors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke);
    final mark = TextPainter(
      text: TextSpan(text: 'W2E', style: font.copyWith(fontSize: r * 0.36, color: AppColors.ink, height: 1, letterSpacing: -r * 0.01)),
      textDirection: TextDirection.ltr,
    )..layout();
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(0.1);
    mark.paint(canvas, Offset(-mark.width / 2, -mark.height / 2));
    canvas.restore();
  }

  @override
  bool shouldRepaint(_BadgePainter old) => true; // cheap; also picks up the late-loading font
}
