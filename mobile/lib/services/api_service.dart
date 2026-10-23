import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiService {
  static String? _token;

  static void setToken(String? token) => _token = token;
  static String? get token => _token;

  static Map<String, String> _headers({bool auth = true}) {
    final headers = {'Content-Type': 'application/json'};
    if (auth && _token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  // ---- Generic HTTP with 15-Second Timeout Guard ----

  static Future<Map<String, dynamic>> get(String url) async {
    try {
      final res = await http
          .get(Uri.parse(url), headers: _headers())
          .timeout(const Duration(seconds: 15));
      return _handle(res);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException(503, 'Network request timed out or unavailable.');
    }
  }

  static Future<Map<String, dynamic>> post(
    String url,
    Map<String, dynamic> body, {
    bool auth = true,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse(url),
            headers: _headers(auth: auth),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));
      return _handle(res);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException(503, 'Network request timed out or unavailable.');
    }
  }

  static Future<Map<String, dynamic>> patch(
    String url,
    Map<String, dynamic> body,
  ) async {
    try {
      final res = await http
          .patch(
            Uri.parse(url),
            headers: _headers(),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));
      return _handle(res);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException(503, 'Network request timed out or unavailable.');
    }
  }

  static Map<String, dynamic> _handle(http.Response res) {
    final body = res.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(res.body) as Map<String, dynamic>;

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return body;
    }
    throw ApiException(
      res.statusCode,
      body['error']?.toString() ?? 'Request failed (${res.statusCode})',
    );
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException(this.statusCode, this.message);

  @override
  String toString() => message;
}
