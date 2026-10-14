import 'package:flutter/material.dart';

import '../../core/dependencias.dart';
import '../../services/api_odoo.dart';
import '../inicio/pantalla_inicio.dart';

/// Eliminar la cuenta (lo exigen Google Play y la App Store). Pide la contraseña otra vez para
/// que nadie lo haga con un teléfono prestado.
class PantallaEliminarCuenta extends StatefulWidget {
  const PantallaEliminarCuenta({super.key});

  @override
  State<PantallaEliminarCuenta> createState() => _PantallaEliminarCuentaState();
}

class _PantallaEliminarCuentaState extends State<PantallaEliminarCuenta> {
  final _password = TextEditingController();
  bool _eliminando = false;
  bool _ocultar = true;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _eliminar() async {
    if (_password.text.isEmpty) {
      setState(() => _error = 'Escribe tu contraseña');
      return;
    }
    setState(() {
      _eliminando = true;
      _error = null;
    });
    try {
      await Dependencias.de(context).cuenta.eliminarCuenta(_password.text);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const PantallaInicio()),
        (_) => false,
      );
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Tu cuenta fue eliminada.')));
    } on ErrorApi catch (error) {
      if (mounted) setState(() => _error = error.mensaje);
    } finally {
      if (mounted) setState(() => _eliminando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final estilo = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Eliminar cuenta')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Si eliminas tu cuenta:', style: estilo.titleMedium),
          const SizedBox(height: 8),
          const _Punto('Tu membresía se cancela y ya no se harán cobros a tu tarjeta.'),
          const _Punto('Tú y tus beneficiarios pierden la cobertura y el tiempo de espera cumplido.'),
          const _Punto('Se borran las fotos de tu DPI y tu firma.'),
          const _Punto('El contrato, las facturas y los pagos se conservan porque la ley lo exige.'),
          const SizedBox(height: 8),
          Text('Esto no se puede deshacer.', style: estilo.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          TextField(
            controller: _password,
            obscureText: _ocultar,
            autofillHints: const [AutofillHints.password],
            decoration: InputDecoration(
              labelText: 'Escribe tu contraseña para confirmar',
              errorText: _error,
              suffixIcon: IconButton(
                tooltip: _ocultar ? 'Mostrar' : 'Ocultar',
                icon: Icon(_ocultar ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                onPressed: () => setState(() => _ocultar = !_ocultar),
              ),
            ),
            onSubmitted: (_) => _eliminar(),
          ),
          const SizedBox(height: 24),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: _eliminando ? null : _eliminar,
            child: _eliminando
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Eliminar mi cuenta'),
          ),
        ],
      ),
    );
  }
}

class _Punto extends StatelessWidget {
  const _Punto(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('•  '),
          Expanded(child: Text(texto)),
        ]),
      );
}
