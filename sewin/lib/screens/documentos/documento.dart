import 'package:flutter/material.dart';
import 'package:sewin/models/documento_model.dart';
import 'package:sewin/services/documento_service.dart';
import 'package:sewin/services/global_error_service.dart';
import 'package:sewin/screens/documentos/documento_modal_form.dart';
import 'package:sewin/widgets/app_drawer.dart';

class DocumentosPage extends StatefulWidget {
  const DocumentosPage({super.key});

  @override
  _DocumentosPageState createState() => _DocumentosPageState();
}

class _DocumentosPageState extends State<DocumentosPage> {
  // Lista para almacenar los documentos
  List<Documento> _documentos = [];
  List<Documento> _pendientesPorAprobar = [];
  List<Documento> _pendientesPorRevisar = [];
  int _pendientesRevisionCount = 0;
  int _pendientesAprobacionCount = 0;
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedView = 'resumen'; // 'resumen', 'aprobar', 'revisar'

  @override
  void initState() {
    super.initState();
    _fetchDocuments();
  }

  // Función para obtener los documentos del backend
  Future<void> _fetchDocuments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Fetch all documents and pending counts in parallel
      final results = await Future.wait([
        DocumentoService.getDocumentos(limit: 50),
        DocumentoService.getPendientesRevisionCount(),
        DocumentoService.getPendientesAprobacionCount(),
      ]);

      final documentResult = results[0] as Map<String, dynamic>;
      final documentos = documentResult['documentos'] as List<Documento>;
      final revisionCount = results[1] as int;
      final aprobacionCount = results[2] as int;

      setState(() {
        _documentos = documentos;
        _pendientesRevisionCount = revisionCount;
        _pendientesAprobacionCount = aprobacionCount;
        // Keep local filtering as fallback
        _pendientesPorAprobar =
            documentos.where((doc) => doc.estado == 'en_revision').toList();
        _pendientesPorRevisar =
            documentos.where((doc) => doc.estado == 'borrador').toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error de conexión: $e';
        _isLoading = false;
      });
    }
  }

  // Función para obtener documentos filtrados por vista
  Future<void> _fetchFilteredDocuments(String view) async {
    if (view == 'resumen') {
      _fetchDocuments();
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      List<Documento> filteredDocs;

      if (view == 'aprobar') {
        filteredDocs =
            await DocumentoService.getPendientesAprobacion(limit: 50);
        setState(() {
          _pendientesPorAprobar = filteredDocs;
        });
      } else if (view == 'revisar') {
        filteredDocs = await DocumentoService.getPendientesRevision(limit: 50);
        setState(() {
          _pendientesPorRevisar = filteredDocs;
        });
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error de conexión: $e';
        _isLoading = false;
      });
    }
  }

  // Función para eliminar un documento
  Future<void> _deleteDocumento(int id) async {
    final bool confirm = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirmar Eliminación'),
            content: const Text(
                '¿Estás seguro de que quieres eliminar este documento?'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Eliminar'),
              ),
            ],
          ),
        ) ??
        false;

    if (confirm) {
      try {
        final success = await DocumentoService.deleteDocumento(id);
        if (success) {
          // Si la eliminación fue exitosa, recarga los documentos
          _fetchDocuments();
          GlobalErrorService.showSuccess('Documento eliminado con éxito.');
        } else {
          GlobalErrorService.showError('Error al eliminar el documento.');
        }
      } catch (e) {
        GlobalErrorService.showError('Error de conexión: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Gestión de Documentos'),
      ),
      body: Row(
        children: [
          // Left Navbar
          Container(
            width: 280,
            color: Colors.grey[100],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Agregar Documento Button
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed: () => _showAddEditDialog(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Agregar Documento',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

                // RESUMEN Section
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'RESUMEN',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Pendientes por Aprobar
                      InkWell(
                        onTap: () {
                          setState(() => _selectedView = 'aprobar');
                          _fetchFilteredDocuments('aprobar');
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 12),
                          decoration: BoxDecoration(
                            color: _selectedView == 'aprobar'
                                ? Colors.orange[50]
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                decoration: const BoxDecoration(
                                  color: Colors.orange,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '$_pendientesAprobacionCount',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Pendientes por Aprobar',
                                  style: TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Pendientes por Revisar
                      InkWell(
                        onTap: () {
                          setState(() => _selectedView = 'revisar');
                          _fetchFilteredDocuments('revisar');
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 12),
                          decoration: BoxDecoration(
                            color: _selectedView == 'revisar'
                                ? Colors.red[50]
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '$_pendientesRevisionCount',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Pendientes por Revisar',
                                  style: TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Right Content Area
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: _buildRightContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRightContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!));
    }

    List<Documento> documentsToShow;
    String title;

    switch (_selectedView) {
      case 'aprobar':
        documentsToShow = _pendientesPorAprobar;
        title = 'Pendientes por Aprobar';
        break;
      case 'revisar':
        documentsToShow = _pendientesPorRevisar;
        title = 'Pendientes por Revisar';
        break;
      default:
        documentsToShow = _documentos;
        title = 'Documentos (${_documentos.length})';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _fetchDocuments,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Container(
            width: double.infinity,
            child: SingleChildScrollView(
              child: PaginatedDataTable(
                columns: const <DataColumn>[
                  DataColumn(label: Text('ID')),
                  DataColumn(label: Text('Código')),
                  DataColumn(label: Text('Nombre')),
                  DataColumn(label: Text('Estado')),
                  DataColumn(label: Text('Descripción')),
                  DataColumn(label: Text('Convención')),
                  DataColumn(label: Text('Gestión')),
                  DataColumn(label: Text('Fecha')),
                  DataColumn(label: Text('Acciones')),
                ],
                source: DocumentosDataSource(
                  documentsToShow,
                  context,
                  _fetchDocuments,
                  _showAddEditDialog,
                  _deleteDocumento,
                ),
                rowsPerPage: 10,
                columnSpacing: 20,
                horizontalMargin: 10,
                showCheckboxColumn: false,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Diálogo para agregar o editar un documento usando DocumentoModalForm
  Future<void> _showAddEditDialog(BuildContext context,
      {Documento? documento}) async {
    showDialog(
      context: context,
      builder: (context) => DocumentoModalForm(
        documento: documento,
        onSaved: () {
          _fetchDocuments(); // Refresh the documents list after saving
        },
      ),
    );
  }
}

// Data Source para el PaginatedDataTable
class DocumentosDataSource extends DataTableSource {
  final List<Documento> _documentos;
  final BuildContext _context;
  final Function _refreshCallback;
  final Function _onEdit;
  final Function _onDelete;

  DocumentosDataSource(
    this._documentos,
    this._context,
    this._refreshCallback,
    this._onEdit,
    this._onDelete,
  );

  @override
  DataRow? getRow(int index) {
    if (index >= _documentos.length) {
      return null;
    }
    final doc = _documentos[index];
    return DataRow(
      cells: [
        DataCell(Text(doc.id.toString())),
        DataCell(Text(doc.codigo)),
        DataCell(Text(doc.nombre)),
        DataCell(Text(doc.estado)),
        DataCell(Text(doc.descripcion)),
        DataCell(Text(doc.convencion)),
        DataCell(Text(doc.gestionNombre)),
        DataCell(Text(doc.fechaCreacion.toString().split(' ')[0])),
        DataCell(Row(
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () => _onEdit(_context, documento: doc),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _onDelete(doc.id),
            ),
          ],
        )),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => _documentos.length;

  @override
  int get selectedRowCount => 0;
}
