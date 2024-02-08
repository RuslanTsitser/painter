import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:painter/features/examples/algorithms.dart';

class ImageFloodFillImpl extends FloodFill<ui.Image, ui.Color> {
  const ImageFloodFillImpl(ui.Image image) : super(image);

  @override
  Future<ui.Image?> fill(int startX, int startY, ui.Color newColor) async {
    ByteData? byteData = await imageToBytes(image);
    if (byteData == null) return null;

    int width = image.width;
    int height = image.height;
    ui.Color originalColor = getPixelColor(bytes: byteData, x: startX, y: startY, imageWidth: width);

    _floodFillUtil(byteData, startX, startY, width, height, originalColor, newColor);

    return imageFromBytes(byteData, width, height);
  }

  void _floodFillUtil(ByteData bytes, int x, int y, int width, int height, ui.Color originalColor, ui.Color newColor) {
    // Check if current node is inside the boundary and not already filled
    if (!_isInside(x, y, width, height) ||
        !isAlmostSameColor(
            pixelColor: getPixelColor(bytes: bytes, x: x, y: y, imageWidth: width),
            checkColor: originalColor,
            imageWidth: width)) return;

    // Set the node
    setPixelColor(x: x, y: y, bytes: bytes, imageWidth: width, newColor: newColor);

    // Perform flood-fill one step in each direction
    _floodFillUtil(bytes, x + 1, y, width, height, originalColor, newColor); // East
    _floodFillUtil(bytes, x - 1, y, width, height, originalColor, newColor); // West
    _floodFillUtil(bytes, x, y - 1, width, height, originalColor, newColor); // North
    _floodFillUtil(bytes, x, y + 1, width, height, originalColor, newColor); // South
  }

  bool _isInside(int x, int y, int width, int height) {
    return x >= 0 && x < width && y >= 0 && y < height;
  }
}

class ImageFloodFillQueueImpl extends FloodFill<ui.Image, ui.Color> {
  const ImageFloodFillQueueImpl(ui.Image image) : super(image);

  @override
  Future<ui.Image?> fill(int startX, int startY, ui.Color newColor) async {
    ByteData? byteData = await imageToBytes(image);
    if (byteData == null) return null;

    int width = image.width;
    int height = image.height;
    ui.Color oldColor = getPixelColor(bytes: byteData, x: startX, y: startY, imageWidth: width);

    final Queue<Point> queue = Queue();
    queue.add(Point(startX, startY));

    while (queue.isNotEmpty) {
      final Point point = queue.removeFirst();
      final int x = point.x;
      final int y = point.y;

      if (isAlmostSameColor(
          pixelColor: getPixelColor(bytes: byteData, x: x, y: y, imageWidth: width),
          checkColor: oldColor,
          imageWidth: width)) {
        setPixelColor(x: x, y: y, bytes: byteData, imageWidth: width, newColor: newColor);

        if (x > 0) queue.add(Point(x - 1, y));
        if (x < width - 1) queue.add(Point(x + 1, y));
        if (y > 0) queue.add(Point(x, y - 1));
        if (y < height - 1) queue.add(Point(x, y + 1));
      }
    }

    return imageFromBytes(byteData, width, height);
  }
}

class Point {
  final int x;
  final int y;

  const Point(this.x, this.y);
}

class ImageFloodFillSpanImpl extends FloodFill<ui.Image, ui.Color> {
  const ImageFloodFillSpanImpl(ui.Image image) : super(image);

  @override
  Future<ui.Image?> fill(int startX, int startY, ui.Color newColor) async {
    ByteData? byteData = await imageToBytes(image);
    if (byteData == null) return null;

    int width = image.width;
    int height = image.height;
    ui.Color targetColor = getPixelColor(bytes: byteData, x: startX, y: startY, imageWidth: width);

    var s = <List<int>>[];
    s.add([startX, startX, startY, 1]);
    s.add([startX, startX, startY - 1, -1]);

    while (s.isNotEmpty) {
      var tuple = s.removeLast();
      var x1 = tuple[0];
      var x2 = tuple[1];
      var y = tuple[2];
      var dy = tuple[3];

      var nx = x1;
      if (_isInside(nx, y, width, height, byteData, targetColor)) {
        while (_isInside(nx - 1, y, width, height, byteData, targetColor)) {
          setPixelColor(x: nx - 1, y: y, bytes: byteData, imageWidth: width, newColor: newColor);
          nx--;
        }
        if (nx < x1) {
          s.add([nx, x1 - 1, y - dy, -dy]);
        }
      }

      while (x1 <= x2) {
        while (_isInside(x1, y, width, height, byteData, targetColor)) {
          setPixelColor(x: x1, y: y, bytes: byteData, imageWidth: width, newColor: newColor);
          x1++;
        }
        if (x1 > nx) {
          s.add([nx, x1 - 1, y + dy, dy]);
        }
        if (x1 - 1 > x2) {
          s.add([x2 + 1, x1 - 1, y - dy, -dy]);
        }
        x1++;
        while (x1 < x2 && !_isInside(x1, y, width, height, byteData, targetColor)) {
          x1++;
        }
        nx = x1;
      }
    }

    return imageFromBytes(byteData, width, height);
  }

  bool _isInside(int x, int y, int width, int height, ByteData bytes, ui.Color targetColor) {
    if (x < 0 || x >= width || y < 0 || y >= height) return false;
    return isAlmostSameColor(
        pixelColor: getPixelColor(bytes: bytes, x: x, y: y, imageWidth: width),
        checkColor: targetColor,
        imageWidth: width);
  }
}

class FloodFillSpan {
  static Future<ui.Image?> fill({
    required ui.Image image,
    required int startX,
    required int startY,
    required ui.Color newColor,
  }) async {
    final Stopwatch stopwatch = Stopwatch()..start();
    ByteData? bytes = await imageToBytes(image);
    if (bytes == null) return null;

    final imageWidth = image.width;
    final imageHeight = image.height;
    final targetColor = getPixelColor(
      bytes: bytes,
      x: startX,
      y: startY,
      imageWidth: imageWidth,
    );

    bool inside(int x, int y) {
      if (x >= 0 && y >= 0 && x < imageWidth && y < imageHeight) {
        final pixelColor = getPixelColor(
          bytes: bytes,
          x: x,
          y: y,
          imageWidth: imageWidth,
        );
        return isAlmostSameColor(
          pixelColor: pixelColor,
          checkColor: targetColor,
          imageWidth: imageWidth,
        );
      }
      return false;
    }

    void set(int x, int y) {
      setPixelColor(x: x, y: y, bytes: bytes, imageWidth: imageWidth, newColor: newColor);
    }

    var s = <List<int>>[];
    s.add([startX, startX, startY, 1]);
    s.add([startX, startX, startY - 1, -1]);

    while (s.isNotEmpty) {
      var tuple = s.removeLast();
      var x1 = tuple[0];
      var x2 = tuple[1];
      var y = tuple[2];
      var dy = tuple[3];

      var nx = x1;
      if (inside(nx, y)) {
        while (inside(nx - 1, y)) {
          set(nx - 1, y);
          nx--;
        }
        if (nx < x1) {
          s.add([nx, x1 - 1, y - dy, -dy]);
        }
      }

      while (x1 <= x2) {
        while (inside(x1, y)) {
          set(x1, y);
          x1++;
        }
        if (x1 > nx) {
          s.add([nx, x1 - 1, y + dy, dy]);
        }
        if (x1 - 1 > x2) {
          s.add([x2 + 1, x1 - 1, y - dy, -dy]);
        }
        x1++;
        while (x1 < x2 && !inside(x1, y)) {
          x1++;
        }
        nx = x1;
      }
    }
    stopwatch.stop();
    print('FloodFillSpan.fill() executed in ${stopwatch.elapsedMilliseconds}ms');
    return imageFromBytes(bytes, imageWidth, imageHeight);
  }

  // Other helper functions (_isAlmostSameColor, _setPixelColor, _convertARGBtoRGBA, _getPixelColor, _returnImage) are same as in your provided code
}

class FloodFillQueued {
  static Future<ui.Image?> fill({
    required ui.Image image,
    required int startX,
    required int startY,
    required ui.Color newColor,
  }) async {
    final Stopwatch stopwatch = Stopwatch()..start();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (bytes == null) return null;

    final imageWidth = image.width;
    final imageHeight = image.height;
    ui.Color initialPixelColor = getPixelColor(
      bytes: bytes,
      x: startX,
      y: startY,
      imageWidth: imageWidth,
    );
    if (initialPixelColor == newColor) return null;

    final Queue<ui.Offset> queue = Queue();
    queue.add(ui.Offset(startX.toDouble(), startY.toDouble()));

    while (queue.isNotEmpty) {
      final ui.Offset point = queue.removeFirst();
      final int x = point.dx.toInt();
      final int y = point.dy.toInt();

      final pixelColor = getPixelColor(
        bytes: bytes,
        x: startX,
        y: startY,
        imageWidth: imageWidth,
      );
      final isInitialAndCurrentSame = isAlmostSameColor(
        pixelColor: pixelColor,
        checkColor: initialPixelColor,
        imageWidth: imageWidth,
      );

      if (isInitialAndCurrentSame) {
        setPixelColor(
          x: x,
          y: x,
          bytes: bytes,
          imageWidth: imageWidth,
          newColor: newColor,
        );

        if (x > 0) {
          queue.add(ui.Offset(x - 1, y.toDouble()));
        }
        if (x < imageWidth - 1) {
          queue.add(ui.Offset(x + 1, y.toDouble()));
        }
        if (y > 0) {
          queue.add(ui.Offset(x.toDouble(), y - 1));
        }
        if (y < imageHeight - 1) {
          queue.add(ui.Offset(x.toDouble(), y + 1));
        }
      }
    }
    stopwatch.stop();
    print('FloodFillQueued.fill() executed in ${stopwatch.elapsedMilliseconds}ms');
    return imageFromBytes(bytes, imageWidth, imageHeight);
  }
}

class FloodFillClassic {
  static Future<ui.Image?> fill({
    required ui.Image image,
    required int startX,
    required int startY,
    required ui.Color newColor,
  }) async {
    final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (bytes == null) return null;

    final imageWidth = image.width;
    final imageHeight = image.height;
    ui.Color initialPixelColor = getPixelColor(
      bytes: bytes,
      x: startX,
      y: startY,
      imageWidth: imageWidth,
    );
    if (initialPixelColor == newColor) return null;

    _fill(
      bytes: bytes,
      x: startX,
      y: startY,
      newColor: newColor,
      initialPixelColor: initialPixelColor,
      imageWidth: imageWidth,
      imageHeight: imageHeight,
    );

    return imageFromBytes(bytes, imageWidth, imageHeight);
  }

  static void _fill({
    required ByteData bytes,
    required int x,
    required int y,
    required ui.Color initialPixelColor,
    required ui.Color newColor,
    required int imageWidth,
    required int imageHeight,
  }) {
    if (x < 0 || x >= imageWidth || y < 0 || y >= imageHeight) return;

    final ui.Color pixelColor = getPixelColor(
      bytes: bytes,
      x: x,
      y: y,
      imageWidth: imageWidth,
    );
    final isInitialAndCurrentSame = isAlmostSameColor(
      pixelColor: pixelColor,
      checkColor: initialPixelColor,
      imageWidth: imageWidth,
    );

    if (isInitialAndCurrentSame) {
      setPixelColor(
        x: x,
        y: x,
        bytes: bytes,
        imageWidth: imageWidth,
        newColor: newColor,
      );

      _fill(
        bytes: bytes,
        imageWidth: imageWidth,
        imageHeight: imageHeight,
        x: x + 1,
        y: y,
        initialPixelColor: initialPixelColor,
        newColor: newColor,
      );
      _fill(
        bytes: bytes,
        imageWidth: imageWidth,
        imageHeight: imageHeight,
        x: x - 1,
        y: y,
        initialPixelColor: initialPixelColor,
        newColor: newColor,
      );
      _fill(
        bytes: bytes,
        imageWidth: imageWidth,
        imageHeight: imageHeight,
        x: x,
        y: y + 1,
        initialPixelColor: initialPixelColor,
        newColor: newColor,
      );
      _fill(
        bytes: bytes,
        imageWidth: imageWidth,
        imageHeight: imageHeight,
        x: x,
        y: y - 1,
        initialPixelColor: initialPixelColor,
        newColor: newColor,
      );
    }
  }
}

Future<ByteData?> imageToBytes(ui.Image image) async {
  final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  return bytes;
}

Future<ui.Image> imageFromBytes(ByteData bytes, int imageWidth, int imageHeight) {
  final Completer<ui.Image> completer = Completer();
  ui.decodeImageFromPixels(
    bytes.buffer.asUint8List(),
    imageWidth,
    imageHeight,
    ui.PixelFormat.rgba8888,
    (img) {
      completer.complete(img);
    },
  );
  return completer.future;
}

bool isAlmostSameColor({
  required ui.Color pixelColor,
  required ui.Color checkColor,
  required int imageWidth,
}) {
  const int threshold = 50;
  final int rDiff = (pixelColor.red - checkColor.red).abs();
  final int gDiff = (pixelColor.green - checkColor.green).abs();
  final int bDiff = (pixelColor.blue - checkColor.blue).abs();
  return rDiff < threshold && gDiff < threshold && bDiff < threshold;
}

void setPixelColor({
  required int x,
  required int y,
  required ByteData bytes,
  required int imageWidth,
  required ui.Color newColor,
}) {
  bytes.setUint32(
    (x + y * imageWidth) * 4,
    colorToIntRGBA(newColor),
  );
}

ui.Color getPixelColor({
  required ByteData bytes,
  required int x,
  required int y,
  required int imageWidth,
}) {
  final uint32 = bytes.getUint32((x + y * imageWidth) * 4);
  return colorFromIntRGBA(uint32);
}

int colorToIntRGBA(ui.Color color) {
  // Extract ARGB components
  int a = (color.value >> 24) & 0xFF;
  int r = (color.value >> 16) & 0xFF;
  int g = (color.value >> 8) & 0xFF;
  int b = color.value & 0xFF;

  // Convert to RGBA and combine into a single integer
  return (r << 24) | (g << 16) | (b << 8) | a;
}

ui.Color colorFromIntRGBA(int uint32Rgba) {
  // Extract RGBA components
  int r = (uint32Rgba >> 24) & 0xFF;
  int g = (uint32Rgba >> 16) & 0xFF;
  int b = (uint32Rgba >> 8) & 0xFF;
  int a = uint32Rgba & 0xFF;

  // Convert to ARGB format and create a Color object
  return ui.Color.fromARGB(a, r, g, b);
}
