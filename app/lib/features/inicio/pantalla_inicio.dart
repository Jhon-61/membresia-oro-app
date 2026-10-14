import 'package:flutter/material.dart';

import '../../core/constantes.dart';
import '../../core/theme/app_theme.dart';
import '../afiliacion/pantalla_afiliacion.dart';
import '../cuenta/pantalla_login.dart';

/// Bienvenida para quien no tiene sesión: afiliarse o iniciar sesión.
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
              Center(
                child: Image.asset(
                  'assets/marca/emblema.png',
                  height: 160,
                  semanticLabel: 'Emblema de Membresía Oro · Las Golondrinas',
                ),
              ),
              const SizedBox(height: 24),
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
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PantallaLogin()),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: ColoresOro.blanco,
                  side: const BorderSide(color: ColoresOro.dorado),
                  minimumSize: const Size.fromHeight(48),
                ),
                child: const Text('Ya soy miembro · Iniciar sesión'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
