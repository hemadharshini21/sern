import 'dart:async';
import 'dart:math' as math;
import 'package:socket_io_client/socket_io_client.dart' as io_client;
import 'package:flutter/foundation.dart';
import '../config/api.dart';

/// GPS position payload from the ambulance captain
class AmbulanceGPS {
  final double lat;
  final double lng;
  final double speed;   // km/h
  final double heading; // degrees
  final int timestamp;

  const AmbulanceGPS({
    required this.lat,
    required this.lng,
    this.speed = 0,
    this.heading = 0,
    required this.timestamp,
  });

  factory AmbulanceGPS.fromMap(Map<String, dynamic> m) => AmbulanceGPS(
        lat: (m['lat'] as num).toDouble(),
        lng: (m['lng'] as num).toDouble(),
        speed: (m['speed'] as num? ?? 0).toDouble(),
        heading: (m['heading'] as num? ?? 0).toDouble(),
        timestamp: (m['timestamp'] as num).toInt(),
      );
}

/// Real-time GPS tracking service using Socket.IO
/// Connects to the backend WebSocket hub and streams ambulance positions.
class GpsTrackingService {
  io_client.Socket? _socket;
  final _positionController = StreamController<AmbulanceGPS>.broadcast();
  final _statusController = StreamController<String>.broadcast();

  bool _connected = false;
  bool get isConnected => _connected;

  Stream<AmbulanceGPS> get positionStream => _positionController.stream;
  Stream<String> get statusStream => _statusController.stream;

  /// Connect and start tracking a specific incident
  void trackIncident(String incidentId) {
    _socket?.disconnect();

    final wsUrl = ApiConfig.baseUrl.replaceFirst('/api', '');

    _socket = io_client.io(
      wsUrl,
      io_client.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(10)
          .setReconnectionDelay(2000)
          .build(),
    );

    _socket!.onConnect((_) {
      _connected = true;
      debugPrint('[GPS] Socket.IO connected — tracking incident $incidentId');
      // Subscribe to this incident's GPS room
      _socket!.emit('user:track', {'incidentId': incidentId});
    });

    _socket!.onDisconnect((_) {
      _connected = false;
      debugPrint('[GPS] Socket.IO disconnected');
    });

    _socket!.onConnectError((err) {
      debugPrint('[GPS] Socket.IO connect error: $err');
    });

    // Live ambulance GPS position updates
    _socket!.on('ambulance:position', (data) {
      try {
        final gps = AmbulanceGPS.fromMap(Map<String, dynamic>.from(data));
        _positionController.add(gps);
      } catch (e) {
        debugPrint('[GPS] Position parse error: $e');
      }
    });

    // Incident status changes (assigned, in_progress, arrived, completed)
    _socket!.on('incident:status', (data) {
      final status = data['status'] as String? ?? '';
      if (status.isNotEmpty) _statusController.add(status);
    });

    _socket!.connect();
  }

  /// Called by the captain/driver app to start broadcasting GPS
  void startCaptainBroadcast({
    required String incidentId,
    required String captainId,
  }) {
    if (_socket == null || !_connected) return;
    _socket!.emit('captain:join', {
      'incidentId': incidentId,
      'captainId': captainId,
    });
  }

  /// Push a GPS position from the driver app
  void pushGPS({
    required String incidentId,
    required double lat,
    required double lng,
    double speed = 0,
    double heading = 0,
  }) {
    if (_socket == null) return;
    _socket!.emit('captain:gps', {
      'incidentId': incidentId,
      'lat': lat,
      'lng': lng,
      'speed': speed,
      'heading': heading,
    });
  }

  void dispose() {
    _socket?.disconnect();
    _socket?.dispose();
    _positionController.close();
    _statusController.close();
  }
}

/// Haversine distance between two GPS points (in km)
double haversineKm(double lat1, double lng1, double lat2, double lng2) {
  const R = 6371.0;
  final dLat = _toRad(lat2 - lat1);
  final dLng = _toRad(lng2 - lng1);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_toRad(lat1)) *
          math.cos(_toRad(lat2)) *
          math.sin(dLng / 2) *
          math.sin(dLng / 2);
  return 2 * R * math.asin(math.sqrt(a));
}

double _toRad(double deg) => deg * math.pi / 180.0;
