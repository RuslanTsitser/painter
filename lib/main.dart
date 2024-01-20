import 'package:flutter/material.dart';
import 'package:painter/features/examples/finger_painter_screen.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      // home: SimpleShaderScreen(),
      home: FingerPainterScreen(),
    );
  }
}
