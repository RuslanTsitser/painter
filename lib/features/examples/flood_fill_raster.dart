import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';
import 'dart:ui' as ui;

class FloodFillSpan {
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
    final targetColor = _getPixelColor(bytes, startX, startY, imageWidth);

    bool inside(int x, int y) {
      if (x >= 0 && y >= 0 && x < imageWidth && y < imageHeight) {
        final pixelColor = _getPixelColor(bytes, x, y, imageWidth);
        return _isAlmostSameColor(
          pixelColor: pixelColor,
          checkColor: targetColor,
          imageWidth: imageWidth,
        );
      }
      return false;
    }

    void set(int x, int y) {
      _setPixelColor(x, y, bytes: bytes, imageWidth: imageWidth, newColor: newColor);
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
    return _returnImage(bytes, imageWidth, imageHeight);
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
    ui.Color initialPixelColor = _getPixelColor(bytes, startX, startY, imageWidth);
    if (initialPixelColor == newColor) return null;

    final Queue<ui.Offset> queue = Queue();
    queue.add(ui.Offset(startX.toDouble(), startY.toDouble()));

    while (queue.isNotEmpty) {
      final ui.Offset point = queue.removeFirst();
      final int x = point.dx.toInt();
      final int y = point.dy.toInt();

      final pixelColor = _getPixelColor(bytes, x, y, imageWidth);
      final isInitialAndCurrentSame = _isAlmostSameColor(
        pixelColor: pixelColor,
        checkColor: initialPixelColor,
        imageWidth: imageWidth,
      );

      if (isInitialAndCurrentSame) {
        _setPixelColor(
          x,
          y,
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
    return _returnImage(bytes, imageWidth, imageHeight);
  }
}

class FloodFill {
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
    ui.Color initialPixelColor = _getPixelColor(bytes, startX, startY, imageWidth);
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

    return _returnImage(bytes, imageWidth, imageHeight);
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

    final ui.Color pixelColor = _getPixelColor(bytes, x, y, imageWidth);
    final isInitialAndCurrentSame = _isAlmostSameColor(
      pixelColor: pixelColor,
      checkColor: initialPixelColor,
      imageWidth: imageWidth,
    );

    if (isInitialAndCurrentSame) {
      _setPixelColor(
        x,
        y,
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

Future<ui.Image> _returnImage(ByteData grid, int imageWidth, int imageHeight) {
  final Completer<ui.Image> completer = Completer();
  ui.decodeImageFromPixels(
    grid.buffer.asUint8List(),
    imageWidth,
    imageHeight,
    ui.PixelFormat.rgba8888,
    (img) {
      completer.complete(img);
    },
  );
  return completer.future;
}

bool _isAlmostSameColor({
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

void _setPixelColor(
  int x,
  int y, {
  required ByteData bytes,
  required int imageWidth,
  required ui.Color newColor,
}) {
  bytes.setUint32(
    (x * 4) + (y * imageWidth * 4),
    _convertARGBtoRGBA(newColor),
  );
}

int _convertARGBtoRGBA(ui.Color color) {
  // Extract ARGB components
  int a = (color.value >> 24) & 0xFF;
  int r = (color.value >> 16) & 0xFF;
  int g = (color.value >> 8) & 0xFF;
  int b = color.value & 0xFF;

  // Convert to RGBA and combine into a single integer
  return (r << 24) | (g << 16) | (b << 8) | a;
}

ui.Color _getPixelColor(ByteData bytes, int x, int y, int imageWidth) {
  final uint32 = bytes.getUint32((x * 4) + (y * imageWidth * 4));
  return _convertRGBAtoARGB(uint32);
}

ui.Color _convertRGBAtoARGB(int uint32Rgba) {
  // Extract RGBA components
  int r = (uint32Rgba >> 24) & 0xFF;
  int g = (uint32Rgba >> 16) & 0xFF;
  int b = (uint32Rgba >> 8) & 0xFF;
  int a = uint32Rgba & 0xFF;

  // Convert to ARGB format and create a Color object
  return ui.Color.fromARGB(a, r, g, b);
}
