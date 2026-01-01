import 'package:flutter/material.dart';

/// Utility functions for color operations
class ColorUtils {
  /// Converts a hex color string to a Color object
  /// 
  /// Returns a default purple color if parsing fails
  static Color fromHex(String hex) {
    try {
      return Color(int.parse(hex.replaceAll('#', '0xFF')));
    } catch (e) {
      return const Color(0xFF6C63FF);
    }
  }
}

