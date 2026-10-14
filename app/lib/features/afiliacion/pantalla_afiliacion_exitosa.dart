import 'package:flutter/material.dart';

import '../../core/constantes.dart';
import '../../core/theme/app_theme.dart';
import '../../services/afiliacion_service.dart';
import '../membresia/pantalla_mi_membresia.dart';
import '../pagos/abrir_pago.dart';

class PantallaAfiliacionExitosa extends StatelessWidget {
  const PantallaAfiliacionExitosa({super.key, required this.resultado});

  final AfiliacionExitosa resultado;

  /// Abre el pago en el navegador integrado y deja "Mi membresía" debajo: al cerrar el
  /// navegador, la app se actualiza sola y avisa si el pago se aprobó.
  Future<void> _pagar(BuildContext context) async {
    // El ScaffoldMessenger es de toda la app: sigue existiendo aunque esta pantalla se cierre.
    final mensajero = ScaffoldMessenger.of(context);
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const PantallaMiMembresia(esperandoPago: true)),
      (_) => false,
    );
    final abierto = await abrirPaginaDePago(resultado.urlPago!);
    if (!abierto) {
      mensajero.showSnackBar(
        const SnackBar(content: Text('No se pudo abrir la página de pago.')),
      );
    }
  }

  void _irAMiMembresia(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const PantallaMiMembresia()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final tienePago = resultado.urlPago != null;
    final tieneSesion = resultado.token != null;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.check_circle, size: 80, color: ColoresOro.alDia),
              const SizedBox(height: 16),
              Text('¡Solicitud recibida!', textAlign: TextAlign.center, style: textos.headlineSmall),
              const SizedBox(height: 8),
              Text(
                'Número de afiliación: ${resultado.referencia}',
                textAlign: TextAlign.center,
                style: textos.titleMedium,
              ),
              if (resultado.aviso != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline),
                      const SizedBox(width: 12),
                      Expanded(child: Text(resultado.aviso!)),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Text(
                tienePago
                    ? 'Para activar tu membresía, paga la primera cuota. '
                        'Se abrirá la página de pago segura.'
                    : 'Te contactaremos para completar el pago de tu membresía.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (tienePago)
                FilledButton.icon(
                  onPressed: () => _pagar(context),
                  icon: const Icon(Icons.lock_outline),
                  label: const Text('Pagar $cuotaMensualTexto'),
                ),
              if (tienePago && tieneSesion) const SizedBox(height: 12),
              if (tieneSesion)
                OutlinedButton(
                  onPressed: () => _irAMiMembresia(context),
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                  child: Text(tienePago ? 'Pagar después' : 'Ir a mi membresía'),
                )
              else
                FilledButton(
                  onPressed: () => Navigator.of(context).popUntil((ruta) => ruta.isFirst),
                  child: const Text('Volver al inicio'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
