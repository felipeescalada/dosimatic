// Modelo de datos para un Documento
class Documento {
  final int id;
  final String codigo;
  final String nombre;
  final String descripcion;
  final int gestionId;
  final String convencion;
  final int? vinculadoA;
  final String? archivoFuente;
  final String? archivoPdf;
  final int version;
  final String estado;
  final DateTime fechaCreacion;
  final DateTime fechaActualizacion;
  final int usuarioCreador;
  final int? usuarioRevisor;
  final int? usuarioAprobador;
  final DateTime? fechaRevision;
  final DateTime? fechaAprobacion;
  final String? comentariosRevision;
  final String? comentariosAprobacion;
  final bool isSigned;
  final String? signedFilePath;
  final int? signerId;
  final DateTime? signedAt;
  final String? signatureImagePath;
  final String? signerName;
  final int? usuarioFirmante;
  final String gestionNombre;
  final String creadorNombre;
  final String? revisorNombre;
  final String? aprobadorNombre;

  Documento({
    required this.id,
    required this.codigo,
    required this.nombre,
    required this.descripcion,
    required this.gestionId,
    required this.convencion,
    this.vinculadoA,
    this.archivoFuente,
    this.archivoPdf,
    required this.version,
    required this.estado,
    required this.fechaCreacion,
    required this.fechaActualizacion,
    required this.usuarioCreador,
    this.usuarioRevisor,
    this.usuarioAprobador,
    this.fechaRevision,
    this.fechaAprobacion,
    this.comentariosRevision,
    this.comentariosAprobacion,
    required this.isSigned,
    this.signedFilePath,
    this.signerId,
    this.signedAt,
    this.signatureImagePath,
    this.signerName,
    this.usuarioFirmante,
    required this.gestionNombre,
    required this.creadorNombre,
    this.revisorNombre,
    this.aprobadorNombre,
  });

  // Constructor para crear un Documento desde un mapa JSON
  factory Documento.fromJson(Map<String, dynamic> json) {
    return Documento(
      id: json['id'],
      codigo: json['codigo'],
      nombre: json['nombre'],
      descripcion: json['descripcion'],
      gestionId: json['gestion_id'],
      convencion: json['convencion'],
      vinculadoA: json['vinculado_a'],
      archivoFuente: json['archivo_fuente'],
      archivoPdf: json['archivo_pdf'],
      version: json['version'],
      estado: json['estado'],
      fechaCreacion: DateTime.parse(json['fecha_creacion']),
      fechaActualizacion: DateTime.parse(json['fecha_actualizacion']),
      usuarioCreador: json['usuario_creador'],
      usuarioRevisor: json['usuario_revisor'],
      usuarioAprobador: json['usuario_aprobador'],
      fechaRevision: json['fecha_revision'] != null
          ? DateTime.parse(json['fecha_revision'])
          : null,
      fechaAprobacion: json['fecha_aprobacion'] != null
          ? DateTime.parse(json['fecha_aprobacion'])
          : null,
      comentariosRevision: json['comentarios_revision'],
      comentariosAprobacion: json['comentarios_aprobacion'],
      isSigned: json['is_signed'] ?? false,
      signedFilePath: json['signed_file_path'],
      signerId: json['signer_id'],
      signedAt:
          json['signed_at'] != null ? DateTime.parse(json['signed_at']) : null,
      signatureImagePath: json['signature_image_path'],
      signerName: json['signer_name'],
      usuarioFirmante: json['usuario_firmante'],
      gestionNombre: json['gestion_nombre'] ?? '',
      creadorNombre: json['creador_nombre'] ?? '',
      revisorNombre: json['revisor_nombre'],
      aprobadorNombre: json['aprobador_nombre'],
    );
  }

  // Método para convertir el Documento a un mapa JSON para la API
  Map<String, dynamic> toJson() {
    return {
      'codigo': codigo,
      'nombre': nombre,
      'descripcion': descripcion,
      'gestion_id': gestionId,
      'convencion': convencion,
      'vinculado_a': vinculadoA,
      'archivo_fuente': archivoFuente,
      'archivo_pdf': archivoPdf,
    };
  }
}
