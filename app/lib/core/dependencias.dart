import 'package:flutter/widgets.dart';

import '../services/afiliacion_service.dart';
import '../services/api_odoo.dart';
import '../services/cuenta_service.dart';
import '../services/servicio_service.dart';
import '../services/sesion_store.dart';
import 'config.dart';

/// Servicios que usan las pantallas. Se crean una vez en `main()` y cualquier pantalla los
/// obtiene con `Dependencias.de(context)`. En las pruebas se reemplazan por versiones falsas.
class Dependencias extends InheritedWidget {
  const Dependencias({
    super.key,
    required this.afiliacion,
    required this.cuenta,
    required this.servicios,
    required super.child,
  });

  /// Real (Odoo) si hay ODOO_URL; si no, simulados.
  factory Dependencias.desdeConfig({required Widget child}) {
    if (Config.usarOdoo) {
      final store = SesionStoreSegura();
      final api = ApiOdoo(Config.odooUrl, token: store.leerToken);
      return Dependencias(
        afiliacion: AfiliacionService.desdeConfig(),
        cuenta: OdooCuentaService(Config.odooUrl, store, api: api),
        servicios: OdooServicioService(api),
        child: child,
      );
    }
    return Dependencias(
      afiliacion: AfiliacionService.desdeConfig(),
      cuenta: CuentaServiceSimulado(SesionStoreMemoria()),
      servicios: ServicioServiceSimulado(),
      child: child,
    );
  }

  final AfiliacionService afiliacion;
  final CuentaService cuenta;
  final ServicioService servicios;

  static Dependencias de(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<Dependencias>()!;

  @override
  bool updateShouldNotify(Dependencias oldWidget) => false;
}
