import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/dependencias.dart';
import '../../core/formato.dart';
import '../../core/validadores.dart';
import '../../models/afiliacion.dart';
import '../../models/membresia.dart';
import '../../services/api_odoo.dart';
import '../afiliacion/widgets/campo_fecha.dart';

/// Agregar un beneficiario nuevo o corregir uno existente (y quitarlo).
/// Al terminar regresa la membresía actualizada.
class PantallaBeneficiario extends StatefulWidget {
  const PantallaBeneficiario({super.key, this.beneficiario});

  /// null = agregar uno nuevo.
  final BeneficiarioInfo? beneficiario;

  @override
  State<PantallaBeneficiario> createState() => _PantallaBeneficiarioState();
}

class _PantallaBeneficiarioState extends State<PantallaBeneficiario> {
  final _formKey = GlobalKey<FormState>();
  late final _nombre = TextEditingController(text: widget.beneficiario?.nombre);
  late final _dpi = TextEditingController(text: widget.beneficiario?.dpi);
  late Parentesco? _parentesco = Parentesco.values
      .where((p) => p.valor == widget.beneficiario?.parentesco)
      .firstOrNull;
  late DateTime? _fechaNacimiento = widget.beneficiario?.fechaNacimiento;
  bool _guardando = false;
  Map<String, String> _erroresOdoo = const {};

  bool get _esNuevo => widget.beneficiario == null;

  @override
  void dispose() {
    _nombre.dispose();
    _dpi.dispose();
    super.dispose();
  }

  /// Envía el cambio a Odoo; si sale bien, regresa a "Mi membresía" con los datos nuevos.
  Future<void> _enviar(Future<Membresia> Function() cambio, String mensajeOk) async {
    setState(() {
      _guardando = true;
      _erroresOdoo = const {};
    });
    try {
      final actualizada = await cambio();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensajeOk)));
      Navigator.of(context).pop(actualizada);
    } on ErrorApi catch (error) {
      if (!mounted) return;
      // Los errores vienen como "beneficiario.dpi": se muestran debajo del campo.
      setState(() => _erroresOdoo = {
            for (final e in error.errores.entries) e.key.split('.').last: e.value,
          });
      if (error.errores.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.mensaje)));
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;
    final datos = {
      'nombre': _nombre.text.trim(),
      'dpi': Validadores.soloDigitos(_dpi.text),
      'parentesco': _parentesco!.valor,
      'fecha_nacimiento': fechaIso(_fechaNacimiento!),
    };
    final cuenta = Dependencias.de(context).cuenta;
    _enviar(
      () => _esNuevo
          ? cuenta.agregarBeneficiario(datos)
          : cuenta.editarBeneficiario(widget.beneficiario!.id, datos),
      _esNuevo ? 'Beneficiario agregado.' : 'Cambios guardados.',
    );
  }

  Future<void> _quitar() async {
    final b = widget.beneficiario!;
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: Text('¿Quitar a ${b.nombre}?'),
        content: const Text(
            'Dejará de estar cubierto por tu membresía. Si lo vuelves a agregar después, '
            'tendrá que esperar otra vez 90 días.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(contexto, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(contexto, true), child: const Text('Quitar')),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;
    final cuenta = Dependencias.de(context).cuenta;
    _enviar(() => cuenta.quitarBeneficiario(b.id), 'Beneficiario retirado.');
  }

  @override
  Widget build(BuildContext context) {
    const espacio = SizedBox(height: 16);
    return Scaffold(
      appBar: AppBar(
        title: Text(_esNuevo ? 'Agregar beneficiario' : 'Beneficiario'),
        actions: [
          if (!_esNuevo)
            IconButton(
              tooltip: 'Quitar beneficiario',
              icon: const Icon(Icons.delete_outline),
              onPressed: _guardando ? null : _quitar,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_esNuevo)
              Card(
                color: Theme.of(context).colorScheme.secondaryContainer,
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('Los beneficiarios nuevos pueden usar el servicio funerario '
                      '90 días después de agregarlos.'),
                ),
              ),
            espacio,
            TextFormField(
              controller: _nombre,
              decoration: InputDecoration(labelText: 'Nombre completo', errorText: _erroresOdoo['nombre']),
              textCapitalization: TextCapitalization.words,
              validator: Validadores.requerido,
            ),
            espacio,
            TextFormField(
              controller: _dpi,
              // El DPI no se cambia: otra persona es otro beneficiario (con su propia espera).
              enabled: _esNuevo,
              decoration: InputDecoration(
                labelText: 'DPI o CUI (13 dígitos)',
                helperText: _esNuevo
                    ? 'Para menores, el CUI de la partida de nacimiento'
                    : 'El DPI no se puede cambiar',
                errorText: _erroresOdoo['dpi'],
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(13),
              ],
              validator: _esNuevo ? Validadores.dpi : null,
            ),
            espacio,
            DropdownButtonFormField<Parentesco>(
              initialValue: _parentesco,
              decoration: InputDecoration(labelText: 'Parentesco', errorText: _erroresOdoo['parentesco']),
              items: [
                for (final p in Parentesco.values) DropdownMenuItem(value: p, child: Text(p.etiqueta)),
              ],
              onChanged: (p) => _parentesco = p,
              validator: (p) => p == null ? 'Elige el parentesco' : null,
            ),
            espacio,
            CampoFecha(
              etiqueta: 'Fecha de nacimiento',
              valorInicial: _fechaNacimiento,
              alCambiar: (fecha) => _fechaNacimiento = fecha,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _guardando ? null : _guardar,
              child: _guardando
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(_esNuevo ? 'Agregar' : 'Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}
