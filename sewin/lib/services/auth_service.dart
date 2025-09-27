import 'dart:convert' show json, base64Url, utf8;
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sewin/global/global_constantes.dart';
import 'package:sewin/services/logger_service.dart';

class AuthService {
  static String get baseUrl => '${Constants.serverapp}/api';
  static const String tokenKey = 'auth_token';
  static const String userDataKey = 'user_data';

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final token = data['token'];
        final user = data['user']; // Get user data from login response
        
        // Debug print user data received from login
        debugPrint('Login Response - Raw User Data: $user');
        if (token != null && user != null) {
          debugPrint('User ID: ${user['id']}');
          debugPrint('Email: ${user['email']}');
          debugPrint('Nombre: ${user['nombre']}');
          debugPrint('Rol: ${user['rol']}');
          debugPrint('Fecha Creación: ${user['fecha_creacion']}');
          
          // Save token and user data to shared preferences
          await _saveToken(token);
          await _saveUserData(user);
          
          if (kDebugMode) {
            developer.log('✅ Login successful', name: 'AuthService');
            developer.log('🔑 Token saved', name: 'AuthService');
            developer.log('👤 User data saved', name: 'AuthService');
          }
          
          return {
            'success': true,
            'message': 'Login exitoso',
            'token': token,
            'user': user,
          };
        } else {
          Logger.w('No token or user data received from server');
          return {
            'success': false,
            'message': 'Error: Datos de usuario incompletos',
          };
        }
      } else {
        try {
          final error = json.decode(response.body);
          return {
            'success': false,
            'message': error['message'] ?? 'Login failed'
          };
        } catch (e) {
          return {'success': false, 'message': 'Credenciales inválidas'};
        }
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error'};
    }
  }

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Password reset email sent'};
      } else {
        final error = json.decode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Reset failed'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error'};
    }
  }

  Future<Map<String, dynamic>> resetPassword(
      String token, String newPassword) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/reset-password'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'token': token,
          'newPassword': newPassword,
        }),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Password changed successfully'};
      } else {
        final error = json.decode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Change failed'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error'};
    }
  }

  Future<Map<String, dynamic>> changePassword(
      String currentPassword, String newPassword) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'No authentication token found'};
      }

      // Decodificar el token para obtener el ID del usuario
      final tokenParts = token.split('.');
      if (tokenParts.length != 3) {
        return {'success': false, 'message': 'Invalid token format'};
      }

      // Decodificar el payload del token (segunda parte)
      final payload = json.decode(
        utf8.decode(
          base64Url.decode(
            base64Url.normalize(tokenParts[1]),
          ),
        ),
      );

      final userId = payload['id'];
      if (userId == null) {
        return {'success': false, 'message': 'User ID not found in token'};
      }

      final response = await http.post(
        Uri.parse('$baseUrl/users/$userId/change-password'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Password changed successfully'};
      } else {
        final error = json.decode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Change failed'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error'};
    }
  }

  Future<void> logout() async {
    await _removeToken();
    await _removeUserData();
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(tokenKey);
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(tokenKey, token);
  }

  Future<void> _saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(userDataKey, json.encode(userData));
  }

  Future<void> _removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(tokenKey);
  }

  Future<void> _removeUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(userDataKey);
  }

  /// Gets the current user data from storage or token
  /// Returns null if no valid user session exists
  Future<Map<String, dynamic>?> getCurrentUser() async {
    // First try to get token
    final token = await getToken();
    if (token == null) {
      if (kDebugMode) {
        developer.log('🔐 No authentication token found', name: 'AuthService');
      }
      return null;
    }

    // Check if we have cached user data
    final prefs = await SharedPreferences.getInstance();
    final storedUserData = prefs.getString(userDataKey);
    
    if (storedUserData != null) {
      try {
        if (kDebugMode) {
          developer.log('📦 Found cached user data', name: 'AuthService');
        }
        final userData = json.decode(storedUserData) as Map<String, dynamic>;
        if (kDebugMode) {
          developer.log('🔍 Cached User Data: $userData', name: 'AuthService');
        }
        return _formatUserData(userData);
      } catch (e) {
        if (kDebugMode) {
          developer.log('❌ Error parsing cached user data: $e', name: 'AuthService');
        }
      }
    }

    // Fall back to extracting from token
    try {
      final tokenParts = token.split('.');
      if (tokenParts.length != 3) {
        if (kDebugMode) {
          developer.log('❌ Invalid token format', name: 'AuthService');
        }
        return null;
      }

      final payload = json.decode(
        utf8.decode(base64Url.decode(base64Url.normalize(tokenParts[1]))),
      ) as Map<String, dynamic>?;

      if (payload == null) {
        if (kDebugMode) {
          developer.log('❌ Failed to decode token payload', name: 'AuthService');
        }
        return null;
      }

      return _getUserDataFromToken(payload);
    } catch (e) {
      if (kDebugMode) {
        developer.log('❌ Error getting user data from token: $e', name: 'AuthService');
      }
      return null;
    }
  }

  /// Formats user data into a consistent format
  Map<String, dynamic> _formatUserData(Map<String, dynamic> userData) {
    if (kDebugMode) {
      developer.log('🔄 Formatting user data:', name: 'AuthService');
      developer.log('📋 Raw user data: $userData', name: 'AuthService');
    }
    
    try {
      final formattedData = {
        'id': userData['id'],
        'email': userData['email'] ?? '',
        'nombre': userData['nombre'] ?? 'Usuario',
        'rol': userData['rol'] ?? 'user',
        'fecha_creacion': userData['fecha_creacion'] ?? DateTime.now().toIso8601String(),
      };
      
      if (kDebugMode) {
        developer.log('✨ Formatted user data: $formattedData', name: 'AuthService');
      }
      return formattedData;
    } catch (e) {
      if (kDebugMode) {
        developer.log('❌ Error formatting user data: $e', name: 'AuthService');
      }
      rethrow;
    }
  }

  Map<String, dynamic> _getUserDataFromToken(Map<String, dynamic> payload) {
    if (kDebugMode) {
      developer.log('🔍 Extracting user data from token payload', name: 'AuthService');
      developer.log('📋 Token payload: $payload', name: 'AuthService');
    }

    final email = payload['email']?.toString() ?? '';
    
    // El JWT token solo contiene: {id, email, role}
    // NO contiene nombre, así que usamos el email como fallback
    String nombre;
    if (payload.containsKey('nombre') && payload['nombre'] != null) {
      nombre = payload['nombre'].toString();
    } else if (email.isNotEmpty) {
      // Extraer el nombre del email (parte antes de la @) como fallback
      nombre = email.split('@').first;
      // Capitalizar primera letra
      if (nombre.isNotEmpty) {
        nombre = nombre[0].toUpperCase() + (nombre.length > 1 ? nombre.substring(1) : '');
      } else {
        nombre = 'Usuario';
      }
    } else {
      nombre = 'Usuario';
    }

    // Buscar el rol en diferentes campos posibles
    String rol;
    if (payload.containsKey('rol')) {
      rol = payload['rol'];
    } else if (payload.containsKey('role')) {
      rol = payload['role'];
    } else {
      rol = 'user';
    }

    // Using fallback user data from token

    return {
      'id': payload['id'],
      'email': email,
      'nombre': nombre,
      'rol': rol,
      'fecha_creacion': payload['fecha_creacion'] ?? DateTime.now().toIso8601String(),
    };
  }
}
