import 'package:flutter/material.dart';

import '../../../core/constantes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/validadores.dart';
import '../../../models/afiliacion.dart';
import '../formulario_afiliacion.dart';
import '../widgets/selector_foto.dart';

/// Paso 3: mascota (opcional). Si pesa más de 25 kg se avisa, pero NO se bloquea.
class PasoMascota extends StatefulWidget {
  const PasoMascota({super.key, required this.formulario, required this.formKey});

  final FormularioAfiliacion formulario;
  final GlobalKey<FormState> formKey;

  @override
  State<PasoMascota> createState() => _PasoMascotaState();
}

class _PasoMascotaState extends State<PasoMascota> {
  FormularioAfiliacion get _f => widget.formulario;

  @override
  Widget build(BuildContext context) {
    const espacio = SizedBox(height: 16);

    return Form(
      key: widget.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Quiero registrar una mascota'),
            subtitle: const Text('Incluye 1 cremación de mascota'),
            value: _f.tieneMascota,
            onChanged: (valor) => setState(() => _f.tieneMascota = valor),
          ),
          // Si el switch está apagado, estos campos no se construyen y el Form no los valida.
          if (_f.tieneMascota) ...[
            espacio,
            TextFormField(
              controller: _f.mascotaNombre,
              decoration: const InputDecoration(labelText: 'Nombre de la mascota'),
              textCapitalization: TextCapitalization.words,
              validator: Validadores.requerido,
            ),
            espacio,
            DropdownButtonFormField<Especie>(
              initialValue: _f.mascotaEspecie,
              decoration: const InputDecoration(labelText: 'Especie'),
              items: [
                for (final e in Especie.values) DropdownMenuItem(value: e, child: Text(e.etiqueta)),
              ],
              onChanged: (e) => _f.mascotaEspecie = e,
              validator: (e) => e == null ? 'Elige la especie' : null,
            ),
            espacio,
            TextFormField(
              controller: _f.mascotaRaza,
              decoration: const InputDecoration(labelText: 'Raza (o "mestizo")'),
              textCapitalization: TextCapitalization.sentences,
              validator: Validadores.requerido,
            ),
            espacio,
            TextFormField(
              controller: _f.mascotaPeso,
              decoration: const InputDecoration(labelText: 'Peso aproximado', suffixText: 'kg'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: Validadores.pesoKg,
              // Se redibuja para mostrar u ocultar el aviso de más de 25 kg.
              onChanged: (_) => setState(() {}),
            ),
            if (_f.mascotaExcedePeso) ...[
              espacio,
              const _AvisoPeso(),
            ],
            espacio,
            SelectorFoto(
              etiqueta: 'Foto de la mascota',
              valorInicial: _f.mascotaFoto,
              mensajeObligatorio: 'Agrega una foto de tu mascota',
              alCambiar: (archivo) => _f.mascotaFoto = archivo,
            ),
          ],
        ],
      ),
    );
  }
}

class _AvisoPeso extends StatelessWidget {
  const _AvisoPeso();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ColoresOro.atraso.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColoresOro.atraso),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Tu mascota pesa más de $pesoMaxMascotaKg kg. Puedes registrarla, '
              'pero la cremación tendrá un cargo extra de $cargoExtraMascotaTexto.',
            ),
          ),
        ],
      ),
    );
  }
}
