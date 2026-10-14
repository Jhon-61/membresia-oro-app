import 'package:flutter/material.dart';

import '../../core/dependencias.dart';
import '../../core/validadores.dart';
import '../../services/api_odoo.dart';
import '../membresia/pantalla_mi_membresia.dart';

class PantallaLogin extends StatefulWidget {
  const PantallaLogin({super.key});

  @override
  State<PantallaLogin> createState() => _PantallaLoginState();
}

class _PantallaLoginState extends State<PantallaLogin> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _oculta = true;
  bool _cargando = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final membresia =
          await Dependencias.de(context).cuenta.iniciarSesion(_email.text, _password.text);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => PantallaMiMembresia(inicial: membresia)),
        (_) => false,
      );
    } on ErrorApi catch (error) {
      if (mounted) setState(() => _error = error.mensaje);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _recuperar() async {
    final correo = TextEditingController(text: _email.text);
    final enviar = await showDialog<bool>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: const Text('¿Olvidaste tu contraseña?'),
        content: TextField(
          controller: correo,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          decoration: const InputDecoration(
            labelText: 'Correo electrónico',
            helperText: 'Te enviaremos un enlace para crear una nueva.',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(contexto, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(contexto, true), child: const Text('Enviar')),
        ],
      ),
    );
    final email = correo.text;
    correo.dispose();
    if (enviar != true || !mounted || Validadores.email(email) != null) return;

    final mensajero = ScaffoldMessenger.of(context);
    try {
      final mensaje = await Dependencias.de(context).cuenta.recuperarContrasena(email);
      mensajero.showSnackBar(SnackBar(content: Text(mensaje)));
    } on ErrorApi catch (error) {
      mensajero.showSnackBar(SnackBar(content: Text(error.mensaje)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Iniciar sesión')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(child: Image.asset('assets/marca/emblema.png', height: 110)),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Correo electrónico'),
                  validator: Validadores.email,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _password,
                  obscureText: _oculta,
                  autocorrect: false,
                  enableSuggestions: false,
                  onFieldSubmitted: (_) => _entrar(),
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    suffixIcon: IconButton(
                      tooltip: _oculta ? 'Mostrar contraseña' : 'Ocultar contraseña',
                      icon: Icon(_oculta ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _oculta = !_oculta),
                    ),
                  ),
                  validator: (valor) =>
                      (valor ?? '').isEmpty ? 'Escribe tu contraseña' : null,
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(_error!, style: TextStyle(color: colores.error)),
                  ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _cargando ? null : _entrar,
                  child: _cargando
                      ? const SizedBox.square(
                          dimension: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                      : const Text('Entrar'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _cargando ? null : _recuperar,
                  child: const Text('¿Olvidaste tu contraseña?'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
