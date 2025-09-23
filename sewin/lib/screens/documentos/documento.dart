import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sewin/models/documento_model.dart';
import 'package:sewin/services/documento_service.dart';
import 'package:sewin/services/global_error_service.dart';
import 'package:sewin/services/auth_service.dart';
import 'package:sewin/screens/documentos/documento_modal_form.dart';
import 'package:sewin/widgets/app_drawer.dart';
import 'package:sewin/widgets/lookup.dart';
import 'package:sewin/global/global_constantes.dart';

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

  // Column filters
  String? _filterCodigo;
  String? _filterNombre;
  String? _filterEstado;
  String? _filterConvencion;
  String? _filterGestion;

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

        // Apply filters and search
        _filteredDocumentos = _applyFilters(documentos);

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
        setState(() {
          _isLoading = true;
        });

        final success = await DocumentoService.deleteDocumento(id);
        if (success) {
          // Clear all filters and refresh the document list
          await _clearAllFilters();
          GlobalErrorService.showSuccess('Documento eliminado con éxito.');
        } else {
          setState(() {
            _isLoading = false;
          });
          GlobalErrorService.showError('Error al eliminar el documento.');
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        GlobalErrorService.showError('Error de conexión: $e');
      }
    }
  }

  /// Applies filters to the document list
  List<Documento> _applyFilters(List<Documento> documents) {
    List<Documento> filtered = documents;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((doc) =>
              doc.codigo.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              doc.nombre.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    // Apply column filters
    if (_filterCodigo != null) {
      filtered = filtered.where((doc) => doc.codigo == _filterCodigo).toList();
    }
    if (_filterNombre != null) {
      filtered = filtered.where((doc) => doc.nombre == _filterNombre).toList();
    }
    if (_filterEstado != null) {
      filtered = filtered.where((doc) => doc.estado == _filterEstado).toList();
    }
    if (_filterConvencion != null) {
      filtered =
          filtered.where((doc) => doc.convencion == _filterConvencion).toList();
    }
    if (_filterGestion != null) {
      filtered =
          filtered.where((doc) => doc.gestionNombre == _filterGestion).toList();
    }

    return filtered;
  }

  /// Applies search filter and updates the document list
  /// Only triggers search when explicitly called (via button press or Enter key)
  /// Now performs server-side database search for better results
  Future<void> _applySearchFilter() async {
    final query = _searchController.text.trim();
    setState(() {
      _searchQuery = query;
      _isLoading = true;
    });

    try {
      // Prepare search parameters for server-side filtering
      String? searchTerm = query.isNotEmpty ? query : null;
      String? estadoFilter = _filterEstado;
      String? convencionFilter = _filterConvencion;
      int? gestionIdFilter;

      // Convert gestion name to ID if needed
      if (_filterGestion != null) {
        // For now, we'll need to handle gestion name to ID conversion
        // This might require a separate lookup or the backend to accept names
        gestionIdFilter = int.tryParse(_filterGestion!);
      }

      // Handle specific column filters
      if (_filterCodigo != null) {
        searchTerm = _filterCodigo;
      } else if (_filterNombre != null) {
        searchTerm = _filterNombre;
      }

      // Perform server-side search using DocumentoService
      final result = await DocumentoService.getDocumentos(
        limit: 100, // Higher limit for search results
        search: searchTerm,
        estado: estadoFilter,
        gestionId: gestionIdFilter,
        convencion: convencionFilter,
      );

      final documentos = result['documentos'] as List<Documento>;

      setState(() {
        _documentos = documentos;
        _filteredDocumentos = documentos;
        _isLoading = false;
      });
    } catch (e) {
      GlobalErrorService.showError('Error al buscar documentos: $e');
      // On error, try to fetch all documents
      await _fetchDocuments();
    }
  }

  /// Clears all filters and resets the document list
  /// Performs fresh database fetch without any filters
  Future<void> _clearAllFilters() async {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _filterCodigo = null;
      _filterNombre = null;
      _filterEstado = null;
      _filterConvencion = null;
      _filterGestion = null;
      _isLoading = true;
    });

    try {
      // Fetch fresh documents without any filters or search terms
      final result = await DocumentoService.getDocumentos(
        limit: 20, // Back to default limit for initial load
        // No search, estado, or gestionId parameters = fetch all
      );

      final documentos = result['documentos'] as List<Documento>;

      setState(() {
        _documentos = documentos;
        _filteredDocumentos = documentos;
        _isLoading = false;
      });
    } catch (e) {
      GlobalErrorService.showError('Error al limpiar filtros: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Shows lookup dialog for column filtering using the real lookup.dart widget
  /// This makes API calls to search the database for large datasets
  Future<void> _showColumnLookup(
    BuildContext context,
    String columnName,
    Function(String?) onSelected,
    String? currentValue,
  ) async {
    // Generate the appropriate API URL for each column type
    String lookupUrl = _getLookupUrl(columnName);

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          width: 500,
          height: 600,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.teal[600],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.filter_list, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Filtrar por $columnName',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Clear filter option
              if (currentValue != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      onSelected(null);
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.clear_all),
                    label: const Text('Mostrar todo (Limpiar filtro)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[600],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),

              // Real lookup widget with API integration
              Expanded(
                child: lookupPage(
                  urllokup: lookupUrl,
                  etiqueta: columnName,
                  onCountSelected: () {
                    // Handle selection count if needed
                  },
                  onItemSelected: (String id, String code, String name) {
                    // For 'nombre' filter, use the display name instead of ID
                    // For other filters, use the id parameter
                    final selectedValue =
                        columnName.toLowerCase() == 'nombre' ? name : id;
                    onSelected(selectedValue);
                    // DON'T call Navigator.pop() here - the lookup widget handles it
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Generates the appropriate lookup URL for each column type
  String _getLookupUrl(String columnName) {
    final String baseUrl = '${Constants.serverapp}/api';

    switch (columnName.toLowerCase()) {
      case 'código':
        return '$baseUrl/documentos/lookup/codigo';
      case 'nombre':
        return '$baseUrl/documentos/lookup/nombre';
      case 'estado':
        return '$baseUrl/documentos/lookup/estado';
      case 'convención':
        return '$baseUrl/documentos/lookup/convencion';
      case 'gestión':
        return '$baseUrl/documentos/lookup/gestion';
      case 'id':
        return '$baseUrl/documentos/lookup/id';
      default:
        return '$baseUrl/documentos/lookup/general';
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
                                _filteredDocumentos =
                                    _applyFilters(_documentos);
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
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _clearAllFilters,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[600],
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child: const Text('Limpiar'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Container(
            width: double.infinity,
            child: SingleChildScrollView(
              child: PaginatedDataTable(
                columns: [
                  DataColumn(
                    label: GestureDetector(
                      onTap: () => _showColumnLookup(
                        context,
                        'ID',
                        (value) async {
                          setState(() {
                            // Clear other filters when applying a new one
                            _filterCodigo = null;
                            _filterNombre = null;
                            _filterEstado = null;
                            _filterConvencion = null;
                            _filterGestion = null;

                            // Set the ID filter (using codigo field for ID filtering)
                            if (value != null) {
                              _filterCodigo = value;
                            }
                          });

                          // Fetch filtered data from database
                          await _applySearchFilter();
                        },
                        _filterCodigo,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('ID'),
                          if (_filterCodigo != null) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.filter_alt,
                                size: 14, color: Colors.blue),
                          ],
                        ],
                      ),
                    ),
                  ),
                  DataColumn(
                    label: GestureDetector(
                      onTap: () => _showColumnLookup(
                        context,
                        'Código',
                        (value) async {
                          setState(() {
                            // Clear other filters when applying a new one
                            _filterNombre = null;
                            _filterEstado = null;
                            _filterConvencion = null;
                            _filterGestion = null;

                            _filterCodigo = value;
                          });

                          // Fetch filtered data from database
                          await _applySearchFilter();
                        },
                        _filterCodigo,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Código'),
                          if (_filterCodigo != null) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.filter_alt,
                                size: 14, color: Colors.blue),
                          ],
                        ],
                      ),
                    ),
                  ),
                  DataColumn(
                    label: GestureDetector(
                      onTap: () => _showColumnLookup(
                        context,
                        'Nombre',
                        (value) async {
                          setState(() {
                            // Clear other filters when applying a new one
                            _filterCodigo = null;
                            _filterEstado = null;
                            _filterConvencion = null;
                            _filterGestion = null;

                            _filterNombre = value;
                          });

                          // Fetch filtered data from database
                          await _applySearchFilter();
                        },
                        _filterNombre,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Nombre'),
                          if (_filterNombre != null) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.filter_alt,
                                size: 14, color: Colors.blue),
                          ],
                        ],
                      ),
                    ),
                  ),
                  DataColumn(
                    label: GestureDetector(
                      onTap: () => _showColumnLookup(
                        context,
                        'Estado',
                        (value) async {
                          setState(() {
                            // Clear other filters when applying a new one
                            _filterCodigo = null;
                            _filterNombre = null;
                            _filterConvencion = null;
                            _filterGestion = null;

                            _filterEstado = value;
                          });

                          // Fetch filtered data from database
                          await _applySearchFilter();
                        },
                        _filterEstado,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Estado'),
                          if (_filterEstado != null) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.filter_alt,
                                size: 14, color: Colors.blue),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const DataColumn(label: Text('Descripción')),
                  DataColumn(
                    label: GestureDetector(
                      onTap: () => _showColumnLookup(
                        context,
                        'Convención',
                        (value) async {
                          setState(() {
                            // Clear other filters when applying a new one
                            _filterCodigo = null;
                            _filterNombre = null;
                            _filterEstado = null;
                            _filterGestion = null;

                            _filterConvencion = value;
                          });

                          // Fetch filtered data from database
                          await _applySearchFilter();
                        },
                        _filterConvencion,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Convención'),
                          if (_filterConvencion != null) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.filter_alt,
                                size: 14, color: Colors.blue),
                          ],
                        ],
                      ),
                    ),
                  ),
                  DataColumn(
                    label: GestureDetector(
                      onTap: () => _showColumnLookup(
                        context,
                        'Gestión',
                        (value) async {
                          setState(() {
                            // Clear other filters when applying a new one
                            _filterCodigo = null;
                            _filterNombre = null;
                            _filterEstado = null;
                            _filterConvencion = null;

                            _filterGestion = value;
                          });

                          // Fetch filtered data from database
                          await _applySearchFilter();
                        },
                        _filterGestion,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Gestión'),
                          if (_filterGestion != null) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.filter_alt,
                                size: 14, color: Colors.blue),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const DataColumn(label: Text('Fecha')),
                  const DataColumn(label: Text('Eventos')),
                  const DataColumn(label: Text('Acciones')),
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
