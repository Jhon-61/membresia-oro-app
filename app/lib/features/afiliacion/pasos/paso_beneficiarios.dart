import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constantes.dart';
import '../../../core/validadores.dart';
import '../../../models/afiliacion.dart';
import '../formulario_afiliacion.dart';
import '../widgets/campo_fecha.dart';

/// Paso 2: de 0 a 4 beneficiarios.
class PasoBeneficiarios extends StatefulWidget {
  const PasoBeneficiarios({super.key, required this.formulario, required this.formKey});

  final FormularioAfiliacion formulario;
  final GlobalKey<FormState> formKey;

  @override
  State<PasoBeneficiarios> createState() => _PasoBeneficiariosState();
}

class _PasoBeneficiariosState extends State<PasoBeneficiarios> {
  List<FormularioBeneficiario> get _beneficiarios => widget.formulario.beneficiarios;

  void _agregar() {
    setState(() => _beneficiarios.add(FormularioBeneficiario()));
  }

  void _quitar(FormularioBeneficiario beneficiario) {
    setState(() => _beneficiarios.remove(beneficiario));
    // Liberar los controladores cuando la tarjeta ya no esté en pantalla.
    WidgetsBinding.instance.addPostFrameCallback((_) => beneficiario.dispose());
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Tu membresía cubre a $maxBeneficiarios personas además de ti. '
            'Puedes agregarlas ahora o después.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          for (final (indice, beneficiario) in _beneficiarios.indexed)
            _TarjetaBeneficiario(
              // ObjectKey: cada tarjeta conserva su estado aunque se borre otra de la lista.
              key: ObjectKey(beneficiario),
              numero: indice + 1,
              beneficiario: beneficiario,
              alQuitar: () => _quitar(beneficiario),
            ),
          if (widget.formulario.puedeAgregarBeneficiario)
            OutlinedButton.icon(
              onPressed: _agregar,
              icon: const Icon(Icons.person_add_alt_1_outlined),
              label: Text('Agregar beneficiario (${_beneficiarios.length} de $maxBeneficiarios)'),
            )
          else
            const Text('Ya registraste el máximo de beneficiarios.', textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _TarjetaBeneficiario extends StatelessWidget {
  const _TarjetaBeneficiario({
    super.key,
    required this.numero,
    required this.beneficiario,
    required this.alQuitar,
  });

  final int numero;
  final FormularioBeneficiario beneficiario;
  final VoidCallback alQuitar;

  @override
  Widget build(BuildContext context) {
    const espacio = SizedBox(height: 12);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Beneficiario $numero',
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                IconButton(
                  tooltip: 'Quitar beneficiario',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: alQuitar,
                ),
              ],
            ),
            TextFormField(
              controller: beneficiario.nombre,
              decoration: const InputDecoration(labelText: 'Nombre completo'),
              textCapitalization: TextCapitalization.words,
              validator: Validadores.requerido,
            ),
            espacio,
            TextFormField(
              controller: beneficiario.dpi,
              decoration: const InputDecoration(
                labelText: 'DPI o CUI (13 dígitos)',
                helperText: 'Para menores, el CUI de la partida de nacimiento',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(13),
              ],
              validator: Validadores.dpi,
            ),
            espacio,
            DropdownButtonFormField<Parentesco>(
              initialValue: beneficiario.parentesco,
              decoration: const InputDecoration(labelText: 'Parentesco'),
              items: [
                for (final p in Parentesco.values)
                  DropdownMenuItem(value: p, child: Text(p.etiqueta)),
              ],
              onChanged: (p) => beneficiario.parentesco = p,
              validator: (p) => p == null ? 'Elige el parentesco' : null,
            ),
            espacio,
            CampoFecha(
              etiqueta: 'Fecha de nacimiento',
              valorInicial: beneficiario.fechaNacimiento,
              alCambiar: (fecha) => beneficiario.fechaNacimiento = fecha,
            ),
          ],
        ),
      ),
    );
  }
}
