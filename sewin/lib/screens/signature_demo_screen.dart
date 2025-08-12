import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../widgets/signature_upload_widget.dart';

class SignatureDemoScreen extends StatefulWidget {
  const SignatureDemoScreen({super.key});

  @override
  State<SignatureDemoScreen> createState() => _SignatureDemoScreenState();
}

class _SignatureDemoScreenState extends State<SignatureDemoScreen> {
  Uint8List? _userSignature;

  void _onSignatureChanged(Uint8List? signature) {
    setState(() {
      _userSignature = signature;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Demo - Firma Digital'),
        backgroundColor: const Color(0xFF1E2A3A),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Widget de Firma Digital',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E2A3A),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Este widget permite al usuario dibujar su firma o subir una imagen de firma. '
              'Automáticamente elimina el fondo blanco dejando solo el trazo transparente.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),

            // Widget de firma
            SignatureUploadWidget(
              onSignatureChanged: _onSignatureChanged,
              title: 'Firma del Usuario',
              width: 400,
              height: 200,
              removeWhiteBackground: true,
            ),

            const SizedBox(height: 24),

            // Mostrar estado actual
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Estado Actual:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _userSignature != null
                          ? 'Firma capturada (${_userSignature!.length} bytes)'
                          : 'Sin firma',
                      style: TextStyle(
                        fontSize: 16,
                        color: _userSignature != null ? Colors.green : Colors.red,
                      ),
                    ),
                    if (_userSignature != null) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Vista previa de la firma:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey.shade100,
                        ),
                        child: Image.memory(
                          _userSignature!,
                          height: 100,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Instrucciones de uso
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Instrucciones de Uso',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '1. Dibuja tu firma directamente en el área gris\n'
                      '2. Presiona "Capturar" para guardar la firma dibujada\n'
                      '3. O presiona "Subir" para seleccionar una imagen de firma\n'
                      '4. Usa "Limpiar" para borrar y empezar de nuevo\n'
                      '5. El fondo blanco se elimina automáticamente',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
