import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class SignatureUploadWidget extends StatefulWidget {
  final Function(Uint8List?) onSignatureChanged;
  final Function(String?)? onSignatureSaved; // Callback para la ruta del archivo
  final String? userId; // ID del usuario para nombrar el archivo
  final double? width;
  final double? height;
  final String? title;
  final bool removeWhiteBackground;

  const SignatureUploadWidget({
    super.key,
    required this.onSignatureChanged,
    this.onSignatureSaved,
    this.userId,
    this.width = 400,
    this.height = 200,
    this.title = 'Firma Digital',
    this.removeWhiteBackground = true,
  });

  @override
  State<SignatureUploadWidget> createState() => _SignatureUploadWidgetState();
}

class _SignatureUploadWidgetState extends State<SignatureUploadWidget> {
  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 2,
    penColor: Colors.black,
    exportBackgroundColor: Colors.transparent,
  );

  Uint8List? _signatureBytes;

  @override
  void initState() {
    super.initState();
    // Ya no necesitamos el listener complejo ni el timer
    // El botón ahora se habilita basándose en si hay una imagen capturada
  }

  @override
  void dispose() {
    _signatureController.dispose();
    super.dispose();
  }

  // Función para eliminar el fondo blanco de la imagen
  Future<Uint8List?> _removeWhiteBackground(Uint8List imageBytes) async {
    try {
      final image = img.decodeImage(imageBytes);
      if (image == null) return null;

      // Crear una nueva imagen con fondo transparente
      final transparentImage = img.Image(
        width: image.width,
        height: image.height,
        numChannels: 4, // RGBA
      );

      // Llenar con transparente
      img.fill(transparentImage, color: img.ColorRgba8(0, 0, 0, 0));

      // Copiar píxeles no blancos
      for (int y = 0; y < image.height; y++) {
        for (int x = 0; x < image.width; x++) {
          final pixel = image.getPixel(x, y);
          final r = pixel.r.toInt();
          final g = pixel.g.toInt();
          final b = pixel.b.toInt();

          // Si no es blanco (con tolerancia), copiarlo
          if (!(r > 240 && g > 240 && b > 240)) {
            transparentImage.setPixel(x, y, pixel);
          }
        }
      }

      return Uint8List.fromList(img.encodePng(transparentImage));
    } catch (e) {
      print('Error removing background: $e');
      return imageBytes; // Retornar imagen original si hay error
    }
  }

  // Guardar firma como archivo PNG
  Future<String?> saveSignatureToFile(Uint8List signatureBytes, String userId) async {
    try {
      if (kIsWeb) {
        // En Flutter Web, descargar el archivo directamente
        return _downloadSignatureWeb(signatureBytes, userId);
      } else {
        // En móvil/escritorio, guardar en el sistema de archivos
        return _saveSignatureNative(signatureBytes, userId);
      }
    } catch (e) {
      print('Error guardando firma: $e');
      return null;
    }
  }

  // Guardar firma en móvil/escritorio
  Future<String?> _saveSignatureNative(Uint8List signatureBytes, String userId) async {
    try {
      // Obtener el directorio de documentos de la aplicación
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      
      // Crear directorio para firmas si no existe
      final Directory signaturesDir = Directory('${appDocDir.path}/signatures');
      if (!await signaturesDir.exists()) {
        await signaturesDir.create(recursive: true);
      }
      
      // Generar nombre único para el archivo
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String fileName = 'signature_${userId}_$timestamp.png';
      final String filePath = '${signaturesDir.path}/$fileName';
      
      // Guardar el archivo
      final File file = File(filePath);
      await file.writeAsBytes(signatureBytes);
      
      print('Firma guardada en: $filePath');
      return filePath;
      
    } catch (e) {
      print('Error guardando firma nativa: $e');
      return null;
    }
  }

  // Descargar firma en Flutter Web
  String? _downloadSignatureWeb(Uint8List signatureBytes, String userId) {
    try {
      // Generar nombre único para el archivo
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String fileName = 'signature_${userId}_$timestamp.png';
      
      // Crear blob y descargar
      final blob = html.Blob([signatureBytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.document.createElement('a') as html.AnchorElement
        ..href = url
        ..style.display = 'none'
        ..download = fileName;
      html.document.body?.children.add(anchor);
      
      // Trigger download
      anchor.click();
      
      // Cleanup
      html.document.body?.children.remove(anchor);
      html.Url.revokeObjectUrl(url);
      
      print('Firma descargada como: $fileName');
      return 'downloaded:$fileName'; // Retornar indicador de descarga
      
    } catch (e) {
      print('Error descargando firma web: $e');
      return null;
    }
  }

  // Capturar firma del canvas
  Future<void> _captureSignature() async {
    if (_signatureController.isEmpty) return;

    try {
      final signature = await _signatureController.toPngBytes();
      if (signature != null) {
        Uint8List? processedSignature = signature;
        
        if (widget.removeWhiteBackground) {
          processedSignature = await _removeWhiteBackground(signature);
        }

        setState(() {
          _signatureBytes = processedSignature;
        });
        
        // Notificar cambio de firma (bytes)
        widget.onSignatureChanged(processedSignature);
        
        // Guardar archivo si se proporcionó userId y callback
        if (widget.userId != null && widget.onSignatureSaved != null && processedSignature != null) {
          final String? filePath = await saveSignatureToFile(processedSignature, widget.userId!);
          widget.onSignatureSaved!(filePath);
        }
      }
    } catch (e) {
      print('Error capturing signature: $e');
    }
  }

  // Subir imagen desde archivo
  Future<void> _uploadSignature() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.single.bytes != null) {
        Uint8List imageBytes = result.files.single.bytes!;
        
        if (widget.removeWhiteBackground) {
          imageBytes = await _removeWhiteBackground(imageBytes) ?? imageBytes;
        }

        setState(() {
          _signatureBytes = imageBytes;
        });
        
        widget.onSignatureChanged(imageBytes);
      }
    } catch (e) {
      print('Error uploading signature: $e');
    }
  }

  // Limpiar firma
  void _clearSignature() {
    _signatureController.clear();
    setState(() {
      _signatureBytes = null;
    });
    widget.onSignatureChanged(null);
  }

  // Guardar firma manualmente (sin capturar)
  Future<void> _saveSignatureManually() async {
    if (_signatureBytes == null) {
      // Si no hay firma capturada, mostrar mensaje
      print('No hay firma para guardar');
      return;
    }

    try {
      // Usar userId proporcionado o generar uno por defecto
      final String userIdToUse = widget.userId ?? 'usuario_${DateTime.now().millisecondsSinceEpoch}';
      
      // Guardar archivo
      final String? filePath = await saveSignatureToFile(_signatureBytes!, userIdToUse);
      
      // Notificar callback si está disponible
      if (widget.onSignatureSaved != null) {
        widget.onSignatureSaved!(filePath);
      }
      
      if (filePath != null) {
        print('Firma guardada manualmente: $filePath');
        
        // En web, mostrar mensaje de descarga exitosa
        if (kIsWeb && filePath.startsWith('downloaded:')) {
          final fileName = filePath.substring('downloaded:'.length);
          print('✅ Archivo descargado: $fileName');
        }
      }
    } catch (e) {
      print('Error guardando firma manualmente: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título
            if (widget.title != null)
              Text(
                widget.title!,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            const SizedBox(height: 16),

            // Área de firma o imagen capturada
            Container(
              width: widget.width,
              height: widget.height,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300, width: 2),
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey.shade50,
              ),
              child: _signatureBytes != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.memory(
                        _signatureBytes!,
                        fit: BoxFit.contain,
                      ),
                    )
                  : Signature(
                      controller: _signatureController,
                      backgroundColor: Colors.transparent,
                    ),
            ),
            const SizedBox(height: 16),

            // Botones de acción - Primera fila
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Botón para subir imagen
                ElevatedButton.icon(
                  onPressed: _uploadSignature,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Subir'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),

                // Botón para capturar firma dibujada
                ElevatedButton.icon(
                  onPressed: _signatureBytes == null ? _captureSignature : null,
                  icon: const Icon(Icons.check),
                  label: const Text('Capturar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),

                // Botón para limpiar
                ElevatedButton.icon(
                  onPressed: _clearSignature,
                  icon: const Icon(Icons.clear),
                  label: const Text('Limpiar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Botones de acción - Segunda fila
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Botón para guardar firma manualmente
                ElevatedButton.icon(
                  onPressed: _signatureBytes != null ? _saveSignatureManually : null,
                  icon: const Icon(Icons.save),
                  label: const Text('Guardar Firma'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ],
            ),

            // Información adicional
            if (widget.removeWhiteBackground)
              const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Text(
                  'El fondo blanco será removido automáticamente',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
