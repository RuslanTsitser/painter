import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SimpleShaderScreen extends StatefulWidget {
  const SimpleShaderScreen({super.key});

  @override
  State<SimpleShaderScreen> createState() => _SimpleShaderScreenState();
}

class _SimpleShaderScreenState extends State<SimpleShaderScreen> with SingleTickerProviderStateMixin {
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
    final bytes = data.buffer.asUint8List();
    final ui.Codec codec = await ui.instantiateImageCodec(bytes);
    final ui.FrameInfo fi = await codec.getNextFrame();

    // Redraw if the image is loaded
    setState(() {
      _brushTexture = fi.image;
    });
  }

  late final AnimationController _controller;

  void _initAnimationController() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );
  }

  @override
  void initState() {
    _initAnimationController();
    _loadBrushTexture();
    _loadMyShader();
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_controller.isAnimating) {
            _controller.stop();
          } else {
            _controller.repeat();
          }
          setState(() {});
        },
        child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              if (_controller.isAnimating) {
                return const Icon(Icons.pause);
              }
              return const Icon(Icons.play_arrow);
            }),
      ),
      body: _program == null || _brushTexture == null
          ? const CircularProgressIndicator()
          : CustomPaint(
              size: MediaQuery.sizeOf(context),
              painter: MyPainter(
                _program!.fragmentShader(),
                _brushTexture!,
                _controller,
              ),
            ),
    );
  }
}

class MyPainter extends CustomPainter {
  const MyPainter(
    this.shader,
    this.brushTexture,
    this.controller,
  ) : super(repaint: controller);

  final ui.FragmentShader shader;
  final ui.Image brushTexture;
  final AnimationController controller;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    // color
    const color = Colors.blue;
    shader.setFloat(0, color.red / 255);
    shader.setFloat(1, color.green / 255);
    shader.setFloat(2, color.blue / 255);
    shader.setFloat(3, color.alpha / 255);

    // size
    shader.setFloat(4, 500);
    shader.setFloat(5, 500);

    // rotation
    shader.setFloat(6, pi * 2 * controller.value);

    // texture
    shader.setImageSampler(0, brushTexture);

    paint.shader = shader;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(MyPainter oldDelegate) => true;
}
