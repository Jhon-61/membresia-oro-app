import '../models/membresia.dart';
import 'api_odoo.dart';
import 'sesion_store.dart';

/// Sesión del miembro y datos de "Mi membresía".
abstract interface class CuentaService {
  /// ¿Hay un token guardado? (No comprueba que siga vigente.)
  Future<bool> haySesion();

  /// Guarda el token que devuelve la afiliación (el miembro ya queda con sesión iniciada).
  Future<void> guardarSesion(String token);

  /// Inicia sesión con correo y contraseña. Lanza [ErrorApi] si son incorrectos.
  Future<Membresia> iniciarSesion(String email, String password);

  Future<void> cerrarSesion();

  /// Pide el correo para crear una contraseña nueva. Devuelve el mensaje para el usuario.
  Future<String> recuperarContrasena(String email);

  /// Datos actuales de la membresía. Si la sesión venció, la borra y lanza [ErrorApi] (401).
  Future<Membresia> obtenerMembresia();

  /// Cambia teléfono, dirección y NIT. Devuelve la membresía actualizada.
  Future<Membresia> actualizarDatos({
    required String telefono,
    required String direccion,
    required String nit,
  });

  /// Agrega un beneficiario ({nombre, dpi, parentesco, fecha_nacimiento}).
  Future<Membresia> agregarBeneficiario(Map<String, dynamic> datos);

  /// Corrige nombre, parentesco o fecha de nacimiento (el DPI no se cambia).
  Future<Membresia> editarBeneficiario(int id, Map<String, dynamic> datos);

  Future<Membresia> quitarBeneficiario(int id);

  /// Enlace temporal (vence en 10 minutos) para abrir el contrato en PDF.
  Future<String> enlaceContrato();

  /// Elimina la cuenta (pide la contraseña otra vez) y borra la sesión del teléfono.
  Future<void> eliminarCuenta(String password);
}

class OdooCuentaService implements CuentaService {
  OdooCuentaService(String baseUrl, this._store, {ApiOdoo? api})
      : _api = api ?? ApiOdoo(baseUrl, token: _store.leerToken);

  final SesionStore _store;
  final ApiOdoo _api;

  static const rutaSesion = '/api/membresia/v1/sesion';
  static const rutaMembresia = '/api/membresia/v1/membresia';
  static const rutaBeneficiarios = '$rutaMembresia/beneficiarios';

  @override
  Future<bool> haySesion() async => (await _store.leerToken())?.isNotEmpty ?? false;

  @override
  Future<void> guardarSesion(String token) => _store.guardarToken(token);

  @override
  Future<Membresia> iniciarSesion(String email, String password) async {
    final json = await _api.post(rutaSesion, {
      'email': email.trim().toLowerCase(),
      'password': password,
    });
    await _store.guardarToken('${json['token']}');
    return Membresia.desdeJson(json['membresia'] as Map<String, dynamic>);
  }

  @override
  Future<void> cerrarSesion() async {
    try {
      await _api.delete(rutaSesion); // invalida el token también en Odoo
    } on ErrorApi {
      // Sin conexión o sesión ya vencida: igual se borra en el teléfono.
    }
    await _store.borrar();
  }

  @override
  Future<String> recuperarContrasena(String email) async {
    final json = await _api.post('$rutaSesion/recuperar', {'email': email.trim().toLowerCase()});
    return '${json['mensaje']}';
  }

  @override
  Future<Membresia> obtenerMembresia() async {
    try {
      final json = await _api.get(rutaMembresia);
      return Membresia.desdeJson(json['membresia'] as Map<String, dynamic>);
    } on ErrorApi catch (error) {
      if (error.sesionVencida) await _store.borrar();
      rethrow;
    }
  }

  /// Envía un cambio y devuelve la membresía actualizada que responde Odoo.
  Future<Membresia> _cambio(Future<Map<String, dynamic>> peticion) async {
    try {
      final json = await peticion;
      return Membresia.desdeJson(json['membresia'] as Map<String, dynamic>);
    } on ErrorApi catch (error) {
      if (error.sesionVencida) await _store.borrar();
      rethrow;
    }
  }

  @override
  Future<Membresia> actualizarDatos({
    required String telefono,
    required String direccion,
    required String nit,
  }) =>
      _cambio(_api.post('$rutaMembresia/datos', {
        'telefono': telefono,
        'direccion': direccion.trim(),
        'nit': nit.trim().isEmpty ? 'CF' : nit.trim(),
      }));

  @override
  Future<Membresia> agregarBeneficiario(Map<String, dynamic> datos) =>
      _cambio(_api.post(rutaBeneficiarios, datos));

  @override
  Future<Membresia> editarBeneficiario(int id, Map<String, dynamic> datos) =>
      _cambio(_api.post('$rutaBeneficiarios/$id', datos));

  @override
  Future<Membresia> quitarBeneficiario(int id) => _cambio(_api.delete('$rutaBeneficiarios/$id'));

  @override
  Future<String> enlaceContrato() async {
    final json = await _api.get('$rutaMembresia/contrato');
    return '${json['url']}';
  }

  @override
  Future<void> eliminarCuenta(String password) async {
    await _api.post('/api/membresia/v1/cuenta/eliminar', {'password': password});
    await _store.borrar();
  }
}

/// Sin Odoo (sin ODOO_URL): datos de ejemplo para probar las pantallas.
class CuentaServiceSimulado implements CuentaService {
  CuentaServiceSimulado(this._store);

  final SesionStore _store;

  @override
  Future<bool> haySesion() async => (await _store.leerToken()) != null;

  @override
  Future<void> guardarSesion(String token) => _store.guardarToken(token);

  @override
  Future<Membresia> iniciarSesion(String email, String password) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    await _store.guardarToken('simulado');
    return membresiaDeEjemplo;
  }

  @override
  Future<void> cerrarSesion() => _store.borrar();

  @override
  Future<String> recuperarContrasena(String email) async =>
      'Si el correo tiene una cuenta, te enviamos las instrucciones.';

  @override
  Future<Membresia> obtenerMembresia() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return membresiaDeEjemplo;
  }

  @override
  Future<Membresia> actualizarDatos({
    required String telefono,
    required String direccion,
    required String nit,
  }) async =>
      membresiaDeEjemplo;

  @override
  Future<Membresia> agregarBeneficiario(Map<String, dynamic> datos) async => membresiaDeEjemplo;

  @override
  Future<Membresia> editarBeneficiario(int id, Map<String, dynamic> datos) async =>
      membresiaDeEjemplo;

  @override
  Future<Membresia> quitarBeneficiario(int id) async => membresiaDeEjemplo;

  @override
  Future<String> enlaceContrato() async =>
      throw const ErrorApi('El contrato solo está disponible conectado a Odoo.');

  @override
  Future<void> eliminarCuenta(String password) => _store.borrar();

  static final membresiaDeEjemplo = Membresia.desdeJson(const {
    'referencia': 'MO-000000',
    'nombre': 'Miembro de prueba',
    'email': 'prueba@correo.com',
    'telefono': '+502 55551234',
    'direccion': 'Zona 1, Guatemala',
    'nit': 'CF',
    'estado': 'pendiente',
    'estado_texto': 'Pendiente de pago',
    'fecha_alta': '2026-10-14',
    'carencia': {
      'humano': {'fecha': '2027-01-12', 'dias_restantes': 90},
      'mascota': {'fecha': '2026-11-13', 'dias_restantes': 30},
    },
    'beneficiarios': [],
    'mascotas': [],
    'cuotas': [],
    'deuda': {'cuotas': 0, 'monto': 0},
  });
}
