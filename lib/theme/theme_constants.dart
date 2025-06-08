import 'package:flutter/material.dart';

class ThemeConstants {
  static const animationDuration = Duration(milliseconds: 800);
  
  // Day Mode Colors (Original)
  static const dayPrimaryGradient = LinearGradient(
    colors: [Color(0xFFFF9966), Color(0xFFFF5E62)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const daySecondaryGradient = LinearGradient(
    colors: [Color(0xFFFFC371), Color(0xFFFFE3A9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const dayAccent = Color(0xFFE74C3C);
  
  static List<List<Color>> dayBackgroundGradients = [
    [Color(0xFFFFF6E9), Color(0xFFFFE0C4)],
    [Color(0xFFFFE0C4), Color(0xFFFFC8A2)],
    [Color(0xFFFFC8A2), Color(0xFFFFF6E9)],
  ];
  
  static final dayCardColor = Colors.white;
  
  // Night Mode Colors (Mystical)
  static const nightPrimaryGradient = LinearGradient(
    colors: [Color(0xFF1A237E), Color(0xFF303F9F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const nightSecondaryGradient = LinearGradient(
    colors: [Color(0xFF283593), Color(0xFF5C6BC0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const nightAccent = Color(0xFF9C27B0);
  
  static List<List<Color>> nightBackgroundGradients = [
    [Color(0xFF0F1F3D), Color(0xFF162955)],
    [Color(0xFF162955), Color(0xFF1D3671)],
    [Color(0xFF1D3671), Color(0xFF0F1F3D)],
  ];
  
  static final nightCardColor = const Color(0xFF1E2756);
  
  // Typography
  static const fontFamily = 'Poppins';
} 