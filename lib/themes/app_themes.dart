import 'package:flutter/material.dart';

class AppThemes {
  static const Map<String, AppTheme> themes = {
    'cyberpunk': AppTheme(
      name: 'Cyberpunk',
      bg: Color(0xFF0a0a0f),
      bg2: Color(0xFF12121a),
      card: Color(0xFF1a1a2e),
      card2: Color(0xFF252542),
      accent: Color(0xFFff2e63),
      accent2: Color(0xFF08d9d6),
      ok: Color(0xFF08d9d6),
      warn: Color(0xFFedf756),
      err: Color(0xFFff2e63),
      info: Color(0xFF3b82f6),
      t1: Color(0xFFffffff),
      t2: Color(0xFFeaeaea),
      t3: Color(0xFFaaaaaa),
      t4: Color(0xFF666666),
      gradient1: Color(0xFFff2e63),
      gradient2: Color(0xFF08d9d6),
    ),
    'midnight': AppTheme(
      name: 'Midnight',
      bg: Color(0xFF0d1b2a),
      bg2: Color(0xFF1b263b),
      card: Color(0xFF22334a),
      card2: Color(0xFF2d3f58),
      accent: Color(0xFF7b68ee),
      accent2: Color(0xFFff6b9d),
      ok: Color(0xFF4ade80),
      warn: Color(0xFFfbbf24),
      err: Color(0xFFf87171),
      info: Color(0xFF60a5fa),
      t1: Color(0xFFffffff),
      t2: Color(0xFFe2e8f0),
      t3: Color(0xFF94a3b8),
      t4: Color(0xFF64748b),
      gradient1: Color(0xFF7b68ee),
      gradient2: Color(0xFFff6b9d),
    ),
    'forest': AppTheme(
      name: 'Forest',
      bg: Color(0xFF0b1a0b),
      bg2: Color(0xFF132213),
      card: Color(0xFF1a3a1a),
      card2: Color(0xFF225522),
      accent: Color(0xFF4ade80),
      accent2: Color(0xFF22d3ee),
      ok: Color(0xFF4ade80),
      warn: Color(0xFFfde047),
      err: Color(0xFFf87171),
      info: Color(0xFF38bdf8),
      t1: Color(0xFFffffff),
      t2: Color(0xFFd1fae5),
      t3: Color(0xFF86efac),
      t4: Color(0xFF4ade80),
      gradient1: Color(0xFF4ade80),
      gradient2: Color(0xFF22d3ee),
    ),
    'light': AppTheme(
      name: 'Light',
      bg: Color(0xFFf8fafc),
      bg2: Color(0xFFf1f5f9),
      card: Color(0xFFffffff),
      card2: Color(0xFFf8fafc),
      accent: Color(0xFF6366f1),
      accent2: Color(0xFFec4899),
      ok: Color(0xFF22c55e),
      warn: Color(0xFFf59e0b),
      err: Color(0xFFef4444),
      info: Color(0xFF3b82f6),
      t1: Color(0xFF1e293b),
      t2: Color(0xFF334155),
      t3: Color(0xFF64748b),
      t4: Color(0xFF94a3b8),
      gradient1: Color(0xFF6366f1),
      gradient2: Color(0xFFec4899),
    ),
  };

  static AppTheme get(String key) => themes[key] ?? themes['cyberpunk']!;
}

class AppTheme {
  final String name;
  final Color bg, bg2, card, card2, accent, accent2, ok, warn, err, info;
  final Color t1, t2, t3, t4, gradient1, gradient2;

  const AppTheme({
    required this.name, required this.bg, required this.bg2,
    required this.card, required this.card2, required this.accent,
    required this.accent2, required this.ok, required this.warn,
    required this.err, required this.info, required this.t1,
    required this.t2, required this.t3, required this.t4,
    required this.gradient1, required this.gradient2,
  });

  ThemeData toThemeData() {
    return ThemeData(
      useMaterial3: true,
      brightness: bg.computeLuminance() < 0.5 ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: bg,
      primaryColor: accent,
      colorScheme: ColorScheme(
        brightness: bg.computeLuminance() < 0.5 ? Brightness.dark : Brightness.light,
        primary: accent, onPrimary: Colors.white,
        secondary: accent2, onSecondary: Colors.white,
        error: err, onError: Colors.white,
        surface: card, onSurface: t1,
      ),
      cardTheme: CardTheme(color: card, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
      appBarTheme: AppBarTheme(backgroundColor: bg, foregroundColor: t1, elevation: 0),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent, foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: bg2,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        hintStyle: TextStyle(color: t4),
      ),
    );
  }
}
