/// Utility functions for document-related operations
class DocumentUtils {
  /// Converts a database estado value to a user-friendly display string
  static String formatEstado(String estado) {
    switch (estado) {
      case 'borrador':
        return 'Borrador';
      case 'pendiente_revision':
        return 'Pendiente por Revisión';
      case 'pendiente_aprobacion':
        return 'Pendiente por Aprobación';
      case 'aprobado':
        return 'Aprobado';
      case 'rechazado':
        return 'Rechazado';
      default:
        return estado; // Return as is if no match found
    }
  }
}
