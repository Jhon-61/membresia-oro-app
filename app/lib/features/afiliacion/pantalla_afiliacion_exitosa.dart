import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constantes.dart';
import '../../core/theme/app_theme.dart';
import '../../services/afiliacion_service.dart';

class PantallaAfiliacionExitosa extends StatelessWidget {
  const PantallaAfiliacionExitosa({super.key, required this.resultado});

  final AfiliacionExitosa resultado;

  /// Abre la página de pago de Odoo en el navegador del teléfono. Ahí el cliente paga
  /// (la tarjeta nunca pasa por la app) y Odoo activa la membresía al confirmarse el pago.
  Future<void> _abrirPago(BuildContext context) async {
    final abierto = await launchUrl(
      Uri.parse(resultado.urlPago!),
      mode: LaunchMode.externalApplication,
    );
    if (!abierto && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir la página de pago.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final tienePago = resultado.urlPago != null;

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
              if (tienePago) ...[
                FilledButton.icon(
                  onPressed: () => _abrirPago(context),
                  icon: const Icon(Icons.lock_outline),
                  label: const Text('Pagar $cuotaMensualTexto'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).popUntil((ruta) => ruta.isFirst),
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                  child: const Text('Pagar después'),
                ),
              ] else
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
