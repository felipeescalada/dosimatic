import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../widgets/signature_upload_widget.dart';

class SignatureExampleScreen extends StatefulWidget {
  final String userId; // ID del usuario actual

  const SignatureExampleScreen({
    super.key,
    required this.userId,
  });

  @override
  State<SignatureExampleScreen> createState() => _SignatureExampleScreenState();
}

class _SignatureExampleScreenState extends State<SignatureExampleScreen> {
  Uint8List? _signatureBytes;
  String? _signatureFilePath;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Captura de Firma'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Widget de firma con guardado automático
            SignatureUploadWidget(
              userId: widget.userId, // ID del usuario
              title: 'Firma del Usuario: ${widget.userId}',
              width: 400,
              height: 200,
              removeWhiteBackground: true,
              
              // Callback cuando cambian los bytes de la firma
              onSignatureChanged: (Uint8List? signatureBytes) {
                setState(() {
                  _signatureBytes = signatureBytes;
                });
                print('Firma capturada: ${signatureBytes?.length} bytes');
              },
              
              // Callback cuando se guarda el archivo
              onSignatureSaved: (String? filePath) {
                setState(() {
                  _signatureFilePath = filePath;
                });
                if (filePath != null) {
                  print('Archivo guardado en: $filePath');
                  // Aquí puedes guardar la ruta en tu base de datos
                  _saveSignaturePathToDatabase(widget.userId, filePath);
                  
                  // Mostrar mensaje de éxito
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Firma guardada exitosamente'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
            ),
            
            const SizedBox(height: 20),
            
            // Información del estado actual
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Estado de la Firma',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Usuario: ${widget.userId}'),
                    Text('Bytes capturados: ${_signatureBytes?.length ?? 0}'),
                    Text('Archivo guardado: ${_signatureFilePath ?? "No guardado"}'),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Botón para asociar firma al usuario (ejemplo)
            if (_signatureFilePath != null)
              ElevatedButton.icon(
                onPressed: () => _associateSignatureToUser(),
                icon: const Icon(Icons.person_add),
                label: const Text('Asociar Firma al Usuario'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Simular guardado en base de datos
  Future<void> _saveSignaturePathToDatabase(String userId, String filePath) async {
    try {
      // Aquí implementarías la lógica para guardar en tu base de datos
      // Por ejemplo, usando HTTP para enviar al backend:
      
      /*
      final response = await http.post(
        Uri.parse('https://tu-backend.com/api/users/$userId/signature'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': userId,
          'signatureFilePath': filePath,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );
      */
      
      print('Guardando en BD: Usuario $userId -> Archivo $filePath');
      
    } catch (e) {
      print('Error guardando en base de datos: $e');
    }
  }

  // Asociar firma al usuario
  void _associateSignatureToUser() {
    if (_signatureFilePath != null) {
      // Aquí implementarías la lógica de asociación
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Firma Asociada'),
          content: Text(
            'La firma ha sido asociada exitosamente al usuario ${widget.userId}.\n\n'
            'Archivo: $_signatureFilePath',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }
}
