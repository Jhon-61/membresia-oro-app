import 'package:flutter/material.dart';

import '../../core/dependencias.dart';
import '../../core/formato.dart';
import '../../core/theme/app_theme.dart';
import '../../models/afiliacion.dart';
import '../../models/membresia.dart';
import '../../services/api_odoo.dart';
import '../inicio/pantalla_inicio.dart';
import '../pagos/abrir_pago.dart';

/// Pantalla principal del miembro con sesión iniciada.
class PantallaMiMembresia extends StatefulWidget {
  const PantallaMiMembresia({super.key, this.inicial, this.esperandoPago = false});

  /// Datos ya cargados (p. ej. al iniciar sesión), para no esperar la primera carga.
  final Membresia? inicial;

  /// true si se acaba de abrir el pago: al volver a la app se revisa si ya se aprobó.
  final bool esperandoPago;

  @override
  State<PantallaMiMembresia> createState() => _PantallaMiMembresiaState();
}

class _PantallaMiMembresiaState extends State<PantallaMiMembresia> with WidgetsBindingObserver {
  Membresia? _membresia;
  String? _error;
  bool _cargando = false;
  late bool _esperandoPago = widget.esperandoPago;

  @override
  void initState() {
    super.initState();
    _membresia = widget.inicial;
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargar());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Al volver a la app (p. ej. después de pagar en el navegador) se actualizan los datos.
  @override
  void didChangeAppLifecycleState(AppLifecycleState estado) {
    if (estado == AppLifecycleState.resumed && _esperandoPago) _cargar();
  }

  Future<void> _cargar() async {
    final antes = _membresia;
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final ahora = await Dependencias.de(context).cuenta.obtenerMembresia();
      if (!mounted) return;
      setState(() => _membresia = ahora);
      if (_esperandoPago) _avisarResultadoDelPago(antes, ahora);
    } on ErrorApi catch (error) {
      if (!mounted) return;
      if (error.sesionVencida) {
        _irAlInicio(error.mensaje);
        return;
      }
      setState(() => _error = error.mensaje);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _avisarResultadoDelPago(Membresia? antes, Membresia ahora) {
    final pago = ahora.cuotasPendientes < (antes?.cuotasPendientes ?? 1) ||
        (ahora.activa && antes?.activa != true);
    if (pago) _esperandoPago = false;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(pago
          ? '¡Pago recibido! ${ahora.activa ? 'Tu membresía está activa.' : ''}'
          : 'Todavía no vemos tu pago. Si ya pagaste, desliza hacia abajo para actualizar.'),
    ));
  }

  Future<void> _pagar(Cuota cuota) async {
    _esperandoPago = true;
    final abierto = await abrirPaginaDePago(cuota.urlPago!);
    if (!abierto && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir la página de pago.')));
    }
  }

  Future<void> _cerrarSesion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: const Text('¿Cerrar sesión?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(contexto, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(contexto, true), child: const Text('Cerrar sesión')),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;
    await Dependencias.de(context).cuenta.cerrarSesion();
    if (mounted) _irAlInicio(null);
  }

  void _irAlInicio(String? mensaje) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const PantallaInicio()),
      (_) => false,
    );
    if (mensaje != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final membresia = _membresia;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi membresía'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (opcion) {
              if (opcion == 'salir') _cerrarSesion();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'salir', child: Text('Cerrar sesión')),
            ],
          ),
        ],
      ),
      body: membresia == null
          ? _SinDatos(cargando: _cargando, error: _error, reintentar: _cargar)
          : RefreshIndicator(
              onRefresh: _cargar,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_error != null) _AvisoError(mensaje: _error!),
                  _TarjetaEstado(membresia: membresia),
                  if (membresia.cuotaPorPagar != null) ...[
                    const SizedBox(height: 12),
                    _TarjetaPago(membresia: membresia, alPagar: _pagar),
                  ],
                  _Seccion(titulo: 'Tus beneficios', children: [
                    _FilaCarencia(texto: 'Servicio funerario', carencia: membresia.carenciaHumano),
                    _FilaCarencia(texto: 'Cremación de mascota', carencia: membresia.carenciaMascota),
                  ]),
                  _Seccion(
                    titulo: 'Beneficiarios (${membresia.beneficiarios.length} de 4)',
                    children: [
                      if (membresia.beneficiarios.isEmpty)
                        const ListTile(title: Text('Aún no registraste beneficiarios.')),
                      for (final b in membresia.beneficiarios)
                        ListTile(
                          leading: const Icon(Icons.person_outline),
                          title: Text(b.nombre),
                          subtitle: Text(_parentesco(b.parentesco)),
                          trailing: _EtiquetaCarencia(carencia: b.carencia),
                        ),
                    ],
                  ),
                  if (membresia.mascotas.isNotEmpty)
                    _Seccion(titulo: 'Mascota', children: [
                      for (final m in membresia.mascotas)
                        ListTile(
                          leading: const Icon(Icons.pets_outlined),
                          title: Text(m.nombre),
                          subtitle: Text('${m.raza} · ${m.pesoKg.toStringAsFixed(1)} kg'
                              '${m.cargoExtra ? ' · cargo extra por peso' : ''}'),
                        ),
                    ]),
                  _Seccion(titulo: 'Cuotas', children: [
                    if (membresia.cuotas.isEmpty) const ListTile(title: Text('Sin cuotas todavía.')),
                    for (final c in membresia.cuotas)
                      ListTile(
                        leading: Icon(c.pagada ? Icons.check_circle : Icons.schedule,
                            color: c.pagada ? ColoresOro.alDia : ColoresOro.atraso),
                        title: Text('${c.periodo ?? c.numero} · ${formatoMonto(c.monto, c.moneda)}'),
                        subtitle: Text(c.pagada ? 'Pagada' : 'Pendiente de pago'),
                      ),
                  ]),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  static String _parentesco(String valor) => Parentesco.values
      .where((p) => p.valor == valor)
      .map((p) => p.etiqueta)
      .firstOrNull ?? valor;
}

class _TarjetaEstado extends StatelessWidget {
  const _TarjetaEstado({required this.membresia});

  final Membresia membresia;

  @override
  Widget build(BuildContext context) {
    final (color, icono) = switch (membresia.estado) {
      'activo' => (ColoresOro.alDia, Icons.verified),
      'mora' => (ColoresOro.mora, Icons.error_outline),
      'cancelado' => (ColoresOro.cancelado, Icons.block),
      'suspendido' => (ColoresOro.atraso, Icons.pause_circle_outline),
      _ => (Colors.blue.shade700, Icons.hourglass_top),
    };
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ColoresOro.azulOscuro,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('MEMBRESÍA ORO',
              style: TextStyle(color: ColoresOro.dorado, fontWeight: FontWeight.bold, letterSpacing: 2)),
          const SizedBox(height: 4),
          Text(membresia.nombre,
              style: const TextStyle(color: ColoresOro.blanco, fontSize: 20, fontWeight: FontWeight.w600)),
          Text('N.º ${membresia.referencia}', style: const TextStyle(color: ColoresOro.blanco)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(icono, color: Colors.white, size: 18),
              const SizedBox(width: 6),
              Text(membresia.estadoTexto, style: const TextStyle(color: Colors.white)),
            ]),
          ),
        ],
      ),
    );
  }
}

class _TarjetaPago extends StatelessWidget {
  const _TarjetaPago({required this.membresia, required this.alPagar});

  final Membresia membresia;
  final ValueChanged<Cuota> alPagar;

  @override
  Widget build(BuildContext context) {
    final cuota = membresia.cuotaPorPagar!;
    final total = formatoMonto(membresia.montoPendiente, cuota.moneda);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              membresia.cuotasPendientes == 1
                  ? 'Tienes 1 cuota pendiente ($total)'
                  : 'Tienes ${membresia.cuotasPendientes} cuotas pendientes ($total)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => alPagar(cuota),
              icon: const Icon(Icons.lock_outline),
              label: Text('Pagar ${formatoMonto(cuota.pendiente, cuota.moneda)}'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Seccion extends StatelessWidget {
  const _Seccion({required this.titulo, required this.children});

  final String titulo;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Card(margin: EdgeInsets.zero, child: Column(children: children)),
        ],
      ),
    );
  }
}

class _FilaCarencia extends StatelessWidget {
  const _FilaCarencia({required this.texto, required this.carencia});

  final String texto;
  final Carencia carencia;

  @override
  Widget build(BuildContext context) => ListTile(
        title: Text(texto),
        subtitle: carencia.fecha != null && !carencia.disponible
            ? Text('Disponible desde el ${fechaCorta(carencia.fecha!)}')
            : null,
        trailing: _EtiquetaCarencia(carencia: carencia),
      );
}

class _EtiquetaCarencia extends StatelessWidget {
  const _EtiquetaCarencia({required this.carencia});

  final Carencia carencia;

  @override
  Widget build(BuildContext context) {
    if (carencia.diasRestantes == null) return const SizedBox.shrink();
    final disponible = carencia.disponible;
    final dias = carencia.diasRestantes!;
    return Text(
      disponible ? 'Disponible' : 'Faltan $dias ${dias == 1 ? 'día' : 'días'}',
      style: TextStyle(
        color: disponible ? ColoresOro.alDia : ColoresOro.atraso,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _AvisoError extends StatelessWidget {
  const _AvisoError({required this.mensaje});

  final String mensaje;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(mensaje, style: TextStyle(color: Theme.of(context).colorScheme.error)),
      );
}

class _SinDatos extends StatelessWidget {
  const _SinDatos({required this.cargando, required this.error, required this.reintentar});

  final bool cargando;
  final String? error;
  final VoidCallback reintentar;

  @override
  Widget build(BuildContext context) {
    if (cargando || error == null) return const Center(child: CircularProgressIndicator());
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(error!, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(onPressed: reintentar, child: const Text('Reintentar')),
        ]),
      ),
    );
  }
}
