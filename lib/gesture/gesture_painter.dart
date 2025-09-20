import 'package:flutter/material.dart';
import 'dart:math';

class GesturePainter extends CustomPainter {
  final List<Offset?> points;
  final bool fitToBox;
  final bool showStartEnd;

  GesturePainter(this.points, {this.fitToBox = false, this.showStartEnd = true});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final paint = Paint()
      ..color = Colors.lightBlue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    final nonNullPoints =
    points.where((p) => p != null).cast<Offset>().toList();
    if (nonNullPoints.isEmpty) return;

    Path path = Path();
    Offset? prevPoint;

    if (fitToBox) {
      final minX = nonNullPoints.map((p) => p.dx).reduce(min);
      final maxX = nonNullPoints.map((p) => p.dx).reduce(max);
      final minY = nonNullPoints.map((p) => p.dy).reduce(min);
      final maxY = nonNullPoints.map((p) => p.dy).reduce(max);

      final width = maxX - minX;
      final height = maxY - minY;
      if (width == 0 || height == 0) return;

      final scaleX = size.width / width;
      final scaleY = size.height / height;
      final scale = min(scaleX, scaleY) * 0.9;

      final dx = (size.width - width * scale) / 2;
      final dy = (size.height - height * scale) / 2;

      for (var point in points) {
        if (point != null) {
          final scaled = Offset(
            (point.dx - minX) * scale + dx,
            (point.dy - minY) * scale + dy,
          );

          if (prevPoint == null) {
            path.moveTo(scaled.dx, scaled.dy);
          } else {
            path.quadraticBezierTo(
              prevPoint.dx,
              prevPoint.dy,
              (prevPoint.dx + scaled.dx) / 2,
              (prevPoint.dy + scaled.dy) / 2,
            );
          }
          prevPoint = scaled;
        } else {
          prevPoint = null;
        }
      }
    } else {
      for (var point in points) {
        if (point != null) {
          if (prevPoint == null) {
            path.moveTo(point.dx, point.dy);
          } else {
            path.quadraticBezierTo(
              prevPoint.dx,
              prevPoint.dy,
              (prevPoint.dx + point.dx) / 2,
              (prevPoint.dy + point.dy) / 2,
            );
          }
          prevPoint = point;
        } else {
          prevPoint = null;
        }
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(GesturePainter oldDelegate) => true;
}


