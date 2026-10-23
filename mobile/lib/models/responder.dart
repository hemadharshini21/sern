class Responder {
  final String userId;
  final double matchScore;
  final double distanceKm;
  final List<String>? skills;
  final double? avgResponseTime;
  final double? acceptanceRate;
  final double? lat;
  final double? lng;

  Responder({
    required this.userId,
    required this.matchScore,
    required this.distanceKm,
    this.skills,
    this.avgResponseTime,
    this.acceptanceRate,
    this.lat,
    this.lng,
  });

  factory Responder.fromJson(
    Map<String, dynamic> json, {
    double? incidentLat,
    double? incidentLng,
  }) {
    // If backend doesn't return lat/lng, simulate a position
    // by placing the ambulance at the given distance in a deterministic direction.
    double? lat = json['lat'] != null ? (json['lat'] as num).toDouble() : null;
    double? lng = json['lng'] != null ? (json['lng'] as num).toDouble() : null;

    if (lat == null && incidentLat != null && incidentLng != null) {
      final dist = (json['distance_km'] as num).toDouble();
      // deterministic angle based on user_id hash so pins don't overlap
      final angle = (json['user_id'].toString().hashCode % 360) * 3.14159 / 180;
      // 1 deg lat ≈ 111 km
      lat = incidentLat + (dist / 111.0) * (angle).abs().clamp(0.2, 1.0);
      lng =
          incidentLng +
          (dist / (111.0 * 0.9)) * (1 - angle.abs()).clamp(0.2, 1.0);
    }

    return Responder(
      userId: json['user_id'],
      matchScore: (json['match_score'] as num).toDouble(),
      distanceKm: (json['distance_km'] as num).toDouble(),
      skills: json['skills'] != null ? List<String>.from(json['skills']) : null,
      avgResponseTime: json['avg_response_time'] != null
          ? (json['avg_response_time'] as num).toDouble()
          : null,
      acceptanceRate: json['acceptance_rate'] != null
          ? (json['acceptance_rate'] as num).toDouble()
          : null,
      lat: lat,
      lng: lng,
    );
  }

  /// ETA in minutes = distance_km ÷ average ambulance speed (assume 30 km/h in city)
  int get etaMinutes => ((distanceKm / 30.0) * 60).round().clamp(1, 60);
}
