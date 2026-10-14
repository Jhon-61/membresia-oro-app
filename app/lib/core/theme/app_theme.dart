import 'package:flutter/material.dart';

/// Colores de marca de Membresía Oro · Las Golondrinas.
abstract final class ColoresOro {
  static const azulOscuro = Color(0xFF0A1931);
  static const dorado = Color(0xFFD4AF37);
  static const blanco = Color(0xFFFFFFFF);

  // Semáforo del panel admin (CONTEXTO §M2).
  static const alDia = Color(0xFF2E7D32); // verde
  static const atraso = Color(0xFFF9A825); // amarillo: 1–29 días
  static const mora = Color(0xFFC62828); // rojo: 30–60 días
  static const cancelado = Color(0xFF212121); // negro
}

/// Tema compartido por la app del cliente y el panel admin.
ThemeData temaOro() {
  final esquema = ColorScheme.fromSeed(
    seedColor: ColoresOro.azulOscuro,
    primary: ColoresOro.azulOscuro,
    secondary: ColoresOro.dorado,
  );

  return ThemeData(
    colorScheme: esquema,
    appBarTheme: const AppBarTheme(
      backgroundColor: ColoresOro.azulOscuro,
      foregroundColor: ColoresOro.blanco,
    ),
    inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: ColoresOro.dorado,
        foregroundColor: ColoresOro.azulOscuro,
        minimumSize: const Size.fromHeight(48),
      ),
    ),
  );
}
