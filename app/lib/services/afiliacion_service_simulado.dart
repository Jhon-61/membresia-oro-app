import 'package:flutter/foundation.dart';

import '../models/afiliacion.dart';
import 'afiliacion_service.dart';

/// Servicio de prueba: NO envía nada. Espera un momento (como si fuera la red)
/// e imprime en la consola un resumen de lo que se habría enviado a Odoo.
class AfiliacionServiceSimulado implements AfiliacionService {
  AfiliacionServiceSimulado({this.demora = const Duration(seconds: 2)});

  final Duration demora;

  @override
  Future<ResultadoAfiliacion> enviar(SolicitudAfiliacion solicitud) async {
    await Future<void>.delayed(demora);

    final kbTotales = [
      solicitud.dpiFrente,
      solicitud.dpiReverso,
      solicitud.firma,
      if (solicitud.mascota != null) solicitud.mascota!.foto,
    ].fold<int>(0, (suma, archivo) => suma + archivo.tamanoKb);

    debugPrint('── Afiliación SIMULADA (no se envió a Odoo) ──');
    debugPrint('Titular: ${solicitud.titular.nombre} · DPI ${solicitud.titular.dpi}');
    debugPrint('Beneficiarios: ${solicitud.beneficiarios.length}');
    debugPrint('Mascota: ${solicitud.mascota?.nombre ?? 'ninguna'}');
    debugPrint('Imágenes: $kbTotales KB en total');

    final referencia = 'SIM-${DateTime.now().millisecondsSinceEpoch % 1000000}';
    return AfiliacionExitosa(referencia: referencia);
  }
}
