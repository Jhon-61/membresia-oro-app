import 'package:flutter/material.dart';

import '../../core/dependencias.dart';
import '../../core/theme/app_theme.dart';
import '../membresia/pantalla_mi_membresia.dart';
import 'pantalla_inicio.dart';

/// Primera pantalla: si hay una sesión guardada va a "Mi membresía"; si no, a la bienvenida.
class PantallaArranque extends StatefulWidget {
  const PantallaArranque({super.key});

  @override
  State<PantallaArranque> createState() => _PantallaArranqueState();
}

class _PantallaArranqueState extends State<PantallaArranque> {
  late final Future<bool> _haySesion = Dependencias.de(context).cuenta.haySesion();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _haySesion,
      builder: (context, resultado) {
        if (!resultado.hasData) {
          return const Scaffold(
            backgroundColor: ColoresOro.azulOscuro,
            body: Center(child: CircularProgressIndicator(color: ColoresOro.dorado)),
          );
        }
        return resultado.data! ? const PantallaMiMembresia() : const PantallaInicio();
      },
    );
  }
}
