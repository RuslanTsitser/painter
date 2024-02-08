import 'dart:async';
import 'dart:collection';

abstract class FloodFill<T, S> {
  final T image;
  const FloodFill(this.image);
  FutureOr<T?> fill(int startX, int startY, S newColor);
}

class BasicFloodFill extends FloodFill<List<List<int>>, int> {
  const BasicFloodFill(List<List<int>> image) : super(image);

  @override
  List<List<int>>? fill(int startX, int startY, int newColor) {
    int originalColor = image[startX][startY];
    _floodFillUtil(startX, startY, originalColor, newColor);
    return image;
  }

  void _floodFillUtil(int x, int y, int originalColor, int newColor) {
    // Check if current node is inside the boundary and not already filled
    if (!_isInside(x, y) || image[x][y] != originalColor) return;

    // Set the node
    image[x][y] = newColor;

    // Perform flood-fill one step in each direction
    _floodFillUtil(x + 1, y, originalColor, newColor); // South
    _floodFillUtil(x - 1, y, originalColor, newColor); // North
    _floodFillUtil(x, y - 1, originalColor, newColor); // West
    _floodFillUtil(x, y + 1, originalColor, newColor); // East
  }

  bool _isInside(int x, int y) {
    return x >= 0 && x < image.length && y >= 0 && y < image[0].length;
  }
}

class Point {
  final int x;
  final int y;

  const Point(this.x, this.y);
}

class FloodFillQueueImpl extends FloodFill<List<List<int>>, int> {
  const FloodFillQueueImpl(List<List<int>> image) : super(image);

  @override
  List<List<int>>? fill(int startX, int startY, int newColor) {
    final int oldColor = image[startX][startY];
    final int width = image[0].length;
    final int height = image.length;
    final Queue<Point> queue = Queue();
    queue.add(Point(startY, startX));

    while (queue.isNotEmpty) {
      final Point point = queue.removeFirst();
      final int x = point.x;
      final int y = point.y;

      if (image[y][x] == oldColor) {
        image[y][x] = newColor;

        if (x > 0) {
          queue.add(Point(x - 1, y));
        }
        if (x < width - 1) {
          queue.add(Point(x + 1, y));
        }
        if (y > 0) {
          queue.add(Point(x, y - 1));
        }
        if (y < height - 1) {
          queue.add(Point(x, y + 1));
        }
      }
    }
    return image;
  }
}

class FloodFillSpanImpl extends FloodFill<List<List<int>>, int> {
  const FloodFillSpanImpl(List<List<int>> image) : super(image);

  // Check if the point is inside the canvas and matches the target color
  bool _isInside(int x, int y, int targetColor) {
    return x >= 0 && y >= 0 && x < image.length && y < image[0].length && image[x][y] == targetColor;
  }

  // Set a point to the replacement color
  void _setColor(int x, int y, int replacementColor) {
    image[x][y] = replacementColor;
  }

  @override
  List<List<int>>? fill(int startX, int startY, int newColor) {
    final targetColor = image[startX][startY];

    if (!_isInside(startX, startY, targetColor)) return null;

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
      if (_isInside(nx, y, targetColor)) {
        while (_isInside(nx - 1, y, targetColor)) {
          _setColor(nx - 1, y, newColor);
          nx--;
        }
        if (nx < x1) {
          s.add([nx, x1 - 1, y - dy, -dy]);
        }
      }

      while (x1 <= x2) {
        while (_isInside(x1, y, targetColor)) {
          _setColor(x1, y, newColor);
          x1++;
        }
        if (x1 > nx) {
          s.add([nx, x1 - 1, y + dy, dy]);
        }
        if (x1 - 1 > x2) {
          s.add([x2 + 1, x1 - 1, y - dy, -dy]);
        }
        x1++;
        while (x1 < x2 && !_isInside(x1, y, targetColor)) {
          x1++;
        }
        nx = x1;
      }
    }
    return image;
  }
}
