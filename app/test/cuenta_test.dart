import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:membresia_oro/core/formato.dart';
import 'package:membresia_oro/core/validadores.dart';
import 'package:membresia_oro/models/membresia.dart';
import 'package:membresia_oro/services/api_odoo.dart';
import 'package:membresia_oro/services/cuenta_service.dart';
import 'package:membresia_oro/services/sesion_store.dart';

const _membresiaJson = {
  'referencia': 'MO-000007',
  'nombre': 'Ana López',
  'estado': 'activo',
  'estado_texto': 'Activo',
  'fecha_alta': '2026-10-14',
  'carencia': {
    'humano': {'fecha': '2027-01-12', 'dias_restantes': 90},
    'mascota': {'fecha': '2026-10-01', 'dias_restantes': 0},
  },
  'beneficiarios': [
    {
      'id': 1, 'nombre': 'Luis', 'dpi': '1234567890101', 'parentesco': 'hijo',
      'fecha_nacimiento': '2010-05-03',
      'carencia': {'fecha': '2027-01-12', 'dias_restantes': 90},
    },
  ],
  'mascotas': [],
  'cuotas': [
    {'id': 3, 'numero': 'INV/3', 'periodo': '2026-11', 'monto': 69.99, 'pendiente': 69.99,
     'moneda': 'GTQ', 'pagada': false, 'url_pago': 'https://odoo.ejemplo.com/my/invoices/3'},
    {'id': 2, 'numero': 'INV/2', 'periodo': '2026-10', 'monto': 69.99, 'pendiente': 69.99,
     'moneda': 'GTQ', 'pagada': false, 'url_pago': 'https://odoo.ejemplo.com/my/invoices/2'},
    {'id': 1, 'numero': 'INV/1', 'periodo': '2026-09', 'monto': 69.99, 'pendiente': 0,
     'moneda': 'GTQ', 'pagada': true, 'url_pago': null},
  ],
  'deuda': {'cuotas': 2, 'monto': 139.98},
};

/// Respuesta JSON en UTF-8, como las de Odoo.
http.Response _json(Object cuerpo, int codigo) => http.Response(jsonEncode(cuerpo), codigo,
    headers: {'content-type': 'application/json; charset=utf-8'});

void main() {
  group('Membresia.desdeJson', () {
    test('lee estado, carencias, beneficiarios y deuda', () {
      final m = Membresia.desdeJson(_membresiaJson);

      expect(m.activa, isTrue);
      expect(m.carenciaHumano.diasRestantes, 90);
      expect(m.carenciaMascota.disponible, isTrue);
      expect(m.beneficiarios.single.nombre, 'Luis');
      expect(m.cuotasPendientes, 2);
      expect(m.montoPendiente, 139.98);
    });

    test('la cuota por pagar es la pendiente más antigua', () {
      expect(Membresia.desdeJson(_membresiaJson).cuotaPorPagar!.periodo, '2026-10');
    });
  });

  group('OdooCuentaService', () {
    test('al iniciar sesión guarda el token y lo usa en las siguientes peticiones', () async {
      final store = SesionStoreMemoria();
      final pedidos = <http.Request>[];
      final cliente = MockClient((peticion) async {
        pedidos.add(peticion);
        final ruta = peticion.url.path;
        if (ruta.endsWith('/sesion')) {
          return _json({'ok': true, 'token': 'tok-123', 'membresia': _membresiaJson}, 200);
        }
        return _json({'ok': true, 'membresia': _membresiaJson}, 200);
      });
      final servicio = OdooCuentaService('https://odoo.ejemplo.com', store,
          api: ApiOdoo('https://odoo.ejemplo.com', cliente: cliente, token: store.leerToken));

      await servicio.iniciarSesion(' ANA@correo.com ', 'Prueba2026');
      await servicio.obtenerMembresia();

      expect(jsonDecode(pedidos.first.body)['email'], 'ana@correo.com');
      expect(await store.leerToken(), 'tok-123');
      expect(pedidos.last.headers['Authorization'], 'Bearer tok-123');
    });

    test('si la sesión venció (401), borra el token', () async {
      final store = SesionStoreMemoria();
      await store.guardarToken('viejo');
      final cliente = MockClient(
          (_) async => _json({'ok': false, 'mensaje': 'Tu sesión expiró.'}, 401));
      final servicio = OdooCuentaService('https://odoo.ejemplo.com', store,
          api: ApiOdoo('https://odoo.ejemplo.com', cliente: cliente, token: store.leerToken));

      await expectLater(servicio.obtenerMembresia(),
          throwsA(isA<ErrorApi>().having((e) => e.sesionVencida, 'sesionVencida', isTrue)));
      expect(await store.leerToken(), isNull);
    });

    test('cambios desde Mi membresía: rutas, métodos y cuerpo', () async {
      final store = SesionStoreMemoria();
      await store.guardarToken('tok-123');
      final pedidos = <http.Request>[];
      final cliente = MockClient((peticion) async {
        pedidos.add(peticion);
        if (peticion.url.path.endsWith('/contrato')) {
          return _json({'ok': true, 'url': 'https://odoo.ejemplo.com/membresia/contrato/7/1/abc'}, 200);
        }
        if (peticion.url.path.endsWith('/eliminar')) return _json({'ok': true}, 200);
        return _json({'ok': true, 'membresia': _membresiaJson}, 200);
      });
      final servicio = OdooCuentaService('https://odoo.ejemplo.com', store,
          api: ApiOdoo('https://odoo.ejemplo.com', cliente: cliente, token: store.leerToken));

      await servicio.actualizarDatos(telefono: '44445555', direccion: ' Zona 10 ', nit: '');
      await servicio.agregarBeneficiario({'nombre': 'Rosa'});
      await servicio.editarBeneficiario(5, {'nombre': 'Rosa María'});
      await servicio.quitarBeneficiario(5);
      expect(await servicio.enlaceContrato(), contains('/membresia/contrato/7/'));

      final rutas = [for (final p in pedidos) '${p.method} ${p.url.path}'];
      expect(rutas, [
        'POST /api/membresia/v1/membresia/datos',
        'POST /api/membresia/v1/membresia/beneficiarios',
        'POST /api/membresia/v1/membresia/beneficiarios/5',
        'DELETE /api/membresia/v1/membresia/beneficiarios/5',
        'GET /api/membresia/v1/membresia/contrato',
      ]);
      expect(jsonDecode(pedidos.first.body),
          {'telefono': '44445555', 'direccion': 'Zona 10', 'nit': 'CF'});
      expect(pedidos.every((p) => p.headers['Authorization'] == 'Bearer tok-123'), isTrue);

      await servicio.eliminarCuenta('Prueba2026');
      expect(jsonDecode(pedidos.last.body), {'password': 'Prueba2026'});
      expect(await store.leerToken(), isNull, reason: 'Al eliminar la cuenta se borra la sesión');
    });

    test('errores por campo de Odoo llegan a la pantalla', () async {
      final store = SesionStoreMemoria();
      await store.guardarToken('tok-123');
      final cliente = MockClient((_) async => _json({
            'ok': false,
            'mensaje': 'Revisa los datos marcados.',
            'errores': {'beneficiario.dpi': 'El DPI debe tener 13 dígitos.'},
          }, 422));
      final servicio = OdooCuentaService('https://odoo.ejemplo.com', store,
          api: ApiOdoo('https://odoo.ejemplo.com', cliente: cliente, token: store.leerToken));

      await expectLater(
          servicio.agregarBeneficiario({}),
          throwsA(isA<ErrorApi>()
              .having((e) => e.errores['beneficiario.dpi'], 'error del DPI', contains('13'))));
      expect(await store.leerToken(), 'tok-123', reason: 'Un 422 no cierra la sesión');
    });

    test('contraseña incorrecta al eliminar: no borra la sesión', () async {
      final store = SesionStoreMemoria();
      await store.guardarToken('tok-123');
      final cliente = MockClient(
          (_) async => _json({'ok': false, 'mensaje': 'La contraseña no es correcta.'}, 401));
      final servicio = OdooCuentaService('https://odoo.ejemplo.com', store,
          api: ApiOdoo('https://odoo.ejemplo.com', cliente: cliente, token: store.leerToken));

      await expectLater(servicio.eliminarCuenta('mala'), throwsA(isA<ErrorApi>()));
      expect(await store.leerToken(), 'tok-123');
    });
  });

  test('formato de montos', () {
    expect(formatoMonto(69.99, 'GTQ'), 'Q69.99');
    expect(formatoMonto(69.99, 'USD'), r'$69.99');
    expect(formatoMonto(5, 'EUR'), '5.00 EUR');
  });

  test('reglas de contraseña iguales a las de Odoo', () {
    expect(Validadores.password('Prueba2026'), isNull);
    for (final mala in ['', 'corta1', 'sololetras', '1234567890']) {
      expect(Validadores.password(mala), isNotNull, reason: mala);
    }
  });
}
