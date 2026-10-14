import 'package:flutter/material.dart';

import '../../core/config.dart';
import '../../core/dependencias.dart';
import '../../services/afiliacion_service.dart';
import 'formulario_afiliacion.dart';
import 'pantalla_afiliacion_exitosa.dart';
import 'pasos/paso_beneficiarios.dart';
import 'pasos/paso_firma.dart';
import 'pasos/paso_mascota.dart';
import 'pasos/paso_titular.dart';

/// Flujo de afiliación en 4 pasos. Al terminar, el miembro queda con la sesión iniciada.
class PantallaAfiliacion extends StatefulWidget {
  const PantallaAfiliacion({super.key, this.servicio});

  /// Se puede inyectar un servicio para las pruebas; si no, se usa el de [Dependencias].
  final AfiliacionService? servicio;

  @override
  State<PantallaAfiliacion> createState() => _PantallaAfiliacionState();
}

class _PantallaAfiliacionState extends State<PantallaAfiliacion> {
  static const _titulos = ['Tus datos', 'Beneficiarios', 'Mascota', 'Términos y firma'];

  final _formulario = FormularioAfiliacion();
  final _formKeys = List.generate(_titulos.length, (_) => GlobalKey<FormState>());
  late final AfiliacionService _servicio =
      widget.servicio ?? Dependencias.de(context).afiliacion;

  int _paso = 0;
  bool _enviando = false;

  bool get _esUltimoPaso => _paso == _titulos.length - 1;

  @override
  void dispose() {
    _formulario.dispose();
    super.dispose();
  }

  void _siguiente() {
    final pasoValido = _formKeys[_paso].currentState?.validate() ?? false;
    if (!pasoValido) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Revisa los campos marcados en rojo')));
      return;
    }
    if (_esUltimoPaso) {
      _enviar();
    } else {
      setState(() => _paso++);
    }
  }

  void _anterior() => setState(() => _paso--);

  Future<void> _enviar() async {
    setState(() => _enviando = true);
    final solicitud = await _formulario.aSolicitud();
    final resultado = await _servicio.enviar(solicitud);
    if (resultado case AfiliacionExitosa(:final token?) when mounted) {
      await Dependencias.de(context).cuenta.guardarSesion(token);
    }
    if (!mounted) return;
    setState(() => _enviando = false);

    switch (resultado) {
      case AfiliacionExitosa():
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => PantallaAfiliacionExitosa(resultado: resultado)),
        );
      case AfiliacionFallida(:final mensaje, :final errores):
        showDialog<void>(
          context: context,
          builder: (contextoDialogo) => AlertDialog(
            title: const Text('No se pudo completar la afiliación'),
            content: Text([mensaje, ...errores.values.map((e) => '• $e')].join('\n')),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(contextoDialogo),
                child: const Text('Entendido'),
              ),
            ],
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pasos = [
      PasoTitular(formulario: _formulario, formKey: _formKeys[0]),
      PasoBeneficiarios(formulario: _formulario, formKey: _formKeys[1]),
      PasoMascota(formulario: _formulario, formKey: _formKeys[2]),
      PasoFirma(formulario: _formulario, formKey: _formKeys[3]),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Afiliación Membresía Oro')),
      body: Column(
        children: [
          if (!Config.usarOdoo) const _AvisoModoPrueba(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Text('Paso ${_paso + 1} de ${_titulos.length}',
                    style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(_titulos[_paso],
                      textAlign: TextAlign.end,
                      style: Theme.of(context).textTheme.titleMedium),
                ),
              ],
            ),
          ),
          LinearProgressIndicator(value: (_paso + 1) / _titulos.length),
          Expanded(
            // IndexedStack mantiene vivos todos los pasos: al regresar, los datos siguen ahí.
            child: IndexedStack(
              index: _paso,
              children: [
                for (final paso in pasos)
                  SingleChildScrollView(padding: const EdgeInsets.all(16), child: paso),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  if (_paso > 0) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _enviando ? null : _anterior,
                        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                        child: const Text('Atrás'),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: FilledButton(
                      onPressed: _enviando ? null : _siguiente,
                      child: _enviando
                          ? const SizedBox.square(
                              dimension: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.5),
                            )
                          : Text(_esUltimoPaso ? 'Enviar afiliación' : 'Siguiente'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvisoModoPrueba extends StatelessWidget {
  const _AvisoModoPrueba();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.tertiaryContainer,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: const Text(
        'Modo prueba: los datos NO se envían a Odoo (falta configurar ODOO_URL).',
        textAlign: TextAlign.center,
      ),
    );
  }
}
