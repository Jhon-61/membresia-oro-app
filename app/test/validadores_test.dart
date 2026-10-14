import 'package:flutter_test/flutter_test.dart';
import 'package:membresia_oro/core/validadores.dart';

void main() {
  group('DPI', () {
    test('acepta 13 dígitos con departamento válido', () {
      expect(Validadores.dpi('1234567890101'), isNull); // departamento 01
      expect(Validadores.dpi('1234 56789 2201'), isNull); // espacios se ignoran; depto 22
    });

    test('rechaza longitud incorrecta, vacío o departamento inexistente', () {
      expect(Validadores.dpi(''), isNotNull);
      expect(Validadores.dpi('123456789010'), isNotNull); // 12 dígitos
      expect(Validadores.dpi('1234567892301'), isNotNull); // departamento 23
      expect(Validadores.dpi('1234567890001'), isNotNull); // departamento 00
    });
  });

  test('teléfono de 8 dígitos', () {
    expect(Validadores.telefono('5555-1234'), isNull);
    expect(Validadores.telefono('555512'), isNotNull);
  });

  test('correo electrónico', () {
    expect(Validadores.email('ana@correo.com'), isNull);
    expect(Validadores.email('ana@correo'), isNotNull);
    expect(Validadores.email(''), isNotNull);
  });

  group('NIT', () {
    test('vacío o CF es consumidor final', () {
      expect(Validadores.nit(''), isNull);
      expect(Validadores.nit('cf'), isNull);
      expect(Validadores.normalizarNit('  '), 'CF');
    });

    // Mismos casos que las pruebas del módulo de Odoo (mismo algoritmo que base_vat).
    test('acepta NIT con dígito verificador correcto, con guion y K final', () {
      expect(Validadores.nit('1234567-9'), isNull);
      expect(Validadores.nit('9876543-4'), isNull);
      expect(Validadores.nit('576937-k'), isNull);
      expect(Validadores.normalizarNit('576937-k'), '576937K');
    });

    test('rechaza dígito verificador equivocado y texto inválido', () {
      expect(Validadores.nit('1234567-8'), contains('verificador'));
      expect(Validadores.nit('ABC'), isNotNull);
    });
  });

  test('peso de mascota acepta coma decimal', () {
    expect(Validadores.convertirPeso('12,5'), 12.5);
    expect(Validadores.pesoKg('12,5'), isNull);
    expect(Validadores.pesoKg('0'), isNotNull);
    expect(Validadores.pesoKg(''), isNotNull);
  });
}
