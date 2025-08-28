import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:sewin/screens/documentos/documento.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/documento_model.dart';

class DocumentoService {
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static const String baseUrl = 'http://localhost:3500/api';

  // Headers for API requests
  static Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Get all documents with pagination and filters
  static Future<Map<String, dynamic>> getDocumentos({
    int page = 1,
    int limit = 10,
    String? estado,
    int? gestionId,
    String? search,
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        if (estado != null) 'estado': estado,
        if (gestionId != null) 'gestion_id': gestionId.toString(),
        if (search != null && search.isNotEmpty) 'search': search,
      };

      final response = await http.get(
        Uri.parse('$baseUrl/documentos').replace(queryParameters: queryParams),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return {
          'documentos': (data['data'] as List)
              .map((json) => Documento.fromJson(json))
              .toList(),
          'total': data['total'] ?? 0,
          'pages': data['pages'] ?? 1,
        };
      } else {
        throw Exception('Error al cargar documentos: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al cargar documentos: $e');
    }
  }

  // Get document by ID
  static Future<Documento> getDocumentoById(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/documentos/$id'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return Documento.fromJson(data['data']);
      } else if (response.statusCode == 404) {
        throw Exception('Documento no encontrado');
      } else {
        throw Exception('Error al cargar el documento: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al cargar el documento: $e');
    }
  }

  // Create new document
  static Future<Documento> createDocumento(Documento documento) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/documentos'),
        headers: {
          ...await _getHeaders(),
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'codigo': documento.codigo,
          'nombre': documento.nombre,
          'descripcion': documento.descripcion,
          'gestion_id': documento.gestionId,
          'convencion': documento.convencion,
          'usuario_creador': documento.usuarioCreador,
          'estado': documento.estado,
        }),
      );

      if (response.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(response.body);
        return Documento.fromJson(data['data']);
      } else {
        final error = json.decode(response.body)['message'];
        throw Exception(error ?? 'Error al crear el documento');
      }
    } catch (e) {
      throw Exception('Error al crear el documento: $e');
    }
  }

  // Update document
  static Future<Documento> updateDocumento(Documento documento) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/documentos/${documento.id}'),
        headers: {
          ...await _getHeaders(),
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'nombre': documento.nombre,
          'descripcion': documento.descripcion,
          'gestion_id': documento.gestionId,
          'convencion': documento.convencion,
          'estado': documento.estado,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return Documento.fromJson(data['data']);
      } else {
        final error = json.decode(response.body)['message'];
        throw Exception(error ?? 'Error al actualizar el documento');
      }
    } catch (e) {
      throw Exception('Error al actualizar el documento: $e');
    }
  }

  // Delete document
  static Future<bool> deleteDocumento(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/documentos/$id'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        final error = json.decode(response.body)['message'];
        throw Exception(error ?? 'Error al eliminar el documento');
      }
    } catch (e) {
      throw Exception('Error al eliminar el documento: $e');
    }
  }

  // Upload document file (source or PDF)
  static Future<Documento> uploadDocumentoFile({
    required int documentoId,
    required File file,
    required bool isPdf,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/documentos/$documentoId/upload');
      final request = http.MultipartRequest('POST', uri);

      // Add headers
      final token = await _getToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      // Add file
      final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';
      final fileField = isPdf ? 'archivo_pdf' : 'archivo_fuente';
      final fileExtension = file.path.split('.').last.toLowerCase();

      request.files.add(
        await http.MultipartFile.fromPath(
          fileField,
          file.path,
          contentType: MediaType.parse(mimeType),
          filename: 'documento_$documentoId.${isPdf ? 'pdf' : fileExtension}',
        ),
      );

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return Documento.fromJson(data['data']);
      } else {
        final error = json.decode(response.body)['message'];
        throw Exception(error ?? 'Error al subir el archivo');
      }
    } catch (e) {
      throw Exception('Error al subir el archivo: $e');
    }
  }

  // Update document status (review, approve, etc.)
  static Future<Documento> updateDocumentoStatus({
    required int documentoId,
    required String status,
    String? comentarios,
    int? usuarioId,
  }) async {
    try {
      String endpoint;
      Map<String, dynamic> body = {};

      switch (status) {
        case 'enviar_revision':
          endpoint = 'enviar-revision';
          body['usuario_revisor'] = usuarioId;
          break;
        case 'revisar':
          endpoint = 'revisar';
          if (comentarios != null) body['comentarios_revision'] = comentarios;
          break;
        case 'aprobar':
          endpoint = 'aprobar';
          body['usuario_aprobador'] = usuarioId;
          if (comentarios != null) body['comentarios_aprobacion'] = comentarios;
          break;
        case 'rechazar':
          endpoint = 'rechazar';
          if (comentarios != null) body['comentarios_rechazo'] = comentarios;
          break;
        default:
          throw Exception('Estado de documento no válido');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/documentos/$documentoId/$endpoint'),
        headers: {
          ...await _getHeaders(),
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return Documento.fromJson(data['data']);
      } else {
        final error = json.decode(response.body)['message'];
        throw Exception(error ?? 'Error al actualizar el estado del documento');
      }
    } catch (e) {
      throw Exception('Error al actualizar el estado del documento: $e');
    }
  }
}
