import 'dart:ui' as ui;
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FingerPainterScreen extends StatefulWidget {
  const FingerPainterScreen({super.key});

  @override
  State<FingerPainterScreen> createState() => _FingerPainterScreenState();
}

class _FingerPainterScreenState extends State<FingerPainterScreen> {
  final List<LineObject> lines = [];
  ui.FragmentProgram? _program;
  ui.Image? _brushTexture;

  Future<void> _loadMyShader() async {
    final fragment = await ui.FragmentProgram.fromAsset('assets/shaders/simple_shader.frag');
    setState(() {
      _program = fragment;
    });
  }

  Future<void> _loadBrushTexture() async {
    // Load the brush texture
    final ByteData data = await rootBundle.load('assets/images/texture.png');
    final Uint8List bytes = data.buffer.asUint8List();
    final ui.Codec codec = await ui.instantiateImageCodec(bytes);
    final ui.FrameInfo fi = await codec.getNextFrame();

    // Redraw if the image is loaded
    setState(() {
      _brushTexture = fi.image;
    });
  }

  @override
  void initState() {
    _loadMyShader();
    _loadBrushTexture();
    super.initState();
  }

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
      body: _program == null || _brushTexture == null
          ? const Center(child: CircularProgressIndicator())
          : GestureDetector(
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
                painter: FingerPainter(
                  lines: lines,
                  program: _program!,
                  brushTexture: _brushTexture!,
                ),
              ),
            ),
    );
  }
}

class FingerPainter extends CustomPainter {
  final List<LineObject> lines;
  final ui.FragmentProgram program;
  final ui.Image brushTexture;
  FingerPainter({
    required this.lines,
    required this.program,
    required this.brushTexture,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (int index = 0; index < lines.length; index++) {
      final line = lines[index];
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..color = line.color
        ..strokeWidth = 20
        ..strokeCap = StrokeCap.round;

      // final path = Path();
      // path.moveTo(line.points.first.dx, line.points.first.dy);
      // for (var i = 1; i < line.points.length; i++) {
      //   path.lineTo(line.points[i].dx, line.points[i].dy);
      // }
      // canvas.drawPath(path, paint);

      for (var i = 0; i < line.points.length - 1; i++) {
        final angle = (line.points[i + 1] - line.points[i]).direction;
        final shader = program.fragmentShader();

        // color
        final color = line.color;
        shader.setFloat(0, color.red / 255);
        shader.setFloat(1, color.green / 255);
        shader.setFloat(2, color.blue / 255);
        shader.setFloat(3, color.alpha / 255);

        // size
        shader.setFloat(4, 4000);
        shader.setFloat(5, 4000);

        // angle
        shader.setFloat(6, angle * 180 / math.pi + 90);

        // const scale = 0.7;

        // // scale X
        // shader.setFloat(7, scale);

        // // scale Y
        // shader.setFloat(8, scale);

        // // point start
        // shader.setFloat(6, line.points[i].dx);
        // shader.setFloat(7, line.points[i].dy);

        // // point end
        // shader.setFloat(8, line.points[i + 1].dx);
        // shader.setFloat(9, line.points[i + 1].dy);

        // texture
        shader.setImageSampler(0, brushTexture);
        paint.shader = shader;
        // final matrix = Matrix4.identity();
        // // matrix.translate(line.points[i].dx, line.points[i].dy);
        // matrix.rotateZ((line.points[i + 1] - line.points[i]).direction);
        // matrix.scale(0.1, 0.1);
        // // matrix.scale(0.8, 0.2);

        // paint.shader = ImageShader(
        //   brushTexture,
        //   TileMode.repeated,
        //   TileMode.repeated,
        //   matrix.storage,
        //   filterQuality: FilterQuality.low,
        // );
        // paint.colorFilter = ui.ColorFilter.mode(line.color, ui.BlendMode.srcATop);
        canvas.drawLine(line.points[i], line.points[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(FingerPainter oldDelegate) => true;
}

class LineObject {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;

  const LineObject({
    required this.points,
    this.color = Colors.red,
    this.strokeWidth = 3.0,
  });
}
