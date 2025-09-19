import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sewin/models/documento_model.dart';
import 'package:sewin/services/documento_service.dart';
import 'package:sewin/services/global_error_service.dart';
import 'package:sewin/services/auth_service.dart';
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
  List<Documento> _filteredDocumentos = [];
  List<Documento> _pendientesPorAprobar = [];
  List<Documento> _pendientesPorRevisar = [];
  int _pendientesRevisionCount = 0;
  int _pendientesAprobacionCount = 0;
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedView = 'resumen'; // 'resumen', 'aprobar', 'revisar'

  // Search functionality
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchDocuments();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Fetches documents from the backend and updates the UI
  /// Also fetches pending counts for the sidebar
  Future<void> _fetchDocuments() async {
    setState(() {
      _errorMessage = null;
    });

    try {
      // Fetch all documents and pending counts in parallel
      final results = await Future.wait([
        DocumentoService.getDocumentos(limit: 20),
        DocumentoService.getPendientesRevisionCount(),
        DocumentoService.getPendientesAprobacionCount(),
      ]);

      final documentResult = results[0] as Map<String, dynamic>;
      final documentos = documentResult['documentos'] as List<Documento>;

      setState(() {
        _documentos = documentos;
        _filteredDocumentos = _searchQuery.isEmpty
            ? documentos
            : documentos
                .where((doc) =>
                    doc.codigo
                        .toLowerCase()
                        .contains(_searchQuery.toLowerCase()) ||
                    doc.nombre
                        .toLowerCase()
                        .contains(_searchQuery.toLowerCase()))
                .toList();

        _pendientesRevisionCount = results[1] as int;
        _pendientesAprobacionCount = results[2] as int;

        // Update pending lists
        _pendientesPorAprobar =
            documentos.where((doc) => doc.estado == 'en_revision').toList();

        _pendientesPorRevisar =
            documentos.where((doc) => doc.estado == 'borrador').toList();
      });
    } catch (e) {
      GlobalErrorService.showError('Error al cargar documentos: $e');
      setState(() => _errorMessage = 'Error al cargar documentos');
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

  /// Applies search filter and updates the document list
  /// Only triggers search when explicitly called (via button press or Enter key)
  Future<void> _applySearchFilter() async {
    final query = _searchController.text.trim();
    setState(() => _searchQuery = query);

    try {
      setState(() => _isLoading = true);

      if (query.isEmpty) {
        // If search is empty, fetch fresh documents
        await _fetchDocuments();
      } else {
        // Use backend search with the query
        final result = await DocumentoService.getDocumentos(
          limit: 50,
          search: query,
        );

        setState(() {
          _filteredDocumentos = result['documentos'] as List<Documento>;
        });
      }
    } catch (e) {
      GlobalErrorService.showError('Error al buscar documentos: $e');
      // Reset to show all documents on error
      setState(() => _filteredDocumentos = _documentos);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  int _getDocumentCount() {
    switch (_selectedView) {
      case 'aprobar':
        return _pendientesPorAprobar.length;
      case 'revisar':
        return _pendientesPorRevisar.length;
      default:
        return _filteredDocumentos.length;
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
        documentsToShow = _filteredDocumentos;
        title =
            _searchQuery.isNotEmpty ? 'Resultados de búsqueda' : 'Documentos';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with title and document count
        Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '(${_getDocumentCount()})',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.teal),
              onPressed: _fetchDocuments,
              tooltip: 'Actualizar documentos',
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Search bar
        Row(
          children: [
            Expanded(
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: TextField(
                  controller: _searchController,
                  onSubmitted: (_) => _applySearchFilter(),
                  decoration: InputDecoration(
                    hintText: 'Buscar por código o nombre...',
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    border: InputBorder.none,
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear,
                                color: Colors.grey[400], size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                                _filteredDocumentos = _documentos;
                              });
                            },
                          )
                        : null,
                    isDense: true,
                  ),
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: _applySearchFilter,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child: const Text('Consultar'),
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
                  DataColumn(label: Text('Eventos')),
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
  final AuthService _authService = AuthService();

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
        DataCell(
          FutureBuilder<Map<String, dynamic>?>(
            future: _authService.getCurrentUser(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                );
              }

              final user = snapshot.data!;
              final userRole = user['rol'] ?? 'user';
              final userId = user['id'];

              final menuItems = _buildMenuItems(doc, userRole, userId);

              // Only show menu if there are items available
              if (menuItems.isEmpty) {
                return const SizedBox(width: 20, height: 20);
              }

              return PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 20),
                padding: EdgeInsets.zero,
                tooltip: 'Firmar documento',
                onSelected: (value) =>
                    _handleMenuAction(value, doc, userRole, userId),
                itemBuilder: (BuildContext context) => menuItems,
              );
            },
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                onPressed: () => _onEdit(_context, documento: doc),
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(),
                tooltip: 'Editar documento',
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                onPressed: () => _onDelete(doc.id),
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(),
                tooltip: 'Eliminar documento',
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => _documentos.length;

  @override
  int get selectedRowCount => 0;

  // Build menu items based on user role and document state
  List<PopupMenuEntry<String>> _buildMenuItems(
      Documento doc, String userRole, int userId) {
    List<PopupMenuEntry<String>> items = [];

    items.add(
      const PopupMenuItem<String>(
        value: 'firmar',
        child: Row(
          children: [
            Icon(Icons.edit_note, size: 18, color: Colors.green),
            SizedBox(width: 8),
            Text('Firmar'),
          ],
        ),
      ),
    );

    return items;
  }

  // Handle menu action selection
  void _handleMenuAction(
      String action, Documento doc, String userRole, int userId) {
    switch (action) {
      case 'firmar':
        // TODO: Implement firmar functionality
        break;
    }
  }
}
