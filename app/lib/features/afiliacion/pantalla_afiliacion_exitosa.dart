import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../services/afiliacion_service.dart';

class PantallaAfiliacionExitosa extends StatelessWidget {
  const PantallaAfiliacionExitosa({super.key, required this.resultado});

  final AfiliacionExitosa resultado;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;

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
              const Text(
                'Te enviaremos tu contrato por WhatsApp. '
                'El pago de la membresía se habilitará en una próxima versión.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
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
