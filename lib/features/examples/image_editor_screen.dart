import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

final _imageKey = GlobalKey();
final _movingRectKey = GlobalKey();

class ImageEditorScreen extends StatelessWidget {
  const ImageEditorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Editor'),
        actions: [
          IconButton(
            onPressed: () {
              final ImageWidgetState imageWidgetState = _imageKey.currentState as ImageWidgetState;
              final ui.Image image = imageWidgetState.image!;
              final Size widgetSize = imageWidgetState.size!;
              final MovingRectWrapperState state = _movingRectKey.currentState as MovingRectWrapperState;
              final Offset rectCenterOffset = state.center;
              final Size rectSize = state.size;

              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => CroppedImageScreen(
                    image: image,
                    center: rectCenterOffset,
                    size: rectSize,
                    widgetSize: widgetSize,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.save),
          ),
        ],
      ),
      body: Center(
        child: MovingRectWrapper(
          key: _movingRectKey,
          child: ImageWidget(
            key: _imageKey,
          ),
        ),
      ),
    );
  }
}

class MovingRectWrapper extends StatefulWidget {
  const MovingRectWrapper({super.key, required this.child});
  final Widget child;

  @override
  State<MovingRectWrapper> createState() => MovingRectWrapperState();
}

class MovingRectWrapperState extends State<MovingRectWrapper> {
  Offset _focalPoint = Offset.zero;
  double _scale = 1.0;
  Matrix4 _matrix = Matrix4.identity();
  final double _width = 100.0;
  final double _height = 100.0;

  Offset get center => Offset(
        _matrix[12] + context.size!.width / 2 - _width / 2 + size.width / 2,
        _matrix[13] + context.size!.height / 2 - _height / 2 + size.height / 2,
      );
  Size get size => Size(
        _width * _matrix[0],
        _height * _matrix[5],
      );

  void _onReset() {
    setState(() {
      _matrix = Matrix4.identity();
      _scale = 1.0;
    });
  }

  void _onScaleStart(ScaleStartDetails details) {
    _focalPoint = details.focalPoint;
    _scale = 1.0;
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
              width: _width,
              height: _height,
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

class CroppedImageScreen extends StatelessWidget {
  const CroppedImageScreen({
    super.key,
    required this.image,
    required this.center,
    required this.size,
    required this.widgetSize,
  });
  final ui.Image image;
  final Offset center;
  final Size size;
  final Size widgetSize;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cropped Image'),
      ),
      body: Center(
        child: CustomPaint(
          size: size,
          painter: CroppedImagePainter(
            image: image,
            center: center,
            widgetSize: widgetSize,
          ),
        ),
      ),
    );
  }
}

class CroppedImagePainter extends CustomPainter {
  const CroppedImagePainter({
    required this.image,
    required this.center,
    required this.widgetSize,
  });
  final ui.Image image;
  final Offset center;
  final Size widgetSize;

  @override
  void paint(Canvas canvas, Size size) {
    final pixelRatio = image.width / widgetSize.width;
    final src = Rect.fromCenter(
      center: Offset(
        center.dx * pixelRatio,
        center.dy * pixelRatio,
      ),
      width: size.width * pixelRatio,
      height: size.height * pixelRatio,
    );
    final dst = Rect.fromCenter(
      center: Offset(
        size.width / 2,
        size.height / 2,
      ),
      width: size.width,
      height: size.height,
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

class ImageWidget extends StatefulWidget {
  const ImageWidget({
    super.key,
  });

  @override
  State<ImageWidget> createState() => ImageWidgetState();
}

class ImageWidgetState extends State<ImageWidget> {
  ui.Image? _image;
  @override
  void initState() {
    _loadImage();

    super.initState();
  }

  ui.Image? get image => _image;
  ui.Size? get size => _image?.width != null && _image?.height != null
      ? ui.Size(_image!.width.toDouble(), _image!.height.toDouble())
      : null;

  Future<void> _loadImage() async {
    final data = await NetworkAssetBundle(Uri.parse('https://picsum.photos/id/418/400/700')).load('');
    final Uint8List bytes = data.buffer.asUint8List();
    final ui.Codec codec = await ui.instantiateImageCodec(bytes);
    final ui.Image image = (await codec.getNextFrame()).image;
    setState(() {
      _image = image;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _image == null
        ? const CircularProgressIndicator()
        : CustomPaint(
            size: Size(
              _image!.width.toDouble(),
              _image!.height.toDouble(),
            ),
            painter: ImagePainter(image: _image!),
          );
  }
}

class ImagePainter extends CustomPainter {
  final ui.Image image;
  const ImagePainter({
    required this.image,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawImage(
      image,
      Offset.zero,
      Paint()..filterQuality = FilterQuality.high,
    );
  }

  @override
  bool shouldRepaint(ImagePainter oldDelegate) => false;
}
