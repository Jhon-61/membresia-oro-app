// Enums que reflejan los valores guardados en Firestore (CONTEXTO §5).
// En Firestore se guardan como string con el `valor` de cada enum.

/// Estado de un miembro. Ver PREGUNTAS_ABIERTAS P-01 sobre `suspendido`.
enum EstadoMiembro {
  pendiente('pendiente'),
  activo('activo'),
  mora('mora'),
  suspendido('suspendido'),
  cancelado('cancelado');

  const EstadoMiembro(this.valor);
  final String valor;

  static EstadoMiembro desdeValor(String valor) =>
      values.firstWhere((e) => e.valor == valor);
}

enum EstadoPago {
  pagado('pagado'),
  fallido('fallido'),
  pendiente('pendiente');

  const EstadoPago(this.valor);
  final String valor;

  static EstadoPago desdeValor(String valor) =>
      values.firstWhere((e) => e.valor == valor);
}

enum MetodoPago {
  tarjeta('tarjeta'),
  link('link'),
  efectivo('efectivo'),
  deposito('deposito');

  const MetodoPago(this.valor);
  final String valor;

  static MetodoPago desdeValor(String valor) =>
      values.firstWhere((e) => e.valor == valor);
}

enum TipoServicio {
  humano('humano'),
  mascota('mascota');

  const TipoServicio(this.valor);
  final String valor;

  static TipoServicio desdeValor(String valor) =>
      values.firstWhere((e) => e.valor == valor);
}

enum EstadoServicio {
  pendiente('pendiente'),
  aprobado('aprobado'),
  enProceso('en_proceso'),
  rechazado('rechazado'),
  finalizado('finalizado');

  const EstadoServicio(this.valor);
  final String valor;

  static EstadoServicio desdeValor(String valor) =>
      values.firstWhere((e) => e.valor == valor);
}
