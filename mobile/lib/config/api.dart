import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  // Web browser uses localhost, Android emulator uses 10.0.2.2 to reach host machine's localhost
  static String get baseUrl => kIsWeb ? 'http://localhost:3000' : 'http://10.0.2.2:3000';

  // Auth
  static String get register => '$baseUrl/auth/register';
  static String get login => '$baseUrl/auth/login';
  static String get me => '$baseUrl/auth/me';

  // Incidents
  static String get incidents => '$baseUrl/incidents';
  static String incidentById(String id) => '$baseUrl/incidents/$id';
  static String incidentStatus(String id) => '$baseUrl/incidents/$id/status';

  // Responders
  static String get respondersNearby => '$baseUrl/responders/nearby';
}