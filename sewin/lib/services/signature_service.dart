import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../global/global_constantes.dart';

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
  
  // Asociar firma a un usuario (sube al servidor y guarda localmente)
  static Future<bool> associateSignatureToUser(String userId, String signatureFilePath) async {
    try {
      final file = File(signatureFilePath);
      if (!await file.exists()) {
        print('Archivo de firma no encontrado: $signatureFilePath');
        return false;
      }

      // Leer los bytes de la firma
      final signatureBytes = await file.readAsBytes();
      
      // Crear la petición multipart
      final url = Uri.parse('${Constants.serverapp}/api/users/$userId/signature');
      final request = http.MultipartRequest('POST', url);
      
      // Añadir el archivo a la petición
      request.files.add(http.MultipartFile.fromBytes(
        'signature',
        signatureBytes,
        filename: 'signature_$userId.png',
        contentType: MediaType('image', 'png'),
      ));

      // Añadir token de autenticación
      final token = await AuthService().getToken();
      if (token == null) {
        print('No se encontró token de autenticación');
        return false;
      }
      request.headers['Authorization'] = 'Bearer $token';

      // Enviar la petición
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        final serverPath = responseData['signature_path'];
        
        if (serverPath != null) {
          // Guardar localmente para acceso rápido
          final SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('$_signaturePathPrefix$userId', signatureFilePath);
          await prefs.setString(
            '${_signaturePathPrefix}${userId}_timestamp', 
            DateTime.now().toIso8601String()
          );
          
          print('Firma subida correctamente al servidor: $serverPath');
          return true;
        }
      }
      
      print('Error al subir la firma al servidor: ${response.statusCode} - ${response.body}');
      return false;
      
    } catch (e) {
      print('Error al asociar firma al usuario: $e');
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
