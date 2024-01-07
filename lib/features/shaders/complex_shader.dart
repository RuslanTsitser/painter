import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_shaders/flutter_shaders.dart';

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

  final FragmentShader shader;
  final AnimationController _controller;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    shader.setFloatUniforms(
      (value) {
        value.setSize(Size(
          size.width,
          size.height,
        ));
        value.setFloat(_controller.value);
        value.setOffset(
          Offset(
            size.width,
            size.height,
          ),
        );
      },
      initialIndex: 0,
    );

    paint.shader = shader;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(MyPainter oldDelegate) => true;
}

/**
 uniform vec3 iResolution; // viewport resolution (in pixels)
uniform float iTime; // shader playback time (in seconds)
uniform float iTimeDelta; // render time (in seconds)
uniform float iFrameRate; // shader frame rate
uniform int iFrame; // shader playback frame
uniform float iChannelTime[4]; // channel playback time (in seconds)
uniform vec3 iChannelResolution[4]; // channel resolution (in pixels)
uniform vec4 iMouse; // mouse pixel coords. xy: current (if MLB down), zw
click
uniform samplerXX iChannel0..3; // input channel. XX = 2D/Cube

 */