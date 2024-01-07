import 'package:flutter/material.dart';

class SimpleCanvasScreen extends StatelessWidget {
  const SimpleCanvasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomPaint(
        size: MediaQuery.sizeOf(context),
        painter: const MyPainter(),
      ),
    );
  }
}

class MyPainter extends CustomPainter {
  const MyPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final TextPainter textPainter = TextPainter(
      text: const TextSpan(
        text: 'Hello, world!',
        style: TextStyle(
          color: Colors.black,
          fontSize: 30,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    final Offset offset = Offset(
      size.width / 2 - textPainter.width / 2,
      size.height / 2 - textPainter.height / 2,
    );
    textPainter.paint(canvas, offset);

    final Paint paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke;

    canvas.drawRect(
      Rect.fromLTWH(
        100,
        100,
        size.width / 4,
        size.height / 4,
      ),
      paint,
    );

    final Paint paint2 = Paint()
      ..color = Colors.blue
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 100, paint2);

    final Paint paint3 = Paint()
      ..color = Colors.green
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke;

    canvas.drawLine(const Offset(0, 0), Offset(size.width, size.height), paint3);
  }

  @override
  bool shouldRepaint(MyPainter oldDelegate) => true;
}
