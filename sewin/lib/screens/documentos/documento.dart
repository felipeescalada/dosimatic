import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sewin/models/documento_model.dart';
import 'package:sewin/widgets/app_drawer.dart';

// Define la URL base del backend
const String baseUrl = 'http://localhost:3500/api/documentos?limit=50&offset=0';

class DocumentosPage extends StatefulWidget {
  const DocumentosPage({super.key});

  @override
  _DocumentosPageState createState() => _DocumentosPageState();
}

class _DocumentosPageState extends State<DocumentosPage> {
  // Lista para almacenar los documentos
  List<Documento> _documentos = [];
  bool _isLoading = true;
  String? _errorMessage;

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
      final response = await http.get(Uri.parse(baseUrl));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['success'] == true) {
          final List<dynamic> documentosJson = responseData['data'];
          setState(() {
            _documentos =
                documentosJson.map((doc) => Documento.fromJson(doc)).toList();
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = 'Error al cargar los documentos';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage =
              'Error al cargar los documentos: ${response.statusCode}';
          _isLoading = false;
        });
      }
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
        final response = await http.delete(Uri.parse('$baseUrl/$id'));
        if (response.statusCode == 204) {
          // Si la eliminación fue exitosa, recarga los documentos
          _fetchDocuments();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Documento eliminado con éxito.')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al eliminar el documento.')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error de conexión: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Gestión de Documentos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchDocuments,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // Navegar a una pantalla de creación o mostrar un diálogo
              // para agregar un nuevo documento.
              _showAddEditDialog(context);
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : SingleChildScrollView(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: PaginatedDataTable(
                        header: const Text('Lista de Documentos'),
                        columns: const <DataColumn>[
                          DataColumn(label: Text('ID')),
                          DataColumn(label: Text('Código')),
                          DataColumn(label: Text('Nombre')),
                          DataColumn(label: Text('Descripción')),
                          DataColumn(label: Text('Convención')),
                          DataColumn(label: Text('Gestión ID')),
                          DataColumn(label: Text('Acciones')),
                        ],
                        source: DocumentosDataSource(
                            _documentos,
                            context,
                            _fetchDocuments,
                            _showAddEditDialog,
                            _deleteDocumento),
                        rowsPerPage: 10,
                      ),
                    ),
                  ),
                ),
    );
  }

  // Diálogo para agregar o editar un documento
  Future<void> _showAddEditDialog(BuildContext context,
      {Documento? documento}) async {
    final bool isEditing = documento != null;
    final TextEditingController codigoController =
        TextEditingController(text: isEditing ? documento.codigo : '');
    final TextEditingController nombreController =
        TextEditingController(text: isEditing ? documento.nombre : '');
    final TextEditingController descripcionController =
        TextEditingController(text: isEditing ? documento.descripcion : '');
    final TextEditingController gestionController = TextEditingController(
        text: isEditing ? documento.gestionId.toString() : '');
    final TextEditingController convencionController =
        TextEditingController(text: isEditing ? documento.convencion : '');

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEditing ? 'Editar Documento' : 'Agregar Documento'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: codigoController,
                    decoration: const InputDecoration(labelText: 'Código')),
                TextField(
                    controller: nombreController,
                    decoration: const InputDecoration(labelText: 'Nombre')),
                TextField(
                    controller: descripcionController,
                    decoration:
                        const InputDecoration(labelText: 'Descripción')),
                TextField(
                    controller: gestionController,
                    decoration: const InputDecoration(labelText: 'Gestión ID')),
                TextField(
                    controller: convencionController,
                    decoration: const InputDecoration(labelText: 'Convención')),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newDoc = {
                  'codigo': codigoController.text,
                  'nombre': nombreController.text,
                  'descripcion': descripcionController.text,
                  'gestion_id': int.tryParse(gestionController.text) ?? 0,
                  'convencion': convencionController.text,
                  'vinculado_a': null, // Simplificado para este ejemplo
                  'archivo_fuente': null,
                  'archivo_pdf': null,
                  'usuario_creador': 1, // Usuario de ejemplo
                };

                try {
                  if (isEditing) {
                    final response = await http.put(
                      Uri.parse('$baseUrl/${documento.id}'),
                      headers: {'Content-Type': 'application/json'},
                      body: jsonEncode(newDoc),
                    );
                    if (response.statusCode == 200) {
                      _fetchDocuments();
                    }
                  } else {
                    final response = await http.post(
                      Uri.parse(baseUrl),
                      headers: {'Content-Type': 'application/json'},
                      body: jsonEncode(newDoc),
                    );
                    if (response.statusCode == 201) {
                      _fetchDocuments();
                    }
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error en la operación: $e')),
                  );
                }
                Navigator.of(context).pop();
              },
              child: Text(isEditing ? 'Guardar' : 'Agregar'),
            ),
          ],
        );
      },
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
        DataCell(Text(doc.descripcion)),
        DataCell(Text(doc.convencion)),
        DataCell(Text(doc.gestionId.toString())),
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
