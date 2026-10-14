import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:membresia_oro/models/afiliacion.dart';
import 'package:membresia_oro/services/afiliacion_service.dart';
import 'package:membresia_oro/services/odoo_afiliacion_service.dart';

ArchivoAdjunto _imagen(String nombre) =>
    ArchivoAdjunto(bytes: Uint8List.fromList([1, 2, 3]), nombre: nombre, mime: 'image/jpeg');

SolicitudAfiliacion _solicitud({Mascota? mascota}) => SolicitudAfiliacion(
      titular: const Titular(
        nombre: 'Ana López',
        dpi: '1234567890101',
        telefono: '55551234',
        email: 'ana@correo.com',
        direccion: 'Zona 1, Guatemala',
        nit: 'CF',
      ),
      dpiFrente: _imagen('frente.jpg'),
      dpiReverso: _imagen('reverso.jpg'),
      beneficiarios: [
        Beneficiario(
          nombre: 'Luis López',
          dpi: '1234567890101',
          parentesco: Parentesco.hijo,
          fechaNacimiento: DateTime(2010, 5, 3),
        ),
      ],
      mascota: mascota,
      firma: ArchivoAdjunto(bytes: Uint8List.fromList([9]), nombre: 'firma.png', mime: 'image/png'),
      aceptaTerminos: true,
      origen: 'app_android',
    );

void main() {
  group('JSON de la solicitud (contrato en docs/API_ODOO.md)', () {
    test('usa los nombres de campo y formatos acordados', () {
      final json = _solicitud().toJson();

      expect(json['titular']['dpi'], '1234567890101');
      expect(json['titular']['nit'], 'CF');
      expect(json['beneficiarios'][0]['parentesco'], 'hijo');
      expect(json['beneficiarios'][0]['fecha_nacimiento'], '2010-05-03');
      expect(json['dpi_frente']['base64'], base64Encode([1, 2, 3]));
      expect(json['mascota'], isNull);
      expect(json['acepta_terminos'], isTrue);
      expect(json['version_terminos'], isNotEmpty);
    });

    test('incluye la mascota con su foto y peso', () {
      final json = _solicitud(
        mascota: Mascota(
          nombre: 'Firulais',
          especie: Especie.perro,
          raza: 'Mestizo',
          pesoKg: 28.5,
          foto: _imagen('perro.jpg'),
        ),
      ).toJson();

      expect(json['mascota']['especie'], 'perro');
      expect(json['mascota']['peso_kg'], 28.5);
      expect(json['mascota']['foto']['nombre_archivo'], 'perro.jpg');
    });
  });

  group('OdooAfiliacionService', () {
    test('envía un POST con JSON a la ruta del módulo', () async {
      late http.Request recibida;
      final cliente = MockClient((peticion) async {
        recibida = peticion;
        return http.Response(
          jsonEncode({'ok': true, 'miembro_id': 7, 'referencia': 'MO-000007'}),
          201,
        );
      });

      final servicio = OdooAfiliacionService('https://ejemplo.odoo.com/', cliente: cliente);
      final resultado = await servicio.enviar(_solicitud());

      expect(recibida.method, 'POST');
      expect(recibida.url.toString(), 'https://ejemplo.odoo.com/api/membresia/v1/afiliaciones');
      expect(recibida.headers['Content-Type'], startsWith('application/json'));
      expect(jsonDecode(recibida.body)['titular']['nombre'], 'Ana López');

      expect(resultado, isA<AfiliacionExitosa>());
      expect((resultado as AfiliacionExitosa).referencia, 'MO-000007');
      expect(resultado.miembroId, 7);
    });

    test('cliente que ya existía: 200 con aviso', () {
      final resultado = OdooAfiliacionService.interpretarRespuesta(
        200,
        jsonEncode({
          'ok': true,
          'miembro_id': 9,
          'referencia': 'MO-000009',
          'cliente_existente': true,
          'aviso': 'Ya estabas registrado como cliente: agregamos la Membresía Oro a tu cuenta.',
        }),
      );

      expect(resultado, isA<AfiliacionExitosa>());
      resultado as AfiliacionExitosa;
      expect(resultado.clienteExistente, isTrue);
      expect(resultado.aviso, contains('Ya estabas registrado'));
    });

    test('convierte los errores por campo de Odoo', () {
      final resultado = OdooAfiliacionService.interpretarRespuesta(
        422,
        jsonEncode({
          'ok': false,
          'errores': {'titular.dpi': 'Ya existe un miembro con este DPI'},
        }),
      );

      expect(resultado, isA<AfiliacionFallida>());
      expect((resultado as AfiliacionFallida).errores['titular.dpi'], contains('Ya existe'));
    });

    test('maneja respuestas que no son JSON (p. ej. error 500 en HTML)', () {
      final resultado = OdooAfiliacionService.interpretarRespuesta(500, '<html>Error</html>');

      expect(resultado, isA<AfiliacionFallida>());
      expect((resultado as AfiliacionFallida).mensaje, contains('500'));
    });

    test('un error de conexión no rompe la app', () async {
      final cliente = MockClient((_) async => throw http.ClientException('sin red'));
      final servicio = OdooAfiliacionService('https://ejemplo.odoo.com', cliente: cliente);

      final resultado = await servicio.enviar(_solicitud());

      expect(resultado, isA<AfiliacionFallida>());
    });
  });
}
