import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';

/// Centralized Authentication and Session Service
class AuthService {
  static const String _keyToken = 'auth_token';
  static const String _keyRole = 'auth_role';
  static const String _keyUserId = 'auth_user_id';
  static const String _keyName = 'auth_user_name';
  static const String _keyEmail = 'auth_user_email';

  // --- Session Persistence Methods ---

  /// Save authenticated session to local device storage
  static Future<void> saveSession({
    required String token,
    required String role,
    required String userId,
    required String fullName,
    required String email,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
    await prefs.setString(_keyRole, role.toUpperCase());
    await prefs.setString(_keyUserId, userId);
    await prefs.setString(_keyName, fullName);
    await prefs.setString(_keyEmail, email);
  }

  /// Get stored access token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  /// Get stored user role ('CUSTOMER' or 'WORKER')
  static Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyRole);
  }

  /// Get stored user display name
  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyName);
  }

  /// Check if user is actively logged in
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Clear session on logout
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyRole);
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyName);
    await prefs.remove(_keyEmail);
  }

  // --- Network API Methods ---

  /// Register a new user (Customer or Worker)
  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    required String role, // 'CUSTOMER' or 'WORKER'
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/auth/register');
    final payload = {
      'email': email.trim(),
      'password': password,
      'full_name': fullName.trim(),
      'phone': phone?.trim(),
      'role': role.toUpperCase(),
    };

    try {
      final response = await http.post(
        url,
        headers: ApiConfig.headers(),
        body: jsonEncode(payload),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        // Save session locally on successful signup
        await saveSession(
          token: data['access_token'] ?? '',
          role: data['role'] ?? role,
          userId: data['user_id'] ?? '',
          fullName: data['full_name'] ?? fullName,
          email: data['email'] ?? email,
        );
        return {'success': true, 'data': data};
      } else {
        final errorMsg = data['detail'] ?? 'Registration failed';
        return {'success': false, 'error': errorMsg};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  /// Log in an existing user
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/auth/login');
    final payload = {
      'email': email.trim(),
      'password': password,
    };

    try {
      final response = await http.post(
        url,
        headers: ApiConfig.headers(),
        body: jsonEncode(payload),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Save session locally on successful login
        await saveSession(
          token: data['access_token'] ?? '',
          role: data['role'] ?? 'CUSTOMER',
          userId: data['user_id'] ?? '',
          fullName: data['full_name'] ?? 'User',
          email: data['email'] ?? email,
        );
        return {'success': true, 'data': data};
      } else {
        final errorMsg = data['detail'] ?? 'Invalid email or password';
        return {'success': false, 'error': errorMsg};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }
}
