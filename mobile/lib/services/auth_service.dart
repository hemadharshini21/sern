import 'package:shared_preferences/shared_preferences.dart';

import '../config/api.dart';
import '../models/user.dart';
import 'api_service.dart';

class AuthService {
  static const _tokenKey = 'auth_token';
  static const _userKey = 'auth_user_id';

  static Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    if (token != null) {
      ApiService.setToken(token);
    }
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey) != null;
  }

  /// Silent guest registration so SOS works without explicit login.
  static Future<void> ensureGuest() async {
    if (await isLoggedIn()) {
      // verify token still works
      final u = await me();
      if (u != null) return; // still valid
      // token expired — clear and re-register
      await logout();
    }

    final ts = DateTime.now().millisecondsSinceEpoch;
    final guestEmail = 'guest_$ts@sern.local';
    final guestPass = 'guest$ts';

    try {
      await register(
        name: 'Guest User',
        email: guestEmail,
        password: guestPass,
      );
    } catch (_) {}
  }

  static Future<User> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'email': email,
      'password': password,
    };
    if (phone != null) {
      body['phone'] = phone;
    }
    final res = await ApiService.post(ApiConfig.register, body, auth: false);
    return _persist(res);
  }

  static Future<User> login({
    required String email,
    required String password,
  }) async {
    final res = await ApiService.post(ApiConfig.login, {
      'email': email,
      'password': password,
    }, auth: false);
    return _persist(res);
  }

  static Future<User?> me() async {
    try {
      final res = await ApiService.get(ApiConfig.me);
      return User.fromJson(res['user']);
    } catch (_) {
      return null;
    }
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    ApiService.setToken(null);
  }

  static Future<User> _persist(Map<String, dynamic> res) async {
    final token = res['accessToken'] as String;
    final user = User.fromJson(res['user']);

    ApiService.setToken(token);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userKey, user.id);

    return user;
  }
}
