import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/constantes.dart';
import 'core/theme/app_theme.dart';
import 'features/afiliacion/pantalla_afiliacion.dart';

// Entrada de la app del CLIENTE (Android, iOS, Web).
// El panel admin tiene su propia entrada: lib/main_admin.dart
void main() {
  runApp(const MembresiaOroApp());
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
      home: const PantallaInicio(),
    );
  }
}

// Pantalla de bienvenida provisional (la landing real será el sitio web en Odoo).
class PantallaInicio extends StatelessWidget {
  const PantallaInicio({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColoresOro.azulOscuro,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.workspace_premium, size: 72, color: ColoresOro.dorado),
              const SizedBox(height: 16),
              const Text(
                'MEMBRESÍA ORO',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: ColoresOro.dorado,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const Text(
                'LAS GOLONDRINAS',
                textAlign: TextAlign.center,
                style: TextStyle(color: ColoresOro.blanco, letterSpacing: 4),
              ),
              const SizedBox(height: 32),
              const Text(
                '$cuotaMensualTexto al mes · 5 personas + 1 mascota',
                textAlign: TextAlign.center,
                style: TextStyle(color: ColoresOro.blanco, fontSize: 16),
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PantallaAfiliacion()),
                ),
                child: const Text('Afíliate'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
