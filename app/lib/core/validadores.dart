/// Validadores de los formularios.
/// Devuelven null si el valor es válido, o el mensaje de error que se muestra debajo del campo.
///
/// Importante: esto solo ayuda al usuario a corregir errores rápido.
/// Odoo debe volver a validar todo, porque la app se puede manipular.
abstract final class Validadores {
  static String? requerido(String? valor) {
    if (valor == null || valor.trim().isEmpty) return 'Este campo es obligatorio';
    return null;
  }

  /// CUI / DPI de Guatemala: 13 dígitos. Los dígitos 10 y 11 son el departamento (01 a 22).
  /// Pendiente: validar el dígito verificador cuando lo probemos con DPIs reales.
  static String? dpi(String? valor) {
    final limpio = soloDigitos(valor ?? '');
    if (limpio.isEmpty) return 'Ingresa el número de DPI';
    if (limpio.length != 13) return 'El DPI debe tener 13 dígitos';
    final departamento = int.parse(limpio.substring(9, 11));
    if (departamento < 1 || departamento > 22) return 'El número de DPI no es válido';
    return null;
  }

  /// Teléfono de Guatemala: 8 dígitos (sin el +502).
  static String? telefono(String? valor) {
    final limpio = soloDigitos(valor ?? '');
    if (limpio.isEmpty) return 'Ingresa un número de teléfono';
    if (limpio.length != 8) return 'El teléfono debe tener 8 dígitos';
    return null;
  }

  static final _formatoEmail = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? email(String? valor) {
    final texto = valor?.trim() ?? '';
    if (texto.isEmpty) return 'Ingresa tu correo electrónico';
    if (!_formatoEmail.hasMatch(texto)) return 'El correo no es válido';
    return null;
  }

  /// NIT opcional: vacío o "CF" significa consumidor final.
  /// Revisa el dígito verificador con el mismo algoritmo que usa Odoo (base_vat).
  static String? nit(String? valor) {
    final texto = normalizarNit(valor ?? '').replaceFirst(RegExp(r'^0+'), '');
    if (texto == 'CF') return null;
    if (texto.length < 2 || !RegExp(r'^\d{1,12}[0-9K]$').hasMatch(texto)) {
      return 'El NIT no es válido (o escribe CF)';
    }
    final cuerpo = texto.substring(0, texto.length - 1);
    var suma = 0;
    for (var i = 0; i < cuerpo.length; i++) {
      // Peso 2 para el último dígito del cuerpo, 3 para el penúltimo, etc.
      suma += (cuerpo.length - i + 1) * int.parse(cuerpo[i]);
    }
    final resto = (-suma) % 11; // en Dart, % siempre devuelve un número positivo
    final esperado = resto == 10 ? 'K' : '$resto';
    if (texto[texto.length - 1] != esperado) {
      return 'El NIT no es válido (revisa el dígito verificador)';
    }
    return null;
  }

  /// Mismas reglas que Odoo (membresia_oro/validaciones.py: error_password).
  static String? password(String? valor) {
    final texto = valor ?? '';
    if (texto.isEmpty) return 'Escribe una contraseña';
    if (texto.length < 8 || texto.length > 128) {
      return 'Debe tener entre 8 y 128 caracteres';
    }
    if (!RegExp(r'[A-Za-z]').hasMatch(texto) || !RegExp(r'\d').hasMatch(texto)) {
      return 'Debe tener al menos una letra y un número';
    }
    return null;
  }

  static String? pesoKg(String? valor) {
    final peso = convertirPeso(valor ?? '');
    if ((valor ?? '').trim().isEmpty) return 'Ingresa el peso aproximado';
    if (peso == null || peso <= 0 || peso > 150) return 'Ingresa un peso válido en kg';
    return null;
  }

  static String soloDigitos(String texto) => texto.replaceAll(RegExp(r'\D'), '');

  /// "1234567-8" → "12345678"; vacío → "CF".
  static String normalizarNit(String texto) {
    final limpio = texto.trim().toUpperCase().replaceAll(RegExp(r'[\s-]'), '');
    return limpio.isEmpty ? 'CF' : limpio;
  }

  /// Acepta "12.5" y "12,5".
  static double? convertirPeso(String texto) =>
      double.tryParse(texto.trim().replaceAll(',', '.'));
}
