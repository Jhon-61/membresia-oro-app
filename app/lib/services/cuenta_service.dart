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
}

class OdooCuentaService implements CuentaService {
  OdooCuentaService(String baseUrl, this._store, {ApiOdoo? api})
      : _api = api ?? ApiOdoo(baseUrl, token: _store.leerToken);

  final SesionStore _store;
  final ApiOdoo _api;

  static const rutaSesion = '/api/membresia/v1/sesion';
  static const rutaMembresia = '/api/membresia/v1/membresia';

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
