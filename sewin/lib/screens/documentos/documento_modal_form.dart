import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sewin/models/documento_model.dart';
import 'package:sewin/screens/documentos/documento.dart';
import 'package:sewin/services/documento_service.dart';
import 'package:sewin/widgets/custom_text_field.dart';

class DocumentoModalForm extends StatefulWidget {
  final Documento? documento;
  final Function()? onSaved;

  const DocumentoModalForm({
    super.key,
    this.documento,
    this.onSaved,
  });

  @override
  State<DocumentoModalForm> createState() => _DocumentoModalFormState();
}

class _DocumentoModalFormState extends State<DocumentoModalForm> {
  final _formKey = GlobalKey<FormState>();
  String? _errorMessage;
  bool _isLoading = false;

  // Controllers
  final TextEditingController _codigoController = TextEditingController();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  final TextEditingController _versionController =
      TextEditingController(text: '1');

  // Form values
  String _selectedEstado = 'borrador';
  int? _selectedGestionId;
  String? _selectedGestionNombre;

  // Estados posibles del documento
  final List<Map<String, String>> _estados = [
    {'value': 'borrador', 'label': 'Borrador'},
    {'value': 'en_revision', 'label': 'En Revisión'},
    {'value': 'aprobado', 'label': 'Aprobado'},
    {'value': 'publicado', 'label': 'Publicado'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.documento != null) {
      _loadDocumentoData();
    }
  }

  void _loadDocumentoData() {
    final doc = widget.documento!;
    _codigoController.text = doc.codigo;
    _nombreController.text = doc.nombre;
    _descripcionController.text = doc.descripcion;
    _versionController.text = doc.version.toString();
    _selectedEstado = doc.estado;
    _selectedGestionId = doc.gestionId;
    _selectedGestionNombre = doc.gestionNombre;
  }

  @override
  void dispose() {
    _codigoController.dispose();
    _nombreController.dispose();
    _descripcionController.dispose();
    _versionController.dispose();
    super.dispose();
  }

  Future<void> _saveDocumento() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final documentoService =
          Provider.of<DocumentoService>(context, listen: false);

      final documento = Documento(
        id: widget.documento!.id,
        codigo: _codigoController.text.trim(),
        nombre: _nombreController.text.trim(),
        descripcion: _descripcionController.text.trim(),
        version: int.tryParse(_versionController.text) ?? 1,
        estado: _selectedEstado,
        gestionId: _selectedGestionId ?? 1, // Default to 1 if not selected
        gestionNombre: _selectedGestionNombre ?? 'Gestión por defecto',
        // Add other required fields with default values
        fechaCreacion: widget.documento?.fechaCreacion ?? DateTime.now(),
        fechaActualizacion: DateTime.now(),
        usuarioCreador: 1, // TODO: Get from auth
        creadorNombre: 'Usuario Actual', // TODO: Get from auth
        isSigned: false, convencion: 'CONV-001',
      );

      if (widget.documento == null) {
        await DocumentoService.createDocumento(documento);
      } else {
        await DocumentoService.updateDocumento(documento);
      }

      if (mounted) {
        Navigator.of(context).pop();
        if (widget.onSaved != null) {
          widget.onSaved!();
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.documento == null
                        ? 'Nuevo Documento'
                        : 'Editar Documento',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red[700]),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Código y Nombre en fila
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: CustomTextField(
                      maxLines: 1,
                      controller: _codigoController,
                      labelText: 'Código',
                      hintText: 'DOC-001',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingrese un código';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 3,
                    child: CustomTextField(
                      maxLines: 1,
                      controller: _nombreController,
                      labelText: 'Nombre',
                      hintText: 'Nombre del documento',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingrese un nombre';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Descripción
              CustomTextField(
                controller: _descripcionController,
                labelText: 'Descripción',
                hintText: 'Descripción del documento',
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese una descripción';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Versión y Estado en fila
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _versionController,
                      labelText: 'Versión',
                      hintText: '1',
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Requerido';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Debe ser un número';
                        }
                        return null;
                      },
                      maxLines: 4,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Estado',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        DropdownButtonFormField<String>(
                          value: _selectedEstado,
                          items: _estados.map((estado) {
                            return DropdownMenuItem(
                              value: estado['value'],
                              child: Text(estado['label']!),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedEstado = value;
                              });
                            }
                          },
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Gestión
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Gestión',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // TODO: Replace with actual gestion dropdown from API
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child:
                        Text(_selectedGestionNombre ?? 'Seleccionar Gestión'),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Botones de acción
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed:
                        _isLoading ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveDocumento,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(widget.documento == null
                            ? 'Guardar'
                            : 'Actualizar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
