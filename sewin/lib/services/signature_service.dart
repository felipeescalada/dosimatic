import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SignatureService {
  static const String _signaturePathPrefix = 'signature_path_';
  
  // Guardar firma como archivo
  static Future<String?> saveSignatureFile(Uint8List signatureBytes, String userId) async {
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
      print('Error guardando firma: $e');
      return null;
    }
  }
  
  // Asociar ruta de firma a un usuario (usando SharedPreferences)
  static Future<bool> associateSignatureToUser(String userId, String signatureFilePath) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_signaturePathPrefix$userId', signatureFilePath);
      
      // También guardar timestamp de cuando se asoció
      await prefs.setString('${_signaturePathPrefix}${userId}_timestamp', 
          DateTime.now().toIso8601String());
      
      print('Firma asociada al usuario $userId: $signatureFilePath');
      return true;
    } catch (e) {
      print('Error asociando firma al usuario: $e');
      return false;
    }
  }
  
  // Obtener ruta de firma de un usuario
  static Future<String?> getUserSignaturePath(String userId) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      return prefs.getString('$_signaturePathPrefix$userId');
    } catch (e) {
      print('Error obteniendo firma del usuario: $e');
      return null;
    }
  }
  
  // Verificar si un usuario tiene firma
  static Future<bool> userHasSignature(String userId) async {
    final String? signaturePath = await getUserSignaturePath(userId);
    if (signaturePath == null) return false;
    
    // Verificar que el archivo aún existe
    final File file = File(signaturePath);
    return await file.exists();
  }
  
  // Obtener bytes de la firma de un usuario
  static Future<Uint8List?> getUserSignatureBytes(String userId) async {
    try {
      final String? signaturePath = await getUserSignaturePath(userId);
      if (signaturePath == null) return null;
      
      final File file = File(signaturePath);
      if (!await file.exists()) return null;
      
      return await file.readAsBytes();
    } catch (e) {
      print('Error leyendo firma del usuario: $e');
      return null;
    }
  }
  
  // Eliminar firma de un usuario
  static Future<bool> deleteUserSignature(String userId) async {
    try {
      final String? signaturePath = await getUserSignaturePath(userId);
      if (signaturePath == null) return false;
      
      // Eliminar archivo
      final File file = File(signaturePath);
      if (await file.exists()) {
        await file.delete();
      }
      
      // Eliminar referencias en SharedPreferences
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_signaturePathPrefix$userId');
      await prefs.remove('${_signaturePathPrefix}${userId}_timestamp');
      
      print('Firma eliminada para el usuario $userId');
      return true;
    } catch (e) {
      print('Error eliminando firma del usuario: $e');
      return false;
    }
  }
  
  // Obtener lista de todos los usuarios con firma
  static Future<List<String>> getUsersWithSignature() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final Set<String> keys = prefs.getKeys();
      
      final List<String> usersWithSignature = [];
      
      for (String key in keys) {
        if (key.startsWith(_signaturePathPrefix) && !key.endsWith('_timestamp')) {
          final String userId = key.substring(_signaturePathPrefix.length);
          if (await userHasSignature(userId)) {
            usersWithSignature.add(userId);
          }
        }
      }
      
      return usersWithSignature;
    } catch (e) {
      print('Error obteniendo usuarios con firma: $e');
      return [];
    }
  }
  
  // Obtener información completa de firma de un usuario
  static Future<Map<String, dynamic>?> getUserSignatureInfo(String userId) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? signaturePath = prefs.getString('$_signaturePathPrefix$userId');
      final String? timestamp = prefs.getString('${_signaturePathPrefix}${userId}_timestamp');
      
      if (signaturePath == null) return null;
      
      final File file = File(signaturePath);
      final bool exists = await file.exists();
      
      return {
        'userId': userId,
        'signaturePath': signaturePath,
        'timestamp': timestamp,
        'fileExists': exists,
        'fileSize': exists ? await file.length() : 0,
      };
    } catch (e) {
      print('Error obteniendo información de firma: $e');
      return null;
    }
  }
}
