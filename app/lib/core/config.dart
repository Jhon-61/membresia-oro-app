/// Configuración que se pasa al compilar o ejecutar con --dart-define.
///
/// Ejemplo (apuntando a la rama de desarrollo de Odoo.sh):
///   flutter run --dart-define=ODOO_URL=https://empresa-dev-123456.dev.odoo.com
///
/// Si ODOO_URL está vacío, la app usa el servicio SIMULADO: no envía nada,
/// solo imprime en la consola lo que habría enviado.
abstract final class Config {
  static const odooUrl = String.fromEnvironment('ODOO_URL');

  static bool get usarOdoo => odooUrl.isNotEmpty;
}
