import 'package:flutter/material.dart';
import 'package:signature/signature.dart';

import '../../../core/constantes.dart';
import '../formulario_afiliacion.dart';

/// Paso 4: aceptar términos y firmar con el dedo.
class PasoFirma extends StatelessWidget {
  const PasoFirma({super.key, required this.formulario, required this.formKey});

  final FormularioAfiliacion formulario;
  final GlobalKey<FormState> formKey;

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    final textos = Theme.of(context).textTheme;

    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Resumen de condiciones', style: textos.titleMedium),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colores.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            // PROVISIONAL: el texto legal definitivo lo entrega el cliente (PREGUNTAS P-09).
            child: const Text(
              '• Cuota de $cuotaMensualTexto al mes por familia.\n'
              '• Cubre al titular, hasta $maxBeneficiarios beneficiarios y 1 cremación de mascota '
              '(hasta $pesoMaxMascotaKg kg).\n'
              '• El servicio humano se activa $carenciaHumanoDias días después de la afiliación; '
              'el de mascota, $carenciaMascotaDias días después.\n'
              '• Con pagos atrasados el beneficio se bloquea.\n\n'
              'Texto provisional: el contrato definitivo se enviará por WhatsApp.',
            ),
          ),
          const SizedBox(height: 8),
          FormField<bool>(
            initialValue: formulario.aceptaTerminos,
            validator: (acepta) => acepta == true ? null : 'Debes aceptar los términos',
            builder: (campo) => CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text('Acepto los términos y condiciones de la Membresía Oro'),
              subtitle: campo.hasError
                  ? Text(campo.errorText!, style: TextStyle(color: colores.error))
                  : null,
              value: campo.value ?? false,
              onChanged: (valor) {
                campo.didChange(valor);
                formulario.aceptaTerminos = valor ?? false;
              },
            ),
          ),
          const SizedBox(height: 16),
          Text('Firma con tu dedo', style: textos.titleMedium),
          const SizedBox(height: 8),
          FormField<void>(
            // La firma vive en el SignatureController; el validador lo revisa directamente.
            validator: (_) => formulario.firma.isEmpty ? 'Firma dentro del recuadro' : null,
            builder: (campo) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: campo.hasError ? colores.error : colores.outline,
                      width: 1.5,
                    ),
                  ),
                  child: Signature(
                    controller: formulario.firma,
                    height: 200,
                    backgroundColor: Colors.white,
                  ),
                ),
                Row(
                  children: [
                    if (campo.hasError)
                      Expanded(
                        child: Text(campo.errorText!,
                            style: textos.bodySmall?.copyWith(color: colores.error)),
                      )
                    else
                      const Spacer(),
                    TextButton.icon(
                      onPressed: () {
                        formulario.firma.clear();
                        campo.didChange(null);
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Borrar firma'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
