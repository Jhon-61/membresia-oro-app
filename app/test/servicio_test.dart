import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:membresia_oro/models/membresia.dart';
import 'package:membresia_oro/services/api_odoo.dart';
import 'package:membresia_oro/services/servicio_service.dart';

http.Response _json(Object cuerpo, int codigo) => http.Response(jsonEncode(cuerpo), codigo,
    headers: {'content-type': 'application/json; charset=utf-8'});

void main() {
  test('evaluar envía tipo y persona, y lee el candado', () async {
    late http.Request pedido;
    final api = ApiOdoo('https://odoo.ejemplo.com',
        cliente: MockClient((peticion) async {
          pedido = peticion;
          return _json({
            'ok': true, 'permitido': false, 'dias_restantes': 23,
            'mensaje': 'Te faltan 23 días para usar este beneficio.', 'cargo': 0,
          }, 200);
        }),
        token: () async => 'tok');

    final candado = await OdooServicioService(api).evaluar('humano', beneficiarioId: 5);

    expect(pedido.url.path, '/api/membresia/v1/servicios/evaluar');
    expect(pedido.url.queryParameters, {'tipo': 'humano', 'beneficiario_id': '5'});
    expect(pedido.headers['Authorization'], 'Bearer tok');
    expect(candado.permitido, isFalse);
    expect(candado.diasRestantes, 23);
  });

  test('si el candado no lo permite, solicitar lanza el motivo', () async {
    final api = ApiOdoo('https://odoo.ejemplo.com',
        cliente: MockClient((_) async => _json(
            {'ok': false, 'mensaje': 'Tu membresía aún no está activa: paga tu primera cuota.'},
            422)));
    final solicitud = const SolicitudServicio(
        tipo: 'humano', lugar: 'Hospital', contactoNombre: 'Luis', contactoTelefono: '55554444');

    await expectLater(
      OdooServicioService(api).solicitar(solicitud),
      throwsA(isA<ErrorApi>().having((e) => e.mensaje, 'mensaje', contains('primera cuota'))),
    );
  });

  test('servicios en "Mi membresía" con cargo pendiente', () {
    final m = Membresia.desdeJson({
      'servicios': [
        {
          'id': 1, 'numero': 'SO-000001', 'tipo_texto': 'Servicio funerario', 'persona': 'Luis',
          'estado': 'pendiente', 'estado_texto': 'Pendiente', 'fecha_solicitud': '2026-10-14 10:00:00',
          'cargo': 3480, 'url_pago': 'https://odoo.ejemplo.com/my/invoices/9',
        },
      ],
    });
    final servicio = m.servicios.single;
    expect(servicio.numero, 'SO-000001');
    expect(servicio.cargo, 3480);
    expect(servicio.urlPago, isNotNull);
    expect(servicio.fechaSolicitud, DateTime(2026, 10, 14));
  });
}
