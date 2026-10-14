import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Error al hablar con Odoo, con un mensaje listo para mostrar al usuario.
class ErrorApi implements Exception {
  const ErrorApi(this.mensaje, {this.codigo, this.errores = const {}});

  final String mensaje;
  final int? codigo;

  /// Errores por campo que devuelve Odoo (p. ej. {"titular.email": "..."}).
  final Map<String, String> errores;

  /// La sesión venció o el token no es válido: hay que volver a iniciar sesión.
  bool get sesionVencida => codigo == 401;

  @override
  String toString() => 'ErrorApi($codigo): $mensaje';
}

/// Cliente HTTP de la API de Membresía Oro en Odoo.
///
/// Agrega el token de sesión (`Authorization: Bearer ...`) cuando existe y convierte las
/// respuestas en JSON o en un [ErrorApi]. Contrato: docs/API_ODOO.md.
class ApiOdoo {
  ApiOdoo(this.baseUrl, {http.Client? cliente, this.token})
      : _cliente = cliente ?? http.Client();

  static const tiempoMaximo = Duration(seconds: 60);

  final String baseUrl;
  final http.Client _cliente;

  /// Devuelve el token actual (o null). Se consulta en cada petición.
  final Future<String?> Function()? token;

  Uri uri(String ruta) => Uri.parse(baseUrl.replaceFirst(RegExp(r'/+$'), '') + ruta);

  Future<Map<String, dynamic>> get(String ruta) => _enviar('GET', ruta);

  Future<Map<String, dynamic>> post(String ruta, Map<String, dynamic> cuerpo) =>
      _enviar('POST', ruta, cuerpo);

  Future<Map<String, dynamic>> delete(String ruta) => _enviar('DELETE', ruta);

  Future<Map<String, dynamic>> _enviar(String metodo, String ruta,
      [Map<String, dynamic>? cuerpo]) async {
    final peticion = http.Request(metodo, uri(ruta))
      ..headers['Accept'] = 'application/json';
    final valorToken = await token?.call();
    if (valorToken != null && valorToken.isNotEmpty) {
      peticion.headers['Authorization'] = 'Bearer $valorToken';
    }
    if (cuerpo != null) {
      peticion.headers['Content-Type'] = 'application/json';
      peticion.body = jsonEncode(cuerpo);
    }

    final http.Response respuesta;
    try {
      respuesta = await http.Response.fromStream(
          await _cliente.send(peticion).timeout(tiempoMaximo));
    } on TimeoutException {
      throw const ErrorApi('El servidor tardó demasiado en responder. Intenta de nuevo.');
    } on http.ClientException {
      throw const ErrorApi('No se pudo conectar. Revisa tu conexión a internet.');
    }
    // Odoo responde en UTF-8; allowMalformed evita que un carácter dañado tumbe la app.
    return interpretar(
        respuesta.statusCode, utf8.decode(respuesta.bodyBytes, allowMalformed: true));
  }

  /// Convierte la respuesta en JSON (si `ok`) o lanza [ErrorApi]. Pública para las pruebas.
  static Map<String, dynamic> interpretar(int codigo, String cuerpo) {
    Map<String, dynamic>? json;
    try {
      final decodificado = jsonDecode(cuerpo);
      if (decodificado is Map<String, dynamic>) json = decodificado;
    } on FormatException {
      json = null; // p. ej. una página de error HTML
    }

    if (codigo >= 200 && codigo < 300 && json?['ok'] == true) return json!;

    final errores = <String, String>{};
    final erroresJson = json?['errores'];
    if (erroresJson is Map) {
      erroresJson.forEach((campo, mensaje) => errores['$campo'] = '$mensaje');
    }
    throw ErrorApi(
      json?['mensaje']?.toString() ??
          'Ocurrió un error en el servidor (código $codigo). Intenta más tarde.',
      codigo: codigo,
      errores: errores,
    );
  }
}
