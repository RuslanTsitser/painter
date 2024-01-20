import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class FingerPainterScreen extends StatefulWidget {
  const FingerPainterScreen({super.key});

  @override
  State<FingerPainterScreen> createState() => _FingerPainterScreenState();
}

class _FingerPainterScreenState extends State<FingerPainterScreen> {
  final List<LineObject> lines = [];

  void _onClearLines() {
    setState(() {
      lines.clear();
      _image = null;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      lines.last = lines.last.copyWith(
        points: [...lines.last.points, details.localPosition],
      );
    });
  }

  void _onPanStart(DragStartDetails details) {
    setState(() {
      lines.add(
        LineObject(
          color: _currentColor,
          points: [details.localPosition],
        ),
      );
    });
  }

  Color get _currentColor => _eraserModeEnabled ? Theme.of(context).scaffoldBackgroundColor : Colors.red;
  bool _eraserModeEnabled = false;
  void _onToggleEraser(bool value) {
    setState(() {
      _eraserModeEnabled = value;
    });
  }

  final _repaintKey = GlobalKey();
  ui.Image? _image;
  void _capturePng() {
    final boundary = _repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = boundary.toImageSync(pixelRatio: 1.0);
    setState(() {
      _image = image;
    });
  }

  ui.FragmentProgram? _program;
  Future<void> _loadMyShader() async {
    final fragmentProgram = await ui.FragmentProgram.fromAsset('assets/shaders/simple_shader.frag');
    setState(() {
      _program = fragmentProgram;
    });
  }

  Future<void> _onPanEnd(DragEndDetails details) async {
    if (_program == null) {
      await _loadMyShader();
    }
    _capturePng();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _onClearLines,
        child: const Icon(Icons.clear),
      ),
      bottomNavigationBar: SafeArea(
        child: ListTile(
          title: const Text('Eraser enabled'),
          trailing: Switch(
            value: _eraserModeEnabled,
            onChanged: _onToggleEraser,
          ),
        ),
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        child: RepaintBoundary(
          key: _repaintKey,
          child: Stack(
            children: [
              if (_image != null && _program != null)
                CustomPaint(
                  size: MediaQuery.sizeOf(context),
                  painter: ImagePainter(
                    image: _image!,
                    program: _program!,
                  ),
                ),
              if (lines.isNotEmpty)
                RepaintBoundary(
                  child: CustomPaint(
                    size: MediaQuery.sizeOf(context),
                    painter: FingerPainter(
                      line: lines.last,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class FingerPainter extends CustomPainter {
  final LineObject line;
  const FingerPainter({
    required this.line,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..color = line.color
      ..strokeWidth = line.strokeWidth
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < line.points.length - 1; i++) {
      canvas.drawLine(line.points[i], line.points[i + 1], paint);
    }
  }

  @override
  bool shouldRepaint(FingerPainter oldDelegate) {
    return oldDelegate.line.points.length != line.points.length;
  }
}

class LineObject {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;

  const LineObject({
    required this.points,
    this.color = Colors.red,
    this.strokeWidth = 20.0,
  });

  LineObject copyWith({
    List<Offset>? points,
    Color? color,
    double? strokeWidth,
  }) {
    return LineObject(
      points: points ?? this.points,
      color: color ?? this.color,
      strokeWidth: strokeWidth ?? this.strokeWidth,
    );
  }
}

class ImagePainter extends CustomPainter {
  final ui.Image image;
  final ui.FragmentProgram program;
  const ImagePainter({
    required this.image,
    required this.program,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = _getShader(size)
      ..style = PaintingStyle.fill;

    final rect = Rect.fromPoints(
      const Offset(0, 0),
      Offset(size.width, size.height),
    );
    canvas.drawRect(rect, paint);
  }

  ui.FragmentShader _getShader(Size size) {
    final shader = program.fragmentShader();

    // resolution
    shader.setFloat(0, size.width);
    shader.setFloat(1, size.height);

    // texture
    shader.setImageSampler(0, image);

    return shader;
  }

  @override
  bool shouldRepaint(ImagePainter oldDelegate) {
    return oldDelegate.image != image;
  }
}


/**
    ui.FragmentProgram? _program;
    Future<void> _loadMyShader() async {
      final fragment = await ui.FragmentProgram.fromAsset('assets/shaders/simple_shader.frag');
      setState(() {
        _program = fragment;
      });
    }

    ui.Image? _brushTexture;
    Future<void> _loadBrushTexture() async {
      final ByteData data = await rootBundle.load('assets/images/texture.png');
      final Uint8List bytes = data.buffer.asUint8List();
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo fi = await codec.getNextFrame();
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

 */