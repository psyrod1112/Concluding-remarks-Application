import 'package:flutter/material.dart';

class AppBackground extends StatelessWidget {
  final Widget child;

  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [
                  Color(0xFF0B1020),
                  Color(0xFF111827),
                  Color(0xFF1A1744),
                ]
              : const [
                  Color(0xFFF8FAFF),
                  Color(0xFFF1F5FF),
                  Color(0xFFF7F3FF),
                ],
        ),
      ),
      child: CustomPaint(
        painter: _WordPatternPainter(isDark: isDark),
        child: SizedBox.expand(child: child),
      ),
    );
  }
}

class _WordPatternPainter extends CustomPainter {
  final bool isDark;

  _WordPatternPainter({required this.isDark});

  static const List<_PatternText> _texts = [
    _PatternText('가', Offset(0.07, 0.16), -0.20, 44),
    _PatternText('나', Offset(0.11, 0.82), 0.16, 36),
    _PatternText('다', Offset(0.86, 0.14), -0.16, 38),
    _PatternText('라', Offset(0.92, 0.58), 0.18, 34),
    _PatternText('마', Offset(0.09, 0.58), -0.18, 34),
    _PatternText('바', Offset(0.83, 0.82), -0.12, 34),
    _PatternText('사', Offset(0.30, 0.12), 0.10, 24),
    _PatternText('자', Offset(0.95, 0.30), 0.14, 30),
    _PatternText('ㅎ', Offset(0.18, 0.30), -0.10, 26),
    _PatternText('ㄴ', Offset(0.72, 0.08), 0.22, 22),
  ];

  static const List<Offset> _points = [
    Offset(0.15, 0.25),
    Offset(0.36, 0.17),
    Offset(0.55, 0.27),
    Offset(0.78, 0.22),
    Offset(0.88, 0.48),
    Offset(0.22, 0.72),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final patternColor = isDark
        ? Colors.white.withOpacity(0.040)
        : const Color(0xFF5B6FD6).withOpacity(0.070);
    final lineColor = isDark
        ? Colors.white.withOpacity(0.032)
        : const Color(0xFF5B6FD6).withOpacity(0.048);
    final dotFillColor = isDark
        ? Colors.white.withOpacity(0.028)
        : const Color(0xFF7C8CF0).withOpacity(0.045);

    _drawSoftGlow(canvas, size, isDark);
    _drawWordChain(canvas, size, lineColor);
    _drawDots(canvas, size, lineColor, dotFillColor);
    _drawPatternTexts(canvas, size, patternColor);
  }

  void _drawSoftGlow(Canvas canvas, Size size, bool isDark) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: isDark
            ? [
                const Color(0xFF5B6FD6).withOpacity(0.10),
                Colors.transparent,
              ]
            : [
                const Color(0xFF93C5FD).withOpacity(0.22),
                Colors.transparent,
              ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.50, size.height * 0.35),
          radius: size.shortestSide * 0.62,
        ),
      );

    canvas.drawCircle(
      Offset(size.width * 0.50, size.height * 0.35),
      size.shortestSide * 0.62,
      paint,
    );
  }

  void _drawWordChain(Canvas canvas, Size size, Color lineColor) {
    final paint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(size.width * 0.08, size.height * 0.33)
      ..cubicTo(
        size.width * 0.24,
        size.height * 0.20,
        size.width * 0.38,
        size.height * 0.22,
        size.width * 0.50,
        size.height * 0.32,
      )
      ..cubicTo(
        size.width * 0.64,
        size.height * 0.43,
        size.width * 0.76,
        size.height * 0.33,
        size.width * 0.92,
        size.height * 0.24,
      );

    _drawDashedPath(canvas, path, paint);
  }

  void _drawDots(Canvas canvas, Size size, Color lineColor, Color fillColor) {
    final outlinePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;
    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    for (final point in _points) {
      final center = Offset(size.width * point.dx, size.height * point.dy);
      canvas.drawCircle(center, 4, fillPaint);
      canvas.drawCircle(center, 13, outlinePaint);
    }
  }

  void _drawPatternTexts(Canvas canvas, Size size, Color color) {
    for (final item in _texts) {
      final painter = TextPainter(
        text: TextSpan(
          text: item.text,
          style: TextStyle(
            fontSize: item.fontSize,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final offset = Offset(
        size.width * item.position.dx,
        size.height * item.position.dy,
      );

      canvas.save();
      canvas.translate(offset.dx, offset.dy);
      canvas.rotate(item.rotation);
      painter.paint(canvas, Offset(-painter.width / 2, -painter.height / 2));
      canvas.restore();
    }
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    const dashWidth = 8.0;
    const dashSpace = 9.0;

    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final segment = metric.extractPath(distance, distance + dashWidth);
        canvas.drawPath(segment, paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WordPatternPainter oldDelegate) {
    return oldDelegate.isDark != isDark;
  }
}

class _PatternText {
  final String text;
  final Offset position;
  final double rotation;
  final double fontSize;

  const _PatternText(this.text, this.position, this.rotation, this.fontSize);
}
