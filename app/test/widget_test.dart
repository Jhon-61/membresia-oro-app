import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:membresia_oro/main.dart';
import 'package:membresia_oro/models/estados.dart';

void main() {
  testWidgets('La pantalla de inicio muestra la marca y el botón de afiliación', (tester) async {
    await tester.pumpWidget(const MembresiaOroApp());

    expect(find.text('MEMBRESÍA ORO'), findsOneWidget);
    expect(find.text('Afíliate'), findsOneWidget);
  });

  testWidgets('Afíliate abre el paso 1 y no deja avanzar con campos vacíos', (tester) async {
    await tester.pumpWidget(const MembresiaOroApp());

    await tester.tap(find.text('Afíliate'));
    await tester.pumpAndSettle();
    expect(find.text('Paso 1 de 4'), findsOneWidget);

    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();

    // Sigue en el paso 1 y muestra los errores.
    expect(find.text('Paso 1 de 4'), findsOneWidget);
    expect(find.text('Ingresa el número de DPI'), findsOneWidget);
    expect(find.text('Agrega la foto del frente del DPI'), findsOneWidget);
    expect(find.byType(SnackBar), findsOneWidget);
  });

  test('Los estados se convierten desde el valor guardado', () {
    expect(EstadoMiembro.desdeValor('mora'), EstadoMiembro.mora);
    expect(EstadoServicio.desdeValor('en_proceso'), EstadoServicio.enProceso);
  });
}
