import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Dónde se guarda el token de sesión.
abstract interface class SesionStore {
  Future<String?> leerToken();
  Future<void> guardarToken(String token);
  Future<void> borrar();
}

/// Guarda el token cifrado (Keystore en Android, Keychain en iOS).
class SesionStoreSegura implements SesionStore {
  SesionStoreSegura([FlutterSecureStorage? almacen])
      : _almacen = almacen ?? const FlutterSecureStorage();

  static const _clave = 'membresia_oro_token';
  final FlutterSecureStorage _almacen;

  @override
  Future<String?> leerToken() => _almacen.read(key: _clave);

  @override
  Future<void> guardarToken(String token) => _almacen.write(key: _clave, value: token);

  @override
  Future<void> borrar() => _almacen.delete(key: _clave);
}

/// En memoria: para pruebas y para el modo simulado.
class SesionStoreMemoria implements SesionStore {
  String? _token;

  @override
  Future<String?> leerToken() async => _token;

  @override
  Future<void> guardarToken(String token) async => _token = token;

  @override
  Future<void> borrar() async => _token = null;
}
