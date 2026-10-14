import '../core/config.dart';
import '../models/afiliacion.dart';
import 'afiliacion_service_simulado.dart';
import 'odoo_afiliacion_service.dart';

/// Envía una solicitud de afiliación al backend.
///
/// Las pantallas solo conocen esta interfaz, no saben si del otro lado está Odoo
/// o el servicio simulado. Así se puede probar la app sin tener el módulo de Odoo listo.
abstract interface class AfiliacionService {
  Future<ResultadoAfiliacion> enviar(SolicitudAfiliacion solicitud);

  /// Elige la implementación según la configuración (ver core/config.dart).
  static AfiliacionService desdeConfig() => Config.usarOdoo
      ? OdooAfiliacionService(Config.odooUrl)
      : AfiliacionServiceSimulado();
}

/// Resultado de enviar la afiliación: exitosa o fallida (sealed = solo estas dos opciones).
sealed class ResultadoAfiliacion {
  const ResultadoAfiliacion();
}

class AfiliacionExitosa extends ResultadoAfiliacion {
  const AfiliacionExitosa({
    required this.referencia,
    this.miembroId,
    this.clienteExistente = false,
    this.aviso,
  });

  /// Número de afiliación para mostrar al cliente (p. ej. "MO-000123").
  final String referencia;
  final int? miembroId;

  /// true si la persona ya era cliente en Odoo y se le agregó la membresía.
  final bool clienteExistente;

  /// Mensaje de Odoo para mostrar al usuario (p. ej. "Ya estabas registrado como cliente…").
  final String? aviso;
}

class AfiliacionFallida extends ResultadoAfiliacion {
  const AfiliacionFallida(this.mensaje, {this.errores = const {}});

  final String mensaje;

  /// Errores por campo que devuelve Odoo, p. ej. {"titular.dpi": "Ya existe un miembro con este DPI"}.
  final Map<String, String> errores;
}
