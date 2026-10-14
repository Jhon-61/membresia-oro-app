import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/afiliacion.dart';
import 'afiliacion_service.dart';

/// Envía la afiliación al endpoint del módulo de Odoo.
/// Contrato del endpoint: docs/API_ODOO.md
class OdooAfiliacionService implements AfiliacionService {
  OdooAfiliacionService(this.baseUrl, {http.Client? cliente}) : _cliente = cliente ?? http.Client();

  static const ruta = '/api/membresia/v1/afiliaciones';
  static const tiempoMaximo = Duration(seconds: 60);

  final String baseUrl;
  final http.Client _cliente;

  Uri get uri => Uri.parse(baseUrl.replaceFirst(RegExp(r'/+$'), '') + ruta);

  @override
  Future<ResultadoAfiliacion> enviar(SolicitudAfiliacion solicitud) async {
    try {
      final respuesta = await _cliente
          .post(
            uri,
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(solicitud.toJson()),
          )
          .timeout(tiempoMaximo);
      return interpretarRespuesta(respuesta.statusCode, respuesta.body);
    } on TimeoutException {
      return const AfiliacionFallida('El servidor tardó demasiado en responder. Intenta de nuevo.');
    } on http.ClientException catch (e) {
      return AfiliacionFallida(
        'No se pudo conectar con el servidor. Revisa tu conexión a internet.\n(${e.message})',
      );
    }
  }

  /// Solo se aceptan enlaces https (nunca se abre otra cosa en el navegador del cliente).
  static String? _urlSegura(Object? valor) {
    final uri = Uri.tryParse(valor?.toString() ?? '');
    return uri != null && uri.scheme == 'https' && uri.host.isNotEmpty ? uri.toString() : null;
  }

  /// Convierte la respuesta HTTP de Odoo en un resultado. Es pública para poder probarla.
  static ResultadoAfiliacion interpretarRespuesta(int codigo, String cuerpo) {
    Map<String, dynamic>? json;
    try {
      final decodificado = jsonDecode(cuerpo);
      if (decodificado is Map<String, dynamic>) json = decodificado;
    } on FormatException {
      json = null; // Odoo respondió algo que no es JSON (p. ej. una página de error HTML).
    }

    final exito = codigo >= 200 && codigo < 300 && json?['ok'] == true;
    if (exito) {
      return AfiliacionExitosa(
        referencia: json!['referencia']?.toString() ?? '',
        miembroId: json['miembro_id'] is int ? json['miembro_id'] as int : null,
        clienteExistente: json['cliente_existente'] == true,
        aviso: json['aviso']?.toString(),
        urlPago: _urlSegura(json['url_pago']),
        token: json['token'] is String && (json['token'] as String).isNotEmpty
            ? json['token'] as String
            : null,
      );
    }

    final errores = <String, String>{};
    final erroresJson = json?['errores'];
    if (erroresJson is Map) {
      erroresJson.forEach((campo, mensaje) => errores['$campo'] = '$mensaje');
    }

    final mensaje = json?['mensaje']?.toString() ??
        (errores.isNotEmpty
            ? 'Revisa los datos marcados.'
            : 'Ocurrió un error en el servidor (código $codigo). Intenta más tarde.');
    return AfiliacionFallida(mensaje, errores: errores);
  }
}
