String _dosDigitos(int n) => n.toString().padLeft(2, '0');

/// Fecha en formato ISO (2026-10-14), como la espera Odoo en los campos Date.
String fechaIso(DateTime fecha) =>
    '${fecha.year}-${_dosDigitos(fecha.month)}-${_dosDigitos(fecha.day)}';

/// Fecha para mostrar en pantalla (14/10/2026).
String fechaCorta(DateTime fecha) =>
    '${_dosDigitos(fecha.day)}/${_dosDigitos(fecha.month)}/${fecha.year}';

/// Monto con el símbolo de su moneda: Q69.99, $69.99 o "69.99 EUR".
String formatoMonto(double monto, String moneda) {
  final simbolo = switch (moneda) {
    'GTQ' => 'Q',
    'USD' => r'$',
    _ => null,
  };
  final texto = monto.toStringAsFixed(2);
  return simbolo != null ? '$simbolo$texto' : '$texto $moneda';
}
