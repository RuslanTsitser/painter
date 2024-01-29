import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class ImageEditorScreen extends StatefulWidget {
  const ImageEditorScreen({super.key});

  @override
  State<ImageEditorScreen> createState() => _ImageEditorScreenState();
}

class _ImageEditorScreenState extends State<ImageEditorScreen> {
  final GlobalKey _repaintBoundaryKey = GlobalKey();
  final _movingRectKey = GlobalKey<State<MovingRectWrapper>>();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Editor'),
        actions: [
          IconButton(
            onPressed: () {
              final RenderRepaintBoundary boundary =
                  _repaintBoundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

              final movingRectState = _movingRectKey.currentWidget as MovingRectWrapper;
              final top = movingRectState.top;
              final left = movingRectState.left;
              final width = movingRectState.width;
              final height = movingRectState.height;

              const imagePixelRatio = 1.0;
              boundary.toImage(pixelRatio: imagePixelRatio).then((image) {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => CroppedImageScreen(
                          image: image,
                          top: top,
                          left: left,
                          width: width,
                          height: height,
                          imagePixelRatio: imagePixelRatio,
                        )));
              });
            },
            icon: const Icon(Icons.save),
          ),
        ],
      ),
      body: Center(
        child: MovingRectWrapper(
          key: _movingRectKey,
          child: RepaintBoundary(
            key: _repaintBoundaryKey,
            child: Image.network('https://picsum.photos/id/418/400/700'), // id 178
          ),
        ),
      ),
    );
  }
}

class MovingRectWrapper extends StatefulWidget {
  const MovingRectWrapper({required GlobalKey key, required this.child}) : super(key: key);
  final Widget child;

  double get top => ((key as GlobalKey).currentState as _MovingRectWrapperState).top;
  double get left => ((key as GlobalKey).currentState as _MovingRectWrapperState).left;
  double get width => ((key as GlobalKey).currentState as _MovingRectWrapperState).width;
  double get height => ((key as GlobalKey).currentState as _MovingRectWrapperState).height;

  @override
  State<MovingRectWrapper> createState() => _MovingRectWrapperState();
}

class _MovingRectWrapperState extends State<MovingRectWrapper> {
  Offset _focalPoint = Offset.zero;
  double _scale = 1.0;
  Matrix4 _matrix = Matrix4.identity();

  double get top => _matrix.getTranslation().y + context.size!.height / 2 - 50;
  double get left => _matrix.getTranslation().x + context.size!.width / 2 - 50;
  double get width => 100 * _scale;
  double get height => 100 * _scale;

  void _onReset() {
    setState(() {
      _matrix = Matrix4.identity();
      _scale = 1.0;
    });
  }

  void _onScaleStart(ScaleStartDetails details) {
    _focalPoint = details.focalPoint;
    if (details.pointerCount > 1) {
      _scale = 1.0;
    }
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    Matrix4 matrix = _matrix;

    final newFocalPoint = details.focalPoint;
    final offsetDelta = (newFocalPoint - _focalPoint);
    _focalPoint = newFocalPoint;
    final offsetDeltaMatrix = _getTranslateMatrix(offsetDelta);
    matrix = offsetDeltaMatrix * matrix;

    final newScale = details.scale;
    if (newScale != 1.0) {
      final scaleDelta = newScale / _scale;
      _scale = newScale;
      final scaleDeltaMatrix = _getScaleMatrix(scaleDelta);
      matrix = scaleDeltaMatrix * matrix;
    }

    setState(() {
      _matrix = matrix;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onDoubleTap: _onReset,
      onScaleStart: _onScaleStart,
      onScaleUpdate: _onScaleUpdate,
      child: Stack(
        alignment: Alignment.center,
        children: [
          widget.child,
          Transform(
            transform: _matrix,
            child: SizedBox(
              width: 100,
              height: 100,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  border: Border.all(
                    color: Colors.red,
                    width: 2,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Matrix4 _getTranslateMatrix(Offset offsetDelta) {
  final dx = offsetDelta.dx;
  final dy = offsetDelta.dy;
  return Matrix4(
    1, 0, 0, 0, // comments are used for readable formatting
    0, 1, 0, 0, // of Matrix4 arguments
    0, 0, 1, 0, //
    dx, dy, 0, 1, //
  );
}

Matrix4 _getScaleMatrix(double scale) {
  return Matrix4(
    scale, 0, 0, 0, //
    0, scale, 0, 0, //
    0, 0, 1, 0, //
    0, 0, 0, 1, //
  );
}

class CroppedImageScreen extends StatefulWidget {
  const CroppedImageScreen({
    super.key,
    required this.image,
    required this.top,
    required this.left,
    required this.width,
    required this.height,
    this.imagePixelRatio = 1.0,
  });
  final ui.Image image;
  final double top;
  final double left;
  final double width;
  final double height;
  final double imagePixelRatio;

  @override
  State<CroppedImageScreen> createState() => _CroppedImageScreenState();
}

class _CroppedImageScreenState extends State<CroppedImageScreen> {
  final GlobalKey _repaintBoundaryKey = GlobalKey();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cropped Image'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final boundary = _repaintBoundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
          boundary.toImage().then(
              (image) => image.toByteData(format: ui.ImageByteFormat.png).then((bytes) => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (context) => Scaffold(
                              appBar: AppBar(
                                title: const Text('Cropped Image'),
                              ),
                              body: Center(
                                child: Image.memory(bytes!.buffer.asUint8List()),
                              ),
                            )),
                  )));
        },
      ),
      body: RepaintBoundary(
        key: _repaintBoundaryKey,
        child: CustomPaint(
          painter: CroppedImagePainter(
            image: widget.image,
            top: widget.top,
            left: widget.left,
            width: widget.width,
            height: widget.height,
            imagePixelRatio: widget.imagePixelRatio,
          ),
        ),
      ),
    );
  }
}

class CroppedImagePainter extends CustomPainter {
  const CroppedImagePainter({
    required this.image,
    required this.top,
    required this.left,
    required this.width,
    required this.height,
    this.imagePixelRatio = 1.0,
  });
  final ui.Image image;
  final double top;
  final double left;
  final double width;
  final double height;
  final double imagePixelRatio;

  @override
  void paint(Canvas canvas, Size size) {
    final src = Rect.fromPoints(
      Offset(
        left * imagePixelRatio,
        top * imagePixelRatio,
      ),
      Offset(
        (left + width) * imagePixelRatio,
        (top + height) * imagePixelRatio,
      ),
    );
    final dst = Rect.fromPoints(
      Offset(left, top),
      Offset(left + width, top + height),
    );
    canvas.drawImageRect(
      image,
      src,
      dst,
      Paint(),
    );
  }

  @override
  bool shouldRepaint(CroppedImagePainter oldDelegate) => false;
}
