import 'package:flutter/material.dart';
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
    final value = await getVectorImage(urlDogWithSmile);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Coloring SVG')),
      body: _items == null || _size == null
          ? const Center(child: CircularProgressIndicator())
          : InteractiveViewer(
              child: Center(
                child: FittedBox(
                  // RepaintBoundary should be used to prevent rebuilds
                  // during transformations with InteractiveViewer
                  child: RepaintBoundary(
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
