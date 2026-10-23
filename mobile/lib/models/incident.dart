import 'responder.dart';

class Incident {
  final String id;
  final String citizenId;
  final String type;
  final String? description;
  final String severity;
  final String status;
  final String patient;
  final double lat;
  final double lng;
  final DateTime createdAt;
  final DateTime? closedAt;
  final List<Responder>? rankedResponders;

  Incident({
    required this.id,
    required this.citizenId,
    required this.type,
    this.description,
    required this.severity,
    required this.status,
    required this.patient,
    required this.lat,
    required this.lng,
    required this.createdAt,
    this.closedAt,
    this.rankedResponders,
  });

  factory Incident.fromJson(
    Map<String, dynamic> json, {
    List<Responder>? responders,
  }) {
    return Incident(
      id: (json['id'] ?? '').toString(),
      citizenId: (json['citizen_id'] ?? '').toString(),
      type: (json['type'] ?? 'emergency').toString(),
      description: json['description'] as String?,
      severity: (json['severity'] ?? 'medium').toString(),
      status: (json['status'] ?? 'pending').toString(),
      patient: (json['patient'] ?? 'self').toString(),
      lat: json['lat'] != null ? (json['lat'] as num).toDouble() : 0.0,
      lng: json['lng'] != null ? (json['lng'] as num).toDouble() : 0.0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
      closedAt: json['closed_at'] != null
          ? DateTime.parse(json['closed_at'].toString())
          : null,
      rankedResponders: responders,
    );
  }

  bool get isActive =>
      status == 'pending' || status == 'assigned' || status == 'in_progress';
  bool get isClosed => status == 'resolved' || status == 'cancelled';
}
