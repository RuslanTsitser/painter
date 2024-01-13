import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class ComplexShaderScreen extends StatefulWidget {
  const ComplexShaderScreen({super.key});

  @override
  State<ComplexShaderScreen> createState() => _ComplexShaderScreenState();
}

class _ComplexShaderScreenState extends State<ComplexShaderScreen> with SingleTickerProviderStateMixin {
  ui.FragmentProgram? _program;

  Future<void> _loadMyShader() async {
    final fragment = await ui.FragmentProgram.fromAsset('assets/shaders/complex_shader.frag');

    setState(() {
      _program = fragment;
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
      body: _program == null
          ? const CircularProgressIndicator()
          : CustomPaint(
              size: MediaQuery.sizeOf(context),
              painter: MyPainter(
                _program!.fragmentShader(),
                _controller,
              ),
            ),
    );
  }
}

class MyPainter extends CustomPainter {
  const MyPainter(this.shader, this._controller) : super(repaint: _controller);

  final ui.FragmentShader shader;
  final AnimationController _controller;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    shader.setFloat(0, size.width);
    shader.setFloat(1, size.height);

    shader.setFloat(2, _controller.value);

    shader.setFloat(3, size.width);
    shader.setFloat(4, size.height);

    paint.shader = shader;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(MyPainter oldDelegate) => true;
}
