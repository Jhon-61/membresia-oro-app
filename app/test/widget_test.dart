import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:membresia_oro/core/dependencias.dart';
import 'package:membresia_oro/main.dart';
import 'package:membresia_oro/models/estados.dart';
import 'package:membresia_oro/models/membresia.dart';
import 'package:membresia_oro/services/afiliacion_service_simulado.dart';
import 'package:membresia_oro/services/api_odoo.dart';
import 'package:membresia_oro/services/cuenta_service.dart';
import 'package:membresia_oro/services/servicio_service.dart';
import 'package:membresia_oro/services/sesion_store.dart';

/// La app con servicios simulados (sin red). Con [token], arranca con la sesión iniciada.
Future<Widget> appDePrueba({String? token, CuentaService? cuenta}) async {
  final store = SesionStoreMemoria();
  if (token != null) await store.guardarToken(token);
  return Dependencias(
    afiliacion: AfiliacionServiceSimulado(demora: Duration.zero),
    cuenta: cuenta ?? CuentaServiceSimulado(store),
    servicios: ServicioServiceSimulado(),
    child: const MembresiaOroApp(),
  );
}

/// Cuenta que siempre rechaza la contraseña.
class _CuentaQueRechaza extends CuentaServiceSimulado {
  _CuentaQueRechaza() : super(SesionStoreMemoria());

  @override
  Future<Membresia> iniciarSesion(String email, String password) async =>
      throw const ErrorApi('Correo o contraseña incorrectos.', codigo: 401);
}

void main() {
  testWidgets('Sin sesión: bienvenida con afiliación e inicio de sesión', (tester) async {
    await tester.pumpWidget(await appDePrueba());
    await tester.pumpAndSettle();

    expect(find.text('MEMBRESÍA ORO'), findsOneWidget);
    expect(find.text('Afíliate'), findsOneWidget);
    expect(find.text('Ya soy miembro · Iniciar sesión'), findsOneWidget);
  });

  testWidgets('Con sesión guardada: abre directo "Mi membresía"', (tester) async {
    await tester.pumpWidget(await appDePrueba(token: 'simulado'));
    await tester.pumpAndSettle();

    expect(find.text('Mi membresía'), findsOneWidget);
    expect(find.text('N.º MO-000000'), findsOneWidget);
    expect(find.text('Pendiente de pago'), findsOneWidget);
  });

  testWidgets('El botón rojo abre el formulario de Servicio Oro', (tester) async {
    await tester.pumpWidget(await appDePrueba(token: 'simulado'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Solicitar Servicio Oro'));
    await tester.pumpAndSettle();

    expect(find.text('¿Para quién es el servicio?'), findsOneWidget);
    expect(find.text('Lugar del fallecimiento'), findsOneWidget);
  });

  testWidgets('El menú tiene Mis datos, contrato y eliminar cuenta', (tester) async {
    await tester.pumpWidget(await appDePrueba(token: 'simulado'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    expect(find.text('Mis datos'), findsOneWidget);
    expect(find.text('Ver mi contrato'), findsOneWidget);
    expect(find.text('Eliminar mi cuenta'), findsOneWidget);

    await tester.tap(find.text('Mis datos'));
    await tester.pumpAndSettle();
    // El teléfono se muestra sin el +502 que guarda Odoo.
    expect(find.widgetWithText(TextFormField, '55551234'), findsOneWidget);
  });

  testWidgets('Eliminar cuenta pide la contraseña', (tester) async {
    await tester.pumpWidget(await appDePrueba(token: 'simulado'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eliminar mi cuenta'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Eliminar mi cuenta'));
    await tester.pump();
    expect(find.text('Escribe tu contraseña'), findsOneWidget);
  });

  testWidgets('Agregar beneficiario avisa de los 90 días', (tester) async {
    await tester.pumpWidget(await appDePrueba(token: 'simulado'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Agregar beneficiario'), 200);
    await tester.ensureVisible(find.text('Agregar beneficiario'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Agregar beneficiario'));
    await tester.pumpAndSettle();
    expect(find.textContaining('90 días'), findsOneWidget);

    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Agregar'));
    await tester.tap(find.widgetWithText(FilledButton, 'Agregar'));
    await tester.pump();
    expect(find.text('Ingresa el número de DPI'), findsOneWidget);
  });

  testWidgets('Iniciar sesión con contraseña incorrecta muestra el error', (tester) async {
    await tester.pumpWidget(await appDePrueba(cuenta: _CuentaQueRechaza()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ya soy miembro · Iniciar sesión'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'ana@correo.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'Mala2026');
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();

    expect(find.text('Correo o contraseña incorrectos.'), findsOneWidget);
  });

  testWidgets('Afíliate abre el paso 1 y no deja avanzar con campos vacíos', (tester) async {
    await tester.pumpWidget(await appDePrueba());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Afíliate'));
    await tester.pumpAndSettle();
    expect(find.text('Paso 1 de 4'), findsOneWidget);

    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();

    // Sigue en el paso 1 y muestra los errores.
    expect(find.text('Paso 1 de 4'), findsOneWidget);
    expect(find.text('Ingresa el número de DPI'), findsOneWidget);
    expect(find.text('Escribe una contraseña'), findsOneWidget);
    expect(find.byType(SnackBar), findsOneWidget);
  });

  test('Los estados se convierten desde el valor guardado', () {
    expect(EstadoMiembro.desdeValor('mora'), EstadoMiembro.mora);
    expect(EstadoServicio.desdeValor('en_proceso'), EstadoServicio.enProceso);
  });
}
