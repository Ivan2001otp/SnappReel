import 'dart:math';

import 'package:flutter/material.dart';
import 'package:short_film_app/Constants/color_constant.dart';

class RecordingProgressIndicator extends StatelessWidget {
  final double value;
  final double minValue;
  final double maxValue;

  const RecordingProgressIndicator({
    super.key,
    required this.value,
    this.minValue = 0,
    this.maxValue = 15,
  });

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return CustomPaint(
      painter: RadialGuagePainter(
        maxValue: maxValue,
        minValue: minValue,
        value: value,
      ),
    );
  }
}

class RadialGuagePainter extends CustomPainter {
  final double value;
  final double maxValue;
  final double minValue;

  RadialGuagePainter({
    required this.value,
    required this.minValue,
    required this.maxValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double minSide = min(size.height, size.width); //diameter
    final double centerX = minSide / 2;
    final double centerY = minSide / 2;

    final Offset center = Offset(centerX, centerY);
    final double radius = minSide / 2;
    final double strokeWidth = 5;

    //paint to track the progress the base..
    final Paint progressTrackPaint = Paint()
      ..color = Colors.white.withOpacity(0.9)
      ..colorFilter =
          ColorFilter.mode(Colors.black.withOpacity(0.2), BlendMode.darken)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    //background Gradient;
    final Paint backgroundPaint = Paint()
      ..shader = SweepGradient(
        colors: progressBackgroundColor,
        startAngle: -pi / 2,
        endAngle: 3 * pi / 2,
        tileMode: TileMode.repeated,
      ).createShader(
          Rect.fromCenter(center: center, width: radius, height: radius))
      ..colorFilter = const ColorFilter.mode(Colors.black38, BlendMode.darken)
      ..style = PaintingStyle.fill
      ..strokeWidth = strokeWidth;

    //progress arc
    final Paint progressStrokePaint = Paint()
      ..shader = SweepGradient(
        colors: progressStrokeColor,
        startAngle: -pi / 2,
        endAngle: 3 * pi / 2,
        tileMode: TileMode.repeated,
      ).createShader(
          Rect.fromCenter(center: center, width: radius, height: radius))
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    const double startAngle = -pi / 2;
    final double sweepAngle = 2 * pi * value / maxValue;

    //draw track of progress
    canvas.drawCircle(center, radius + 2, progressTrackPaint);

    //draw gradient arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      true,
      backgroundPaint,
    );

    //draw the progress arc..
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius + 2),
      startAngle,
      sweepAngle,
      false,
      progressStrokePaint,
    );

    //calculate text position
    final double x = centerX + radius * cos(sweepAngle + startAngle);
    final double y = centerY + radius * sin(sweepAngle + startAngle);
    final Offset textCenter = Offset(x, y);
    const double textBorderRadius = 10;

    //Paint for text bg
    Paint textBgPaint = Paint()..color = Colors.black.withOpacity(0.8);

    //textborder
    Paint textBorderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    //draw a line connecting center to the text center
    canvas.drawLine(center, textCenter, textBorderPaint);

    //text bg circle
    canvas.drawCircle(textCenter, textBorderRadius, textBgPaint);

    //border for text bg circle
    canvas.drawCircle(textCenter, textBorderRadius, textBorderPaint);

    //draw the text
    final TextSpan textSpan = TextSpan(
      text: "${(value).toInt()}",
      style: const TextStyle(
        color: Colors.white,
        fontSize: 10.0,
      ),
    );

    final TextPainter textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    textPainter.layout(
      minWidth: 0,
      maxWidth: size.width,
    );

    final Offset textOffset =
        Offset(x - textPainter.width / 2, y - textPainter.height / 2);
    textPainter.paint(canvas, textOffset);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
