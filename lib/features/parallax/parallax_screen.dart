import 'dart:math' show Random;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class ParallaxScreen extends StatefulWidget {
  const ParallaxScreen({super.key});

  @override
  State<ParallaxScreen> createState() => _ParallaxScreenState();
}

class _ParallaxScreenState extends State<ParallaxScreen> {
  late final List<int> ids = List.generate(10, (index) => Random().nextInt(500));
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _Background(
        scrollController: _scrollController,
        child: ListView.builder(
          controller: _scrollController,
          itemCount: ids.length,
          itemBuilder: (context, index) {
            final int id = ids[index];
            return ItemCard(id: id);
          },
        ),
      ),
    );
  }
}

class ItemCard extends StatelessWidget {
  const ItemCard({
    super.key,
    required this.id,
  });

  final int id;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 20,
      ),
      clipBehavior: Clip.hardEdge,
      width: double.maxFinite,
      height: 300,
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Stack(
        children: [
          Image.network(
            'https://picsum.photos/id/$id/500/300',
            width: double.maxFinite,
          ),
          Positioned(
            left: 20,
            bottom: 20,
            child: Text(
              'Image $id',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Background extends StatefulWidget {
  const _Background({
    required this.child,
    required this.scrollController,
  });
  final Widget child;
  final ScrollController scrollController;

  @override
  State<_Background> createState() => _BackgroundState();
}

class _BackgroundState extends State<_Background> {
  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  ui.Image? _image;
  Future<void> _loadImage() async {
    const imageProvider = NetworkImage('https://picsum.photos/id/307/600/4000');
    final ImageStreamListener listener = ImageStreamListener((info, _) {
      setState(() {
        _image = info.image;
      });
    });
    final ImageStream stream = imageProvider.resolve(const ImageConfiguration());
    stream.addListener(listener);
  }

  @override
  void dispose() {
    _image?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _image != null ? _BackgroundImagePainter(widget.scrollController, _image!) : null,
      child: widget.child,
    );
  }
}

class _BackgroundImagePainter extends CustomPainter {
  final ScrollController controller;
  final ui.Image image;
  const _BackgroundImagePainter(this.controller, this.image) : super(repaint: controller);

  @override
  void paint(Canvas canvas, Size size) {
    final imageWidth = image.width.toDouble();
    final imageHeight = image.height.toDouble();
    final aspectRatio = imageWidth / imageHeight;

    final src = Rect.fromLTWH(
      0,
      0,
      imageWidth,
      imageHeight,
    );
    final deltaY = -controller.offset * 0.6;
    final dst = Rect.fromLTWH(
      0,
      deltaY,
      size.width,
      size.width / aspectRatio,
    );
    canvas.drawImageRect(
      image,
      src,
      dst,
      Paint()..filterQuality = FilterQuality.high,
    );
  }

  @override
  bool shouldRepaint(_BackgroundImagePainter oldDelegate) => controller.offset != oldDelegate.controller.offset;
}
