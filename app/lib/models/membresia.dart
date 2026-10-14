// Datos de "Mi membresía" tal como los envía Odoo (GET /api/membresia/v1/membresia).
// Formato en docs/API_ODOO.md.

DateTime? _fecha(Object? valor) =>
    valor is String && valor.isNotEmpty ? DateTime.tryParse(valor) : null;

double _numero(Object? valor) => valor is num ? valor.toDouble() : 0;

/// Cuántos días faltan para poder usar un beneficio (0 = ya disponible).
class Carencia {
  const Carencia({this.fecha, this.diasRestantes});

  factory Carencia.desdeJson(Object? json) {
    final mapa = json is Map ? json : const {};
    return Carencia(
      fecha: _fecha(mapa['fecha']),
      diasRestantes: mapa['dias_restantes'] is int ? mapa['dias_restantes'] as int : null,
    );
  }

  final DateTime? fecha;
  final int? diasRestantes;

  bool get disponible => diasRestantes == 0;
}

class BeneficiarioInfo {
  const BeneficiarioInfo({
    required this.id,
    required this.nombre,
    required this.dpi,
    required this.parentesco,
    required this.fechaNacimiento,
    required this.carencia,
  });

  factory BeneficiarioInfo.desdeJson(Map<String, dynamic> json) => BeneficiarioInfo(
        id: json['id'] as int,
        nombre: '${json['nombre'] ?? ''}',
        dpi: '${json['dpi'] ?? ''}',
        parentesco: '${json['parentesco'] ?? ''}',
        fechaNacimiento: _fecha(json['fecha_nacimiento']),
        carencia: Carencia.desdeJson(json['carencia']),
      );

  final int id;
  final String nombre;
  final String dpi;
  final String parentesco;
  final DateTime? fechaNacimiento;
  final Carencia carencia;
}

class MascotaInfo {
  const MascotaInfo({
    required this.id,
    required this.nombre,
    required this.especie,
    required this.raza,
    required this.pesoKg,
    required this.cargoExtra,
  });

  factory MascotaInfo.desdeJson(Map<String, dynamic> json) => MascotaInfo(
        id: json['id'] as int,
        nombre: '${json['nombre'] ?? ''}',
        especie: '${json['especie'] ?? ''}',
        raza: '${json['raza'] ?? ''}',
        pesoKg: _numero(json['peso_kg']),
        cargoExtra: json['cargo_extra'] == true,
      );

  final int id;
  final String nombre;
  final String especie;
  final String raza;
  final double pesoKg;
  final bool cargoExtra;
}

class Cuota {
  const Cuota({
    required this.id,
    required this.numero,
    required this.periodo,
    required this.fecha,
    required this.monto,
    required this.pendiente,
    required this.moneda,
    required this.pagada,
    required this.urlPago,
  });

  factory Cuota.desdeJson(Map<String, dynamic> json) => Cuota(
        id: json['id'] as int,
        numero: '${json['numero'] ?? ''}',
        periodo: json['periodo']?.toString(),
        fecha: _fecha(json['fecha']),
        monto: _numero(json['monto']),
        pendiente: _numero(json['pendiente']),
        moneda: '${json['moneda'] ?? ''}',
        pagada: json['pagada'] == true,
        urlPago: _urlSegura(json['url_pago']),
      );

  final int id;
  final String numero;
  final String? periodo;
  final DateTime? fecha;
  final double monto;
  final double pendiente;
  final String moneda;
  final bool pagada;

  /// Enlace para pagarla en el portal de Odoo (solo si está pendiente).
  final String? urlPago;
}

/// Solo se aceptan enlaces https (nunca se abre otra cosa en el navegador del cliente).
String? _urlSegura(Object? valor) {
  final uri = Uri.tryParse(valor?.toString() ?? '');
  return uri != null && uri.scheme == 'https' && uri.host.isNotEmpty ? uri.toString() : null;
}

class Membresia {
  const Membresia({
    required this.referencia,
    required this.nombre,
    required this.email,
    required this.telefono,
    required this.direccion,
    required this.nit,
    required this.estado,
    required this.estadoTexto,
    required this.fechaAlta,
    required this.carenciaHumano,
    required this.carenciaMascota,
    required this.beneficiarios,
    required this.mascotas,
    required this.cuotas,
    required this.cuotasPendientes,
    required this.montoPendiente,
  });

  factory Membresia.desdeJson(Map<String, dynamic> json) {
    List<Map<String, dynamic>> lista(String clave) =>
        (json[clave] as List? ?? const []).whereType<Map<String, dynamic>>().toList();
    final carencia = json['carencia'] is Map ? json['carencia'] as Map : const {};
    final deuda = json['deuda'] is Map ? json['deuda'] as Map : const {};
    return Membresia(
      referencia: '${json['referencia'] ?? ''}',
      nombre: '${json['nombre'] ?? ''}',
      email: '${json['email'] ?? ''}',
      telefono: '${json['telefono'] ?? ''}',
      direccion: '${json['direccion'] ?? ''}',
      nit: '${json['nit'] ?? 'CF'}',
      estado: '${json['estado'] ?? ''}',
      estadoTexto: '${json['estado_texto'] ?? json['estado'] ?? ''}',
      fechaAlta: _fecha(json['fecha_alta']),
      carenciaHumano: Carencia.desdeJson(carencia['humano']),
      carenciaMascota: Carencia.desdeJson(carencia['mascota']),
      beneficiarios: lista('beneficiarios').map(BeneficiarioInfo.desdeJson).toList(),
      mascotas: lista('mascotas').map(MascotaInfo.desdeJson).toList(),
      cuotas: lista('cuotas').map(Cuota.desdeJson).toList(),
      cuotasPendientes: deuda['cuotas'] is int ? deuda['cuotas'] as int : 0,
      montoPendiente: _numero(deuda['monto']),
    );
  }

  final String referencia;
  final String nombre;
  final String email;
  final String telefono;
  final String direccion;
  final String nit;

  /// pendiente, activo, mora, suspendido, cancelado
  final String estado;
  final String estadoTexto;
  final DateTime? fechaAlta;
  final Carencia carenciaHumano;
  final Carencia carenciaMascota;
  final List<BeneficiarioInfo> beneficiarios;
  final List<MascotaInfo> mascotas;
  final List<Cuota> cuotas;
  final int cuotasPendientes;
  final double montoPendiente;

  bool get activa => estado == 'activo';

  /// La cuota pendiente más antigua (la que conviene pagar primero).
  Cuota? get cuotaPorPagar {
    final pendientes = cuotas.where((c) => !c.pagada && c.urlPago != null).toList();
    return pendientes.isEmpty ? null : pendientes.last;
  }
}
