import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/dependencias.dart';
import 'core/theme/app_theme.dart';
import 'features/inicio/pantalla_arranque.dart';

// Entrada de la app del cliente (Android e iOS).
void main() {
  runApp(Dependencias.desdeConfig(child: const MembresiaOroApp()));
}

class MembresiaOroApp extends StatelessWidget {
  const MembresiaOroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Membresía Oro',
      debugShowCheckedModeBanner: false,
      theme: temaOro(),
      // Calendarios, botones del sistema y textos de Material en español.
      locale: const Locale('es'),
      supportedLocales: const [Locale('es')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      // Decide si mostrar la bienvenida o "Mi membresía" (si ya hay sesión).
      home: const PantallaArranque(),
    );
  }
}
