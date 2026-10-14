import '../models/afiliacion.dart';
import '../models/membresia.dart';
import 'api_odoo.dart';

/// Resultado de los "candados": si puede usar el beneficio, por qué no, o cuánto cuesta.
class Candado {
  const Candado({
    required this.permitido,
    required this.mensaje,
    this.cargo = 0,
    this.diasRestantes = 0,
  });

  factory Candado.desdeJson(Map<String, dynamic> json) => Candado(
        permitido: json['permitido'] == true,
        mensaje: '${json['mensaje'] ?? ''}',
        cargo: json['cargo'] is num ? (json['cargo'] as num).toDouble() : 0,
        diasRestantes: json['dias_restantes'] is int ? json['dias_restantes'] as int : 0,
      );

  final bool permitido;
  final String mensaje;
  final double cargo;
  final int diasRestantes;
}

/// Datos del formulario "Solicitar Servicio Oro".
class SolicitudServicio {
  const SolicitudServicio({
    required this.tipo,
    required this.lugar,
    required this.contactoNombre,
    required this.contactoTelefono,
    this.beneficiarioId,
    this.mascotaId,
    this.notas = '',
    this.dpiFoto,
  });

  /// 'humano' o 'mascota'
  final String tipo;
  final int? beneficiarioId;
  final int? mascotaId;
  final String lugar;
  final String contactoNombre;
  final String contactoTelefono;
  final String notas;
  final ArchivoAdjunto? dpiFoto;

  Map<String, dynamic> toJson() => {
        'tipo': tipo,
        'beneficiario_id': beneficiarioId,
        'mascota_id': mascotaId,
        'lugar': lugar,
        'contacto_nombre': contactoNombre,
        'contacto_telefono': contactoTelefono,
        'notas': notas,
        'dpi_foto': dpiFoto?.toJson(),
      };
}

class ServicioCreado {
  const ServicioCreado({required this.servicio, required this.mensaje});

  final ServicioInfo servicio;
  final String mensaje;
}

abstract interface class ServicioService {
  /// ¿Puede usar el beneficio para esa persona? (antes de enviar la solicitud)
  Future<Candado> evaluar(String tipo, {int? beneficiarioId, int? mascotaId});

  /// Envía la solicitud. Lanza [ErrorApi] si no se permite o hay datos inválidos.
  Future<ServicioCreado> solicitar(SolicitudServicio solicitud);
}

class OdooServicioService implements ServicioService {
  OdooServicioService(this._api);

  final ApiOdoo _api;
  static const ruta = '/api/membresia/v1/servicios';

  @override
  Future<Candado> evaluar(String tipo, {int? beneficiarioId, int? mascotaId}) async {
    final parametros = {
      'tipo': tipo,
      if (beneficiarioId != null) 'beneficiario_id': '$beneficiarioId',
      if (mascotaId != null) 'mascota_id': '$mascotaId',
    };
    final json = await _api.get('$ruta/evaluar?${Uri(queryParameters: parametros).query}');
    return Candado.desdeJson(json);
  }

  @override
  Future<ServicioCreado> solicitar(SolicitudServicio solicitud) async {
    final json = await _api.post(ruta, solicitud.toJson());
    return ServicioCreado(
      servicio: ServicioInfo.desdeJson(json['servicio'] as Map<String, dynamic>),
      mensaje: '${json['mensaje'] ?? ''}',
    );
  }
}

/// Sin Odoo: siempre permite y responde una solicitud de ejemplo.
class ServicioServiceSimulado implements ServicioService {
  @override
  Future<Candado> evaluar(String tipo, {int? beneficiarioId, int? mascotaId}) async =>
      const Candado(permitido: true, mensaje: 'Puedes usar tu Servicio Oro.');

  @override
  Future<ServicioCreado> solicitar(SolicitudServicio solicitud) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return ServicioCreado(
      servicio: ServicioInfo.desdeJson({
        'id': 1, 'numero': 'SO-000000', 'tipo_texto': 'Servicio funerario',
        'persona': 'Prueba', 'estado': 'pendiente', 'estado_texto': 'Pendiente',
        'fecha_solicitud': '2026-10-14 10:00:00', 'cargo': 0,
      }),
      mensaje: 'Puedes usar tu Servicio Oro.',
    );
  }
}
