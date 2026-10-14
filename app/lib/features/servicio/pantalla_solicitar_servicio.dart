import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/dependencias.dart';
import '../../core/formato.dart';
import '../../core/theme/app_theme.dart';
import '../../core/validadores.dart';
import '../../models/afiliacion.dart';
import '../../models/membresia.dart';
import '../../services/api_odoo.dart';
import '../../services/servicio_service.dart';
import '../afiliacion/widgets/selector_foto.dart';
import '../pagos/abrir_pago.dart';

/// Formulario del botón rojo "Solicitar Servicio Oro". Devuelve true (Navigator.pop) si se
/// envió, para que "Mi membresía" se actualice.
class PantallaSolicitarServicio extends StatefulWidget {
  const PantallaSolicitarServicio({super.key, required this.membresia});

  final Membresia membresia;

  @override
  State<PantallaSolicitarServicio> createState() => _PantallaSolicitarServicioState();
}

/// Opción de "¿Para quién?": el titular, un beneficiario o una mascota.
class _Persona {
  const _Persona(this.etiqueta, {this.beneficiarioId, this.mascotaId});

  final String etiqueta;
  final int? beneficiarioId;
  final int? mascotaId;

  // Igualdad por contenido: el Dropdown compara la opción elegida con las de la lista, que
  // se vuelven a crear en cada build.
  @override
  bool operator ==(Object otro) =>
      otro is _Persona && otro.beneficiarioId == beneficiarioId && otro.mascotaId == mascotaId;

  @override
  int get hashCode => Object.hash(beneficiarioId, mascotaId);
}

class _PantallaSolicitarServicioState extends State<PantallaSolicitarServicio> {
  final _formKey = GlobalKey<FormState>();
  final _lugar = TextEditingController();
  final _contactoNombre = TextEditingController();
  final _contactoTelefono = TextEditingController();
  final _notas = TextEditingController();
  ArchivoAdjunto? _dpiFoto;

  String _tipo = 'humano';
  _Persona? _persona;
  Candado? _candado;
  bool _evaluando = false;
  bool _enviando = false;

  @override
  void dispose() {
    for (final c in [_lugar, _contactoNombre, _contactoTelefono, _notas]) {
      c.dispose();
    }
    super.dispose();
  }

  List<_Persona> get _personas {
    final m = widget.membresia;
    if (_tipo == 'mascota') {
      return [for (final mascota in m.mascotas) _Persona(mascota.nombre, mascotaId: mascota.id)];
    }
    return [
      _Persona('${m.nombre} (titular)'),
      for (final b in m.beneficiarios) _Persona(b.nombre, beneficiarioId: b.id),
    ];
  }

  void _cambiarTipo(String tipo) {
    setState(() {
      _tipo = tipo;
      _persona = null;
      _candado = null;
    });
  }

  Future<void> _elegirPersona(_Persona? persona) async {
    setState(() {
      _persona = persona;
      _candado = null;
    });
    if (persona == null) return;
    setState(() => _evaluando = true);
    try {
      final candado = await Dependencias.de(context).servicios.evaluar(
          _tipo, beneficiarioId: persona.beneficiarioId, mascotaId: persona.mascotaId);
      if (mounted && _persona == persona) setState(() => _candado = candado);
    } on ErrorApi catch (error) {
      if (mounted) setState(() => _candado = Candado(permitido: false, mensaje: error.mensaje));
    } finally {
      if (mounted) setState(() => _evaluando = false);
    }
  }

  Future<void> _enviar() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _enviando = true);
    final dependencias = Dependencias.de(context);
    try {
      final creado = await dependencias.servicios.solicitar(SolicitudServicio(
        tipo: _tipo,
        beneficiarioId: _persona?.beneficiarioId,
        mascotaId: _persona?.mascotaId,
        lugar: _lugar.text.trim(),
        contactoNombre: _contactoNombre.text.trim(),
        contactoTelefono: Validadores.soloDigitos(_contactoTelefono.text),
        notas: _notas.text.trim(),
        dpiFoto: _tipo == 'humano' ? _dpiFoto : null,
      ));
      if (!mounted) return;
      await _confirmacion(creado);
      if (mounted) Navigator.of(context).pop(true);
    } on ErrorApi catch (error) {
      if (!mounted) return;
      showDialog<void>(
        context: context,
        builder: (contexto) => AlertDialog(
          title: const Text('No se pudo enviar la solicitud'),
          content: Text([error.mensaje, ...error.errores.values.map((e) => '• $e')].join('\n')),
          actions: [
            TextButton(onPressed: () => Navigator.pop(contexto), child: const Text('Entendido')),
          ],
        ),
      );
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  Future<void> _confirmacion(ServicioCreado creado) async {
    final servicio = creado.servicio;
    final pagar = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (contexto) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: ColoresOro.alDia, size: 48),
        title: Text('Solicitud ${servicio.numero} enviada'),
        content: Text(
          'Nuestro equipo te contactará al ${_contactoTelefono.text}. '
          '${servicio.urlPago != null ? '\n\n${creado.mensaje}' : ''}',
        ),
        actions: [
          if (servicio.urlPago != null)
            TextButton(onPressed: () => Navigator.pop(contexto, false), child: const Text('Pagar después')),
          FilledButton(
            onPressed: () => Navigator.pop(contexto, servicio.urlPago != null),
            child: Text(servicio.urlPago != null
                ? 'Pagar ${formatoMonto(servicio.cargo, 'GTQ')}'
                : 'Entendido'),
          ),
        ],
      ),
    );
    if (pagar == true) await abrirPaginaDePago(servicio.urlPago!);
  }

  @override
  Widget build(BuildContext context) {
    const espacio = SizedBox(height: 16);
    final hayMascotas = widget.membresia.mascotas.isNotEmpty;
    final candado = _candado;
    final puedeEnviar = candado?.permitido == true && !_enviando;

    return Scaffold(
      appBar: AppBar(title: const Text('Solicitar Servicio Oro')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Lamentamos tu pérdida. Llena estos datos y te contactaremos de inmediato.',
                  style: Theme.of(context).textTheme.bodyLarge),
              espacio,
              if (hayMascotas)
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'humano', label: Text('Servicio funerario')),
                    ButtonSegment(value: 'mascota', label: Text('Cremación de mascota')),
                  ],
                  selected: {_tipo},
                  onSelectionChanged: (valor) => _cambiarTipo(valor.first),
                ),
              if (hayMascotas) espacio,
              DropdownButtonFormField<_Persona>(
                key: ValueKey(_tipo), // se reinicia al cambiar el tipo
                initialValue: _persona,
                decoration: const InputDecoration(labelText: '¿Para quién es el servicio?'),
                items: [
                  for (final p in _personas) DropdownMenuItem(value: p, child: Text(p.etiqueta)),
                ],
                onChanged: _elegirPersona,
                validator: (p) => p == null ? 'Elige para quién es el servicio' : null,
              ),
              if (_evaluando)
                const Padding(padding: EdgeInsets.only(top: 12), child: LinearProgressIndicator()),
              if (candado != null) ...[espacio, _ResultadoCandado(candado: candado)],
              espacio,
              TextFormField(
                controller: _lugar,
                decoration: const InputDecoration(labelText: 'Lugar del fallecimiento'),
                textCapitalization: TextCapitalization.sentences,
                validator: Validadores.requerido,
              ),
              espacio,
              TextFormField(
                controller: _contactoNombre,
                decoration: const InputDecoration(labelText: 'Persona de contacto'),
                textCapitalization: TextCapitalization.words,
                validator: Validadores.requerido,
              ),
              espacio,
              TextFormField(
                controller: _contactoTelefono,
                decoration: const InputDecoration(labelText: 'Teléfono de contacto', prefixText: '+502 '),
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(8),
                ],
                validator: Validadores.telefono,
              ),
              espacio,
              TextFormField(
                controller: _notas,
                decoration: const InputDecoration(labelText: 'Notas (opcional)'),
                maxLines: 3,
              ),
              if (_tipo == 'humano') ...[
                const SizedBox(height: 24),
                SelectorFoto(
                  etiqueta: 'Foto del DPI de la persona fallecida',
                  valorInicial: _dpiFoto,
                  mensajeObligatorio: 'Agrega la foto del DPI',
                  alCambiar: (archivo) => _dpiFoto = archivo,
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                ),
                onPressed: puedeEnviar ? _enviar : null,
                child: _enviando
                    ? const SizedBox.square(
                        dimension: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                    : const Text('Enviar solicitud'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultadoCandado extends StatelessWidget {
  const _ResultadoCandado({required this.candado});

  final Candado candado;

  @override
  Widget build(BuildContext context) {
    final (color, icono) = !candado.permitido
        ? (ColoresOro.mora, Icons.block)
        : candado.cargo > 0
            ? (ColoresOro.atraso, Icons.info_outline)
            : (ColoresOro.alDia, Icons.check_circle_outline);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, color: color),
          const SizedBox(width: 12),
          Expanded(child: Text(candado.mensaje)),
        ],
      ),
    );
  }
}
