import '../config/api.dart';
import '../models/incident.dart';
import '../models/responder.dart' as responder_model;
import 'api_service.dart';

class IncidentService {
  /// Create a new incident. Returns the incident with ranked responders.
  static Future<Incident> create({
    required String type,
    String? landmark,
    String? description,
    required double lat,
    required double lng,
    String patient = 'self',
  }) async {
    final body = <String, dynamic>{
      'type': type,
      'lat': lat,
      'lng': lng,
      'patient': patient,
    };

    if (landmark != null && landmark.trim().isNotEmpty) {
      body['landmark'] = landmark.trim();
    } else if (description != null && description.trim().isNotEmpty) {
      body['landmark'] = description.trim();
    }

    final res = await ApiService.post(ApiConfig.incidents, body);

    final respondersRaw = res['ranked_responders'] as List? ?? [];
    final responders = respondersRaw
        .map(
          (e) => responder_model.Responder.fromJson(e as Map<String, dynamic>),
        )
        .toList();

    return Incident.fromJson(
      res['incident'] as Map<String, dynamic>,
      responders: responders.cast(),
    );
  }

  static Future<List<Incident>> list({String? status}) async {
    final url = status != null
        ? '${ApiConfig.incidents}?status=$status'
        : ApiConfig.incidents;
    final res = await ApiService.get(url);
    final raw = res['incidents'] as List? ?? [];
    return raw
        .map((e) => Incident.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<Incident> getById(String id) async {
    final res = await ApiService.get(ApiConfig.incidentById(id));
    return Incident.fromJson(res['incident'] as Map<String, dynamic>);
  }

  /// Updates the status of an incident. Merges the returned partial payload
  /// with [current] so that null fields from a fallback response don't crash.
  static Future<Incident> updateStatus(
    String id,
    String status, {
    Incident? current,
  }) async {
    final res = await ApiService.patch(ApiConfig.incidentStatus(id), {
      'status': status,
    });

    final rawIncident = res['incident'] as Map<String, dynamic>? ?? {};

    // If the backend returned a partial object (fallback path), merge with the
    // existing incident data so all required fields remain non-null.
    if (current != null) {
      final merged = <String, dynamic>{
        'id': current.id,
        'citizen_id': current.citizenId,
        'type': current.type,
        'description': current.description,
        'severity': current.severity,
        'status': current.status,
        'patient': current.patient,
        'lat': current.lat,
        'lng': current.lng,
        'created_at': current.createdAt.toIso8601String(),
        'closed_at': current.closedAt?.toIso8601String(),
        // Overlay whatever the API returned on top
        ...rawIncident,
      };
      return Incident.fromJson(merged);
    }

    return Incident.fromJson(rawIncident);
  }
}
