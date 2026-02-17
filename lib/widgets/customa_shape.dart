import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


class CustomShape extends ShapeBorder {
  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return getInnerPath(rect);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final double radius = 24;
    final double curveWidth = rect.width / 4.5; // bump width
    final double curveHeight = 20; // bump height

    Path path = Path();

    // Top left corner
    path.moveTo(rect.left + radius, rect.top);

    path.lineTo(rect.right - radius, rect.top);

    path.arcToPoint(
      Offset(rect.right, rect.top + radius),
      radius: Radius.circular(radius),
    );

    // Right side
    path.lineTo(rect.right, rect.bottom - radius);

    path.arcToPoint(
      Offset(rect.right - radius, rect.bottom),
      radius: Radius.circular(radius),
    );

    // 👉 Move to start of curve
    path.lineTo(rect.center.dx + curveWidth, rect.bottom);

    // 👉 Smooth dome curve (RIGHT SIDE)
    path.cubicTo(
      rect.center.dx + curveWidth * 0.6,
      rect.bottom,
      rect.center.dx + curveWidth * 0.4,
      rect.bottom - curveHeight,
      rect.center.dx,
      rect.bottom - curveHeight,
    );

    // 👉 Smooth dome curve (LEFT SIDE)
    path.cubicTo(
      rect.center.dx - curveWidth * 0.4,
      rect.bottom - curveHeight,
      rect.center.dx - curveWidth * 0.6,
      rect.bottom,
      rect.center.dx - curveWidth,
      rect.bottom,
    );

    // Continue bottom
    path.lineTo(rect.left + radius, rect.bottom);

    path.arcToPoint(
      Offset(rect.left, rect.bottom - radius),
      radius: Radius.circular(radius),
    );

    path.lineTo(rect.left, rect.top + radius);

    path.arcToPoint(
      Offset(rect.left + radius, rect.top),
      radius: Radius.circular(radius),
    );

    path.close();

    return path;
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    canvas.drawPath(
      getOuterPath(rect),
      Paint()
        ..color = Colors.transparent
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  ShapeBorder scale(double t) => this;
}