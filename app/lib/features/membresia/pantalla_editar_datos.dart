import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/dependencias.dart';
import '../../core/validadores.dart';
import '../../models/membresia.dart';
import '../../services/api_odoo.dart';

/// Cambiar teléfono, dirección y NIT. Al guardar regresa la membresía actualizada.
/// El nombre, el DPI y el correo no se cambian desde la app (son los del contrato).
class PantallaEditarDatos extends StatefulWidget {
  const PantallaEditarDatos({super.key, required this.membresia});

  final Membresia membresia;

  @override
  State<PantallaEditarDatos> createState() => _PantallaEditarDatosState();
}

class _PantallaEditarDatosState extends State<PantallaEditarDatos> {
  final _formKey = GlobalKey<FormState>();
  late final _telefono = TextEditingController(text: _sinCodigoPais(widget.membresia.telefono));
  late final _direccion = TextEditingController(text: widget.membresia.direccion);
  late final _nit = TextEditingController(text: widget.membresia.nit);
  bool _guardando = false;
  Map<String, String> _erroresOdoo = const {};

  /// Odoo guarda "+502 55551234"; en el campo solo van los 8 dígitos.
  static String _sinCodigoPais(String telefono) {
    final digitos = Validadores.soloDigitos(telefono);
    return digitos.length == 11 && digitos.startsWith('502') ? digitos.substring(3) : digitos;
  }

  @override
  void dispose() {
    _telefono.dispose();
    _direccion.dispose();
    _nit.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    setState(() => _erroresOdoo = const {});
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);
    try {
      final actualizada = await Dependencias.de(context).cuenta.actualizarDatos(
        telefono: Validadores.soloDigitos(_telefono.text),
        direccion: _direccion.text,
        nit: _nit.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Tus datos se guardaron.')));
      Navigator.of(context).pop(actualizada);
    } on ErrorApi catch (error) {
      if (!mounted) return;
      // Odoo vuelve a validar: sus mensajes se muestran debajo de cada campo.
      setState(() => _erroresOdoo = error.errores);
      if (error.errores.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.mensaje)));
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const espacio = SizedBox(height: 16);
    final m = widget.membresia;
    return Scaffold(
      appBar: AppBar(title: const Text('Mis datos')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(m.nombre),
              subtitle: Text(m.email),
            ),
            Text(
              'El nombre, el DPI y el correo son los del contrato. Si necesitas cambiarlos, '
              'comunícate con Las Golondrinas.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            espacio,
            TextFormField(
              controller: _telefono,
              decoration: InputDecoration(
                labelText: 'Teléfono',
                prefixText: '+502 ',
                errorText: _erroresOdoo['telefono'],
              ),
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(8),
              ],
              validator: Validadores.telefono,
            ),
            espacio,
            TextFormField(
              controller: _direccion,
              decoration: InputDecoration(labelText: 'Dirección', errorText: _erroresOdoo['direccion']),
              textCapitalization: TextCapitalization.sentences,
              maxLines: 2,
              validator: Validadores.requerido,
            ),
            espacio,
            TextFormField(
              controller: _nit,
              decoration: InputDecoration(
                labelText: 'NIT para la factura',
                helperText: 'Escribe CF si no tienes NIT. Se usa desde la próxima cuota.',
                errorText: _erroresOdoo['nit'],
              ),
              textCapitalization: TextCapitalization.characters,
              validator: Validadores.nit,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _guardando ? null : _guardar,
              child: _guardando
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}
