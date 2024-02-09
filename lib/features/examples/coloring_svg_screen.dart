import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_drawing/path_drawing.dart';
import 'package:xml/xml.dart';

class ColoringSvgScreen extends StatefulWidget {
  const ColoringSvgScreen({super.key});

  @override
  State<ColoringSvgScreen> createState() => _ColoringSvgScreenState();
}

class _ColoringSvgScreenState extends State<ColoringSvgScreen> {
  final repaintKey = GlobalKey();

  Size? _size;
  List<PathSvgItem>? _items;
  List<Color>? _colors;

  Future<void> _init() async {
    final value = await getPathSvgItems('assets/images/dog-with-smile.svg');
    setState(() {
      _items = value.items;
      _size = value.size;
      _colors = List.generate(_items!.length, (index) {
        final element = _items![index];
        return element.fill == Colors.black ? element.fill! : Colors.white;
      });
    });
  }

  @override
  void initState() {
    _init();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _items == null || _size == null
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: FittedBox(
                child: RepaintBoundary(
                  key: repaintKey,
                  child: SizedBox(
                    width: _size!.width,
                    height: _size!.height,
                    child: Stack(
                      children: [
                        for (int index = 0; index < _items!.length; index++)
                          SvgPainterImage(
                            item: _items![index],
                            onTap: () {
                              setState(() {
                                _colors![index] = Colors.red;
                              });
                            },
                            fillColor: _colors![index],
                          )
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Future<({List<PathSvgItem> items, Size? size})> getPathSvgItems(String source) async {
    String generalString = await rootBundle.loadString(source);

    return _getList(generalString);
  }

  ({List<PathSvgItem> items, Size? size}) _getList(String generalString) {
    List<PathSvgItem> items = [];
    XmlDocument document = XmlDocument.parse(generalString);

    Size? size;
    double scaleX = 1.0;
    double scaleY = 1.0;

    double? translateX;
    double? translateY;

    final paths = document.findAllElements('path').toList();
    var width = document.findAllElements('svg').first.getAttribute('width');
    var height = document.findAllElements('svg').first.getAttribute('height');
    var viewBox = document.findAllElements('svg').first.getAttribute('viewBox');
    var gElement = document.findAllElements('g');

    if (gElement.isNotEmpty) {
      var transformAttribute = gElement.first.getAttribute('transform');
      if (transformAttribute != null) {
        final scale = _getScale(transformAttribute);
        if (scale != null) {
          scaleX = scale.x;
          scaleY = scale.y;
        }
        final translate = _getTranslate(transformAttribute);
        if (translate != null) {
          translateX = translate.x;
          translateY = translate.y;
        }
      }
    }

    if (width != null && height != null) {
      width = width.replaceAll(RegExp(r'[^0-9.]'), '');
      height = height.replaceAll(RegExp(r'[^0-9.]'), '');
      size = Size(double.parse(width), double.parse(height));
    } else if (viewBox != null) {
      var viewBoxList = viewBox.split(' ');
      size = Size(double.parse(viewBoxList[2]), double.parse(viewBoxList[3]));
    }

    for (int i = 0; i < paths.length; i++) {
      final element = paths[i];
      String? partPath = element.getAttribute('d');
      String? strokeWidth = element.getAttribute('stroke-width');
      String? strokeMeterLimit = element.getAttribute('stroke-meterlimit');
      String? strokeLinecap = element.getAttribute('stroke-linecap');
      String? strokeLinejoin = element.getAttribute('stroke-linejoin');
      String? fill = element.getAttribute('fill');
      var transformAttribute = element.getAttribute('transform');
      if (transformAttribute != null) {
        final scale = _getScale(transformAttribute);
        if (scale != null) {
          scaleX = scale.x;
          scaleY = scale.y;
        }
        final translate = _getTranslate(transformAttribute);
        if (translate != null) {
          translateX = translate.x;
          translateY = translate.y;
        }
      }

      var style = element.getAttribute('style');
      if (style != null) {
        fill = _getFillColor(style);
      }

      if (items.any((element) => element.path == partPath)) {
        items.removeWhere((element) => element.path == partPath);
      }

      if (partPath == null) {
        continue;
      }
      items.add(PathSvgItem(
        fill: fill != null ? adjustColorToPureBlack(getColorFromString(fill)) : null,
        path: partPath,
        strokeWidth: strokeWidth,
        strokeMeterLimit: strokeMeterLimit,
        strokeLinecap: strokeLinecap,
        strokeLinejoin: strokeLinejoin,
        scaleX: scaleX,
        scaleY: scaleY,
        translateX: translateX,
        translateY: translateY,
      ));
    }

    return (items: items, size: size);
  }

  ({double x, double y})? _getScale(String data) {
    RegExp regExp = RegExp(r'scale\(([^,]+),([^)]+)\)');
    var match = regExp.firstMatch(data);

    if (match != null) {
      double scaleX = double.parse(match.group(1)!);
      double scaleY = double.parse(match.group(2)!);

      return (x: scaleX, y: scaleY);
    } else {
      return null;
    }
  }

  ({double x, double y})? _getTranslate(String data) {
    RegExp regExp = RegExp(r'translate\(([^,]+),([^)]+)\)');
    var match = regExp.firstMatch(data);

    if (match != null) {
      double translateX = double.parse(match.group(1)!);
      double translateY = double.parse(match.group(2)!);

      return (x: translateX, y: translateY);
    } else {
      return null;
    }
  }

  String? _getFillColor(String data) {
    RegExp regExp = RegExp(r'fill:\s*(#[a-fA-F0-9]{6})');
    RegExpMatch? match = regExp.firstMatch(data);

    return match?.group(1);
  }

  Color hexToColor(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 6 || hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  Color getColorFromString(String colorString) {
    if (colorString.startsWith('#')) {
      return hexToColor(colorString);
    } else {
      switch (colorString) {
        case 'red':
          return Colors.red;
        case 'green':
          return Colors.green;
        case 'blue':
          return Colors.blue;
        case 'yellow':
          return Colors.yellow;
        case 'white':
          return Colors.white;
        case 'black':
          return Colors.black;
        default:
          return Colors.transparent;
      }
    }
  }

  Color adjustColorToPureBlack(Color color) {
    // Define the near black thresholds
    int lowThreshold = 100;

    int red = color.red;
    int green = color.green;
    int blue = color.blue;

    // Calculate average to determine brightness
    double avg = (red + green + blue) / 3.0;

    // If the color is closer to black, turn it into pure black
    if (avg < lowThreshold) {
      return const Color(0xFF000000); // pure black
    } else {
      return color; // returns the color as is if it's not close to black or white
    }
  }
}

class SvgPainterImage extends StatelessWidget {
  const SvgPainterImage({super.key, required this.item, required this.onTap, required this.fillColor});
  final PathSvgItem item;
  final VoidCallback onTap;
  final Color fillColor;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: SvgPainter(item),
      child: ClipPath(
        clipper: SvgClipper(item),
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            color: item.fill == Colors.black ? item.fill : fillColor,
          ),
        ),
      ),
    );
  }
}

class SvgPainter extends CustomPainter {
  const SvgPainter(this.pathSvgItem);

  final PathSvgItem pathSvgItem;

  @override
  void paint(Canvas canvas, Size size) {
    Path path = parseSvgPathData(pathSvgItem.path);
    final paint = Paint()..isAntiAlias = true;

    paint.color = Colors.black;
    paint.style = PaintingStyle.stroke;
    if (pathSvgItem.strokeLinecap != null) {
      switch (pathSvgItem.strokeLinecap) {
        case 'butt':
          paint.strokeCap = StrokeCap.butt;
          break;
        case 'round':
          paint.strokeCap = StrokeCap.round;
          break;
        case 'square':
          paint.strokeCap = StrokeCap.square;
          break;
      }
    }
    if (pathSvgItem.strokeLinejoin != null) {
      switch (pathSvgItem.strokeLinejoin) {
        case 'bevel':
          paint.strokeJoin = StrokeJoin.bevel;
          break;
        case 'miter':
          paint.strokeJoin = StrokeJoin.miter;
          break;
        case 'round':
          paint.strokeJoin = StrokeJoin.round;
          break;
      }
    }

    if (pathSvgItem.strokeMeterLimit != null) {
      paint.strokeMiterLimit = double.parse(pathSvgItem.strokeMeterLimit!);
    }

    if (pathSvgItem.strokeWidth != null) {
      paint.strokeWidth = double.parse(pathSvgItem.strokeWidth!);
    }

    final Matrix4 matrix4 = Matrix4.identity();

    if (pathSvgItem.translateX != null && pathSvgItem.translateX != null) {
      matrix4.translate(pathSvgItem.translateX!, pathSvgItem.translateY!);
    }

    matrix4.scale(pathSvgItem.scaleX, pathSvgItem.scaleY);

    path = path.transform(matrix4.storage);

    canvas.drawPath(path, paint);
  }

  @override
  bool? hitTest(Offset position) {
    return false;
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

class SvgClipper extends CustomClipper<Path> {
  const SvgClipper(this.pathSvgItem);

  final PathSvgItem pathSvgItem;

  @override
  Path getClip(Size size) {
    Path path = parseSvgPathData(pathSvgItem.path);
    final Matrix4 matrix4 = Matrix4.identity();

    if (pathSvgItem.translateX != null && pathSvgItem.translateX != null) {
      matrix4.translate(pathSvgItem.translateX!, pathSvgItem.translateY!);
    }

    matrix4.scale(pathSvgItem.scaleX, pathSvgItem.scaleY);

    path = path.transform(matrix4.storage);
    return path;
  }

  @override
  bool shouldReclip(CustomClipper oldClipper) {
    return true;
  }
}

class PathSvgItem {
  const PathSvgItem({
    required this.path,
    this.strokeWidth,
    this.strokeMeterLimit,
    this.strokeLinecap,
    this.strokeLinejoin,
    this.fill,
    this.scaleX = 1,
    this.scaleY = 1,
    this.translateX,
    this.translateY,
  });

  final String path;
  final String? strokeWidth;
  final String? strokeMeterLimit;
  final String? strokeLinecap;
  final String? strokeLinejoin;
  final Color? fill;
  final double scaleX;
  final double scaleY;
  final double? translateX;
  final double? translateY;
}
