import 'package:flutter/material.dart';

import '../../../core/formato.dart';

/// Campo de formulario que abre un calendario para elegir una fecha pasada
/// (p. ej. fecha de nacimiento).
class CampoFecha extends StatelessWidget {
  const CampoFecha({
    super.key,
    required this.etiqueta,
    required this.valorInicial,
    required this.alCambiar,
  });

  final String etiqueta;
  final DateTime? valorInicial;
  final ValueChanged<DateTime> alCambiar;

  @override
  Widget build(BuildContext context) {
    return FormField<DateTime>(
      initialValue: valorInicial,
      validator: (fecha) => fecha == null ? 'Elige la fecha' : null,
      builder: (campo) => InkWell(
        onTap: () async {
          final hoy = DateTime.now();
          final elegida = await showDatePicker(
            context: context,
            initialDate: campo.value ?? DateTime(hoy.year - 30),
            firstDate: DateTime(1900),
            lastDate: hoy,
            initialEntryMode: DatePickerEntryMode.calendarOnly,
          );
          if (elegida == null || !campo.mounted) return;
          campo.didChange(elegida);
          alCambiar(elegida);
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: etiqueta,
            errorText: campo.errorText,
            suffixIcon: const Icon(Icons.calendar_today_outlined),
          ),
          isEmpty: campo.value == null,
          child: Text(campo.value == null ? '' : fechaCorta(campo.value!)),
        ),
      ),
    );
  }
}
