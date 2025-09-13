import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class RetroFilters {
  static ColorFilter get sepia => const ColorFilter.matrix([
        0.393, 0.769, 0.189, 0, 0,
        0.349, 0.686, 0.168, 0, 0,
        0.272, 0.534, 0.131, 0, 0,
        0, 0, 0, 1, 0,
      ]);

  static ColorFilter get blackAndWhite => const ColorFilter.matrix([
        0.2126, 0.7152, 0.0722, 0, 0,
        0.2126, 0.7152, 0.0722, 0, 0,
        0.2126, 0.7152, 0.0722, 0, 0,
        0, 0, 0, 1, 0,
      ]);

  static ColorFilter get vintage => const ColorFilter.matrix([
        0.5, 0.5, 0.1, 0, 0,
        0.3, 0.5, 0.1, 0, 0,
        0.2, 0.3, 0.1, 0, 0,
        0, 0, 0, 1, 0,
      ]);

  static ColorFilter? getFilter(String? filterType) {
    switch (filterType) {
      case 'sepia':
        return sepia;
      case 'blackAndWhite':
        return blackAndWhite;
      case 'vintage':
        return vintage;
      default:
        return null;
    }
  }
}