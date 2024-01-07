import 'package:flutter/material.dart';

class FingerCustomPainterScreen extends StatefulWidget {
  const FingerCustomPainterScreen({super.key});

  @override
  State<FingerCustomPainterScreen> createState() => _FingerCustomPainterScreenState();
}

class _FingerCustomPainterScreenState extends State<FingerCustomPainterScreen> {
  final List<LineObject> lines = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            lines.clear();
          });
        },
        child: const Icon(Icons.clear),
      ),
      body: GestureDetector(
        onPanStart: (details) {
          setState(() {
            lines.add(LineObject(points: [details.localPosition]));
          });
        },
        onPanUpdate: (details) {
          setState(() {
            lines.last.points.add(details.localPosition);
          });
        },
        child: CustomPaint(
          size: MediaQuery.sizeOf(context),
          painter: FingerCustomPainter(lines: lines),
        ),
      ),
    );
  }
}

class FingerCustomPainter extends CustomPainter {
  final List<LineObject> lines;
  FingerCustomPainter({required this.lines});

  @override
  void paint(Canvas canvas, Size size) {
    for (final line in lines) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..color = line.color
        ..strokeWidth = 20
        ..strokeCap = StrokeCap.round;

      final path = Path();
      path.moveTo(line.points.first.dx, line.points.first.dy);
      for (var i = 1; i < line.points.length; i++) {
        path.lineTo(line.points[i].dx, line.points[i].dy);
      }
      canvas.drawPath(path, paint);

      for (var i = 0; i < line.points.length - 1; i++) {
        canvas.drawLine(line.points[i], line.points[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(FingerCustomPainter oldDelegate) => true;
}

class LineObject {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;

  const LineObject({
    required this.points,
    this.color = Colors.black,
    this.strokeWidth = 3.0,
  });
}
