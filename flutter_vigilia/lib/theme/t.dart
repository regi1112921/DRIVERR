import 'package:flutter/material.dart';

class T {
  static const bg       = Color(0xFF050A0F);
  static const bg2      = Color(0xFF090F16);
  static const bg3      = Color(0xFF0D1520);
  static const cyan     = Color(0xFF00E5FF);
  static const cyanDim  = Color(0x1F00E5FF);
  static const orange   = Color(0xFFFFA500);
  static const red      = Color(0xFFFF3333);
  static const green    = Color(0xFF00FF88);
  static const textDim  = Color(0xFF4A6478);
  static const text     = Color(0xFFC8DDE8);
  static const border   = Color(0x2E00E5FF);

  static ThemeData theme() => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: bg,
    colorScheme: const ColorScheme.dark(
      primary: cyan,
      secondary: green,
      error: red,
      surface: bg2,
    ),
    fontFamily: 'Rajdhani',
  );
}
