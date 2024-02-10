import 'package:flutter/material.dart';

import 'models.dart';

class SvgPainter extends CustomPainter {
  const SvgPainter(this.pathSvgItem, this.onTap);
  final PathSvgItem pathSvgItem;
  final VoidCallback onTap;

  @override
  void paint(Canvas canvas, Size size) {
    Path path = pathSvgItem.path;

    final paint = Paint();
    paint.color = pathSvgItem.fill ?? Colors.white;
    paint.style = PaintingStyle.fill;

    canvas.drawPath(path, paint);
  }

  @override
  bool? hitTest(Offset position) {
    Path path = pathSvgItem.path;
    if (path.contains(position)) {
      onTap();
      return true;
    }
    return super.hitTest(position);
  }

  @override
  bool shouldRepaint(SvgPainter oldDelegate) {
    return pathSvgItem != oldDelegate.pathSvgItem;
  }
}
