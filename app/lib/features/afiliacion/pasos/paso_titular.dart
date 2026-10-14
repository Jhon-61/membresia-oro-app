import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/validadores.dart';
import '../formulario_afiliacion.dart';
import '../widgets/selector_foto.dart';

/// Paso 1: datos del titular y fotos de su DPI.
class PasoTitular extends StatelessWidget {
  const PasoTitular({super.key, required this.formulario, required this.formKey});

  final FormularioAfiliacion formulario;
  final GlobalKey<FormState> formKey;

  @override
  Widget build(BuildContext context) {
    const espacio = SizedBox(height: 16);

    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: formulario.nombre,
            decoration: const InputDecoration(labelText: 'Nombre completo'),
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            validator: Validadores.requerido,
          ),
          espacio,
          TextFormField(
            controller: formulario.dpi,
            decoration: const InputDecoration(labelText: 'DPI (13 dígitos)'),
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(13),
            ],
            validator: Validadores.dpi,
          ),
          espacio,
          TextFormField(
            controller: formulario.telefono,
            decoration: const InputDecoration(
              labelText: 'Teléfono (WhatsApp)',
              prefixText: '+502 ',
            ),
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(8),
            ],
            validator: Validadores.telefono,
          ),
          espacio,
          TextFormField(
            controller: formulario.email,
            decoration: const InputDecoration(labelText: 'Correo electrónico'),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autocorrect: false,
            validator: Validadores.email,
          ),
          espacio,
          TextFormField(
            controller: formulario.direccion,
            decoration: const InputDecoration(labelText: 'Dirección'),
            textCapitalization: TextCapitalization.sentences,
            maxLines: 2,
            validator: Validadores.requerido,
          ),
          espacio,
          TextFormField(
            controller: formulario.nit,
            decoration: const InputDecoration(
              labelText: 'NIT para la factura (opcional)',
              helperText: 'Déjalo vacío o escribe CF si no tienes NIT',
            ),
            textCapitalization: TextCapitalization.characters,
            validator: Validadores.nit,
          ),
          const SizedBox(height: 24),
          SelectorFoto(
            etiqueta: 'Foto del DPI · frente',
            ayuda: 'Que se lean bien el nombre y el número',
            valorInicial: formulario.dpiFrente,
            mensajeObligatorio: 'Agrega la foto del frente del DPI',
            alCambiar: (archivo) => formulario.dpiFrente = archivo,
          ),
          espacio,
          SelectorFoto(
            etiqueta: 'Foto del DPI · reverso',
            valorInicial: formulario.dpiReverso,
            mensajeObligatorio: 'Agrega la foto del reverso del DPI',
            alCambiar: (archivo) => formulario.dpiReverso = archivo,
          ),
        ],
      ),
    );
  }
}
