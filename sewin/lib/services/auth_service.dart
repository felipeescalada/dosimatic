import 'dart:convert' show json, base64Url, utf8;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String baseUrl = 'http://localhost:3500/api';
  static const String tokenKey = 'auth_token';

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
        if (token != null) {
          await _saveToken(token);
          return {
            'success': true,
            'message': 'Login successful',
            'token': token
          };
        }
        return {'success': false, 'message': 'No token received'};
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
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(tokenKey);
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(tokenKey, token);
  }

  Future<void> _removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(tokenKey);
  }

  Future<bool> isAuthenticated() async {
    final token = await getToken();
    print('DEBUG AuthService: Token obtenido: ${token != null ? "SÍ" : "NO"}');

    if (token == null) {
      print('DEBUG AuthService: No hay token, retornando false');
      return false;
    }

    // Verificar si el token no ha expirado
    try {
      final tokenParts = token.split('.');
      print('DEBUG AuthService: Token tiene ${tokenParts.length} partes');

      if (tokenParts.length != 3) {
        print('DEBUG AuthService: Token inválido (no tiene 3 partes)');
        return false;
      }

      final payload = json.decode(
        utf8.decode(
          base64Url.decode(
            base64Url.normalize(tokenParts[1]),
          ),
        ),
      );

      print('DEBUG AuthService: Payload decodificado: $payload');

      final exp = payload['exp'];
      print('DEBUG AuthService: Expiración del token: $exp');

      if (exp == null) {
        print('DEBUG AuthService: Token sin fecha de expiración');
        return false;
      }

      final expirationDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      final now = DateTime.now();
      final isValid = now.isBefore(expirationDate);

      print('DEBUG AuthService: Fecha actual: $now');
      print('DEBUG AuthService: Fecha expiración: $expirationDate');
      print('DEBUG AuthService: Token válido: $isValid');

      return isValid;
    } catch (e) {
      print('DEBUG AuthService: Error al validar token: $e');
      return false;
    }
  }
}
