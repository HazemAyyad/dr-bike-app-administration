import 'package:flutter/material.dart';

class ScreenUtilNew {
  static double? _width;
  static double? _height;

  // Initializes the dimensions based on the given context.
  static void init(BuildContext context) {
    _width = MediaQuery.of(context).size.width;
    _height = MediaQuery.of(context).size.height;
  }

  // Returns the scaled width based on the reference width (430).
  static double width(double width1) {
    assert(_width != null,
        'ScreenUtilNew has not been initialized. Call init() first.');
    return (width1 / 430) * _width!;
  }

  // Returns the scaled height based on the reference height (932).
  static double height(double height1) {
    assert(_height != null,
        'ScreenUtilNew has not been initialized. Call init() first.');
    return (height1 / 932) * _height!;
  }

  // Resets the dimensions to null, useful if you need to reinitialize.
  static void reset() {
    _width = null;
    _height = null;
  }
}
