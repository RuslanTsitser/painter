import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:painter/features/coloring_svg/svg_painter.dart';

import 'models.dart';
import 'utils.dart';

// ignore: unused_field
const urlDogDetailed =
    'https://vk.com/doc223802256_674334023?hash=WxRBA2ZsSDeqhPaVJfJrcyEEqWJLWKYhjXA4H0ilo8X&dl=pugZVOEX0owMVIPuthbpfaEaWwGk0LZcr7msH9yKrpz';

class ColoringSvgScreen extends StatefulWidget {
  const ColoringSvgScreen({super.key});

  @override
  State<ColoringSvgScreen> createState() => _ColoringSvgScreenState();
}

class _ColoringSvgScreenState extends State<ColoringSvgScreen> {
  @override
  void initState() {
    _init();
    super.initState();
  }

  Size? _size;
  List<PathSvgItem>? _items;

  static const urlDogWithSmile =
      'https://vk.com/doc223802256_674334116?hash=407AqZBhX6zQrqcI3cGxCZdJGaZDbv1ywq65EZ8eHqH&dl=5KapGZXnEYzXOUUA977vWJoTB0kvZSrUzp7drp4qPIX';

  Future<void> _init() async {
    final value = await getVectorImage(urlDogDetailed);
    setState(() {
      _items = value.items;
      _size = value.size;
    });
  }

  void _onTap(int index) {
    setState(() {
      _items![index] = _items![index].copyWith(
        fill: Colors.red,
      );
    });
  }

  final GlobalKey _key = GlobalKey();
  bool _isInteraction = false;
  ui.Image? _image;

  void _onInteractionStart() {
    if (_isInteraction) return;
    _image = (_key.currentContext!.findRenderObject()! as RenderRepaintBoundary).toImageSync();
    setState(() {
      _isInteraction = true;
    });
  }

  void _onInteractionEnd() {
    if (!_isInteraction) return;
    setState(() {
      _isInteraction = false;
    });
    _image?.dispose();
    _image = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Coloring SVG')),
      body: _items == null || _size == null
          ? const Center(child: CircularProgressIndicator())
          : InteractiveViewer(
              onInteractionStart: (_) => _onInteractionStart(),
              onInteractionEnd: (_) => _onInteractionEnd(),
              child: Center(
                child: FittedBox(
                  child: _isInteraction
                      ? CustomPaint(
                          size: _size!,
                          painter: ImagePainter(_image!),
                        )
                      // RepaintBoundary should be used to prevent rebuilds
                      // during transformations with InteractiveViewer
                      : RepaintBoundary(
                          key: _key,
                          child: SizedBox(
                            width: _size!.width,
                            height: _size!.height,
                            child: Stack(
                              children: [
                                for (int index = 0; index < _items!.length; index++)
                                  SvgPainterImage(
                                    item: _items![index],
                                    size: _size!,
                                    onTap: () => _onTap(index),
                                  )
                              ],
                            ),
                          ),
                        ),
                ),
              ),
            ),
    );
  }
}

class SvgPainterImage extends StatelessWidget {
  const SvgPainterImage({
    super.key,
    required this.item,
    required this.size,
    required this.onTap,
  });
  final PathSvgItem item;
  final Size size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: size,
      foregroundPainter: SvgPainter(item, onTap),
    );
  }
}

class ImagePainter extends CustomPainter {
  final ui.Image image;

  const ImagePainter(this.image);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    canvas.drawImage(image, Offset.zero, paint);
  }

  @override
  bool shouldRepaint(ImagePainter oldDelegate) => false;
}
