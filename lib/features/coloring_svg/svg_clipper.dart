import 'package:flutter/material.dart';

import 'models.dart';

class SvgClipper extends CustomClipper<Path> {
  const SvgClipper(this.pathSvgItem);

  final PathSvgItem pathSvgItem;

  @override
  Path getClip(Size size) {
    Path path = pathSvgItem.path;

    return path;
  }

  @override
  bool shouldReclip(CustomClipper oldClipper) => false;
}
