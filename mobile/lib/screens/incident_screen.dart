import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/incident.dart';
import '../services/gps_tracking_service.dart';
import '../services/incident_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/driver_profile_dialog.dart';
import '../widgets/vehicle_driver_widgets.dart';

class IncidentScreen extends StatefulWidget {
  final Incident incident;
  const IncidentScreen({super.key, required this.incident});

  @override
  State<IncidentScreen> createState() => _IncidentScreenState();
}

class _IncidentScreenState extends State<IncidentScreen> {
  late Incident _incident;
  final MapController _mapController = MapController();

  // ── Real-time GPS (Socket.IO) ────────────────────────────────────────────
  final GpsTrackingService _gpsService = GpsTrackingService();
  StreamSubscription<AmbulanceGPS>? _gpsSub;
  StreamSubscription<String>? _statusSub;

  // ── Live state ───────────────────────────────────────────────────────────
  LatLng? _ambulancePosition;
  LatLng? _ambulanceStartPosition;
  double _liveDistanceKm = 0.0;
  int _etaSeconds = 0;
  bool _arrivalShown = false;
  bool _socketConnected = false;

  // Fallback simulation (used when Socket.IO is not yet connected)
  Timer? _simTicker;
  int _simElapsed = 0;
  static const int _simTotalSec = 45;

  bool get _isPastIncident =>
      _incident.status == 'cancelled' || _incident.status == 'resolved';
  bool get _hasArrived => _liveDistanceKm <= 0.05;

  @override
  void initState() {
    super.initState();
    _incident = widget.incident;
    _initStartPosition();
    if (!_isPastIncident) {
      _connectSocket();
      _startFallbackSim(); // runs until socket connects
    }
  }

  // ── Initialise ambulance start position ─────────────────────────────────
  void _initStartPosition() {
    final responders = _incident.rankedResponders ?? [];
    if (responders.isNotEmpty &&
        responders.first.lat != null &&
        responders.first.lng != null) {
      _ambulanceStartPosition =
          LatLng(responders.first.lat!, responders.first.lng!);
    } else {
      _ambulanceStartPosition =
          LatLng(_incident.lat + 0.022, _incident.lng + 0.018);
    }
    _ambulancePosition = _ambulanceStartPosition;
    _liveDistanceKm =
        _haversineKm(_ambulancePosition!, LatLng(_incident.lat, _incident.lng));
    _etaSeconds = (_liveDistanceKm / 40.0 * 3600).round();
  }

  // ── Socket.IO real GPS connection ────────────────────────────────────────
  void _connectSocket() {
    _gpsService.trackIncident(_incident.id);

    _gpsSub = _gpsService.positionStream.listen((gps) {
      if (!mounted) return;
      final incidentPt = LatLng(_incident.lat, _incident.lng);
      final newPos = LatLng(gps.lat, gps.lng);
      final distKm = _haversineKm(newPos, incidentPt);
      final eta = distKm > 0.05
          ? (distKm / 40.0 * 3600).round().clamp(0, 3600)
          : 0;

      setState(() {
        _socketConnected = true;
        _ambulancePosition = newPos;
        _liveDistanceKm = distKm;
        _etaSeconds = eta;
      });

      // Cancel fallback sim once real GPS arrives
      _simTicker?.cancel();

      // Trigger arrival once
      if (distKm <= 0.05 && !_arrivalShown) {
        _arrivalShown = true;
        _onAmbulanceArrived();
      }
    });

    // Listen for remote status changes
    _statusSub = _gpsService.statusStream.listen((status) {
      if (!mounted) return;
      setState(() {
        _incident = Incident(
          id: _incident.id,
          citizenId: _incident.citizenId,
          type: _incident.type,
          description: _incident.description,
          severity: _incident.severity,
          status: status,
          patient: _incident.patient,
          lat: _incident.lat,
          lng: _incident.lng,
          createdAt: _incident.createdAt,
          closedAt: _incident.closedAt,
          rankedResponders: _incident.rankedResponders,
        );
      });
      // Notification per status
      _handleStatusNotification(status);
    });
  }

  // ── Fallback GPS simulation (used when Socket.IO not yet connected) ──────
  void _startFallbackSim() {
    _simTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _socketConnected) {
        _simTicker?.cancel();
        return;
      }
      _simElapsed++;
      final incidentPt = LatLng(_incident.lat, _incident.lng);
      final start = _ambulanceStartPosition!;
      final progress = (_simElapsed / _simTotalSec).clamp(0.0, 1.0);
      final newPos = LatLng(
        start.latitude + (incidentPt.latitude - start.latitude) * progress,
        start.longitude + (incidentPt.longitude - start.longitude) * progress,
      );
      final distKm = _haversineKm(newPos, incidentPt);
      final eta = distKm > 0.05
          ? (distKm / 40.0 * 3600).round().clamp(0, 3600)
          : 0;

      setState(() {
        _ambulancePosition = newPos;
        _liveDistanceKm = distKm;
        _etaSeconds = eta;
      });

      if (distKm <= 0.05 && !_arrivalShown) {
        _arrivalShown = true;
        _simTicker?.cancel();
        _onAmbulanceArrived();
      }
    });
  }

  // ── Arrival handler ──────────────────────────────────────────────────────
  Future<void> _onAmbulanceArrived() async {
    // Push local notification with sound
    await NotificationService().showArrived(unitNumber: 'KA-05-EM-1082');
    // Show in-app dialog
    if (mounted) _showArrivalDialog();
  }

  // ── Status notification dispatcher ──────────────────────────────────────
  void _handleStatusNotification(String status) {
    switch (status) {
      case 'assigned':
        NotificationService()
            .showAssigned(unitNumber: 'KA-05-EM-1082');
        break;
      case 'in_progress':
        NotificationService().showEnRoute(
          eta: _formatEta(),
          distanceKm: _formatDistance(),
        );
        break;
      case 'arrived':
        if (!_arrivalShown) {
          _arrivalShown = true;
          _onAmbulanceArrived();
        }
        break;
      case 'completed':
        NotificationService().showCompleted();
        break;
    }
  }

  // ── Haversine distance (km) ──────────────────────────────────────────────
  double _haversineKm(LatLng a, LatLng b) {
    const R = 6371.0;
    final dLat = _rad(b.latitude - a.latitude);
    final dLng = _rad(b.longitude - a.longitude);
    final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_rad(a.latitude)) *
            math.cos(_rad(b.latitude)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return 2 * R * math.asin(math.sqrt(h));
  }

  double _rad(double d) => d * math.pi / 180.0;

  // ── Format helpers ───────────────────────────────────────────────────────
  String _formatEta() {
    if (_hasArrived) return 'Ambulance has arrived';
    if (_etaSeconds <= 0) return 'Arriving now';
    final mins = (_etaSeconds / 60).ceil();
    return 'Arriving in $mins min${mins > 1 ? 's' : ''}';
  }

  String _formatDistance() {
    if (_liveDistanceKm <= 0.05) return 'Arrived';
    if (_liveDistanceKm < 1.0) {
      return '${(_liveDistanceKm * 1000).round()} m away';
    }
    return '${_liveDistanceKm.toStringAsFixed(2)} km away';
  }

  @override
  void dispose() {
    _gpsSub?.cancel();
    _statusSub?.cancel();
    _simTicker?.cancel();
    _gpsService.dispose();
    super.dispose();
  }

  // ── Arrival dialog ───────────────────────────────────────────────────────
  void _showArrivalDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface(context),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF1D9E75), width: 2),
            boxShadow: const [
              BoxShadow(
                  color: Colors.black54, blurRadius: 32, offset: Offset(0, 8)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color:
                      const Color(0xFF1D9E75).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: const Color(0xFF1D9E75), width: 2.5),
                ),
                child: const Icon(Icons.airport_shuttle_rounded,
                    color: Color(0xFF1D9E75), size: 42),
              ),
              const SizedBox(height: 18),
              Text(
                '🚨 Ambulance Arrived!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary(context),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Unit KA-05-EM-1082 (ALS) has reached your location.\nParamedic Rajesh M. is on the way to assist you.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary(context),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 22),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.check_circle_rounded, size: 18),
                label: const Text('Got it',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1D9E75),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Cancel booking ───────────────────────────────────────────────────────
  Future<void> _cancelBooking() async {
    final brightness = Theme.of(context).brightness;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface(context),
        title: Row(children: [
          Icon(Icons.warning_amber_rounded,
              color: AppColors.severityColor('high', brightness)),
          const SizedBox(width: 10),
          Text('Cancel Ambulance?',
              style: TextStyle(
                  color: AppColors.textPrimary(context), fontSize: 16)),
        ]),
        content: Text(
          'Are you sure you want to cancel this emergency ambulance request?',
          style: TextStyle(color: AppColors.textSecondary(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('No, Continue',
                style:
                    TextStyle(color: AppColors.textSecondary(context))),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      _simTicker?.cancel();
      _gpsService.dispose();
      await IncidentService.updateStatus(_incident.id, 'cancelled',
          current: _incident);
    } catch (_) {}

    if (!mounted) return;
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  // ── Call driver ──────────────────────────────────────────────────────────
  Future<void> _callDriver(String name,
      {String phone = '+919876543210'}) async {
    final uri = Uri.parse('tel:${phone.replaceAll(RegExp(r'[^\d+]'), '')}');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (_) {}
    if (!mounted) return;
    final brightness = Theme.of(context).brightness;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface(context),
        title: Row(children: [
          Icon(Icons.phone_in_talk_rounded,
              color: AppColors.severityColor('low', brightness)),
          const SizedBox(width: 10),
          Expanded(
              child: Text('Calling $name',
                  style: TextStyle(
                      color: AppColors.textPrimary(context),
                      fontSize: 16))),
        ]),
        content: Text('Dialing $phone…',
            style:
                TextStyle(color: AppColors.textSecondary(context))),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close',
                  style: TextStyle(
                      color: AppColors.severityColor(
                          'critical', brightness)))),
        ],
      ),
    );
  }

  // ── Ambulance tier sheet ─────────────────────────────────────────────────
  void _openTiersSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface(context),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        final br = Theme.of(ctx).brightness;
        final lowColor = AppColors.severityColor('low', br);
        final medColor = AppColors.severityColor('medium', br);
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                      color: AppColors.border(ctx),
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Text('Ambulance Units Available',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.textPrimary(ctx))),
              const SizedBox(height: 4),
              Text('ML-ranked by proximity & capability',
                  style: TextStyle(
                      fontSize: 12, color: AppColors.textSecondary(ctx))),
              const SizedBox(height: 16),
              _tierTile(ctx,
                  icon: Icons.local_hospital_rounded,
                  title: 'ALS – Advanced Life Support',
                  sub: 'KA-05-EM-1082 · ${_formatDistance()}',
                  color: lowColor,
                  badge: 'ML #1'),
              const SizedBox(height: 10),
              _tierTile(ctx,
                  icon: Icons.airport_shuttle_rounded,
                  title: 'BLS – Basic Life Support',
                  sub: 'KA-01-MH-0441 · 4.2 km away',
                  color: medColor,
                  badge: 'ML #2'),
              const SizedBox(height: 10),
              _tierTile(ctx,
                  icon: Icons.directions_bus_rounded,
                  title: 'Patient Transport',
                  sub: 'KA-09-PT-3302 · 6.8 km away',
                  color: lowColor.withValues(alpha: 0.6),
                  badge: 'ML #3'),
            ],
          ),
        );
      },
    );
  }

  Widget _tierTile(BuildContext ctx,
      {required IconData icon,
      required String title,
      required String sub,
      required Color color,
      required String badge}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: AppColors.surfaceElevated(ctx),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border(ctx))),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(title,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppColors.textPrimary(ctx))),
              Text(sub,
                  style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary(ctx))),
            ]),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8)),
            child: Text(badge,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: color)),
          ),
        ],
      ),
    );
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final lowColor = AppColors.severityColor('low', brightness);
    final medColor = AppColors.severityColor('medium', brightness);

    final ambulances = _incident.rankedResponders ?? [];
    final incidentPoint = LatLng(_incident.lat, _incident.lng);
    final topAmbulance = ambulances.isNotEmpty ? ambulances.first : null;
    final driverName = 'Paramedic Rajesh M. (KA-05-EM-1082)';

    final isCancelled = _incident.status == 'cancelled';
    final isResolved = _incident.status == 'resolved';
    final isPast = isCancelled || isResolved;

    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: Stack(
        children: [
          // ── Full-screen OpenStreetMap ────────────────────────────────────
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                  initialCenter: incidentPoint,
                  initialZoom: 14.5,
                  minZoom: 10,
                  maxZoom: 18),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.sern.sern_citizen',
                ),
                // Route polyline
                if (_ambulancePosition != null)
                  PolylineLayer(polylines: [
                    Polyline(
                        points: [_ambulancePosition!, incidentPoint],
                        strokeWidth: 8,
                        color: Colors.black87),
                    Polyline(
                        points: [_ambulancePosition!, incidentPoint],
                        strokeWidth: 5,
                        color: const Color(0xFF1D9E75)),
                  ]),
                // Markers
                MarkerLayer(markers: [
                  // Patient pickup pin
                  Marker(
                    point: incidentPoint,
                    width: 140,
                    height: 70,
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.black26),
                            boxShadow: const [
                              BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                  offset: Offset(0, 2))
                            ]),
                        child: const Row(mainAxisSize: MainAxisSize.min,
                            children: [
                          Icon(Icons.circle,
                              color: Color(0xFF1D9E75), size: 8),
                          SizedBox(width: 4),
                          Text('Your Location',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87)),
                        ]),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                            color: const Color(0xFF1D9E75),
                            shape: BoxShape.circle,
                            border:
                                Border.all(color: Colors.white, width: 2.5),
                            boxShadow: const [
                              BoxShadow(
                                  color: Colors.black45, blurRadius: 6)
                            ]),
                        child: const Icon(Icons.person_pin_rounded,
                            color: Colors.white, size: 18),
                      ),
                    ]),
                  ),
                  // Ambulance marker
                  if (_ambulancePosition != null)
                    Marker(
                      point: _ambulancePosition!,
                      width: 70,
                      height: 70,
                      child: AmbulanceVehicleWidget(
                          isTop: true, plateNumber: 'KA-05-1082'),
                    ),
                ]),
              ],
            ),
          ),

          // ── Top navigation bar ───────────────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: Row(children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: AppColors.surface(context),
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: AppColors.border(context)),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 6)
                      ]),
                  child: Icon(Icons.arrow_back_rounded,
                      size: 18,
                      color: AppColors.textPrimary(context)),
                ),
              ),
              const SizedBox(width: 8),
              // Live tracking pill
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                      color: AppColors.surface(context),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.border(context)),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 8)
                      ]),
                  child: Row(children: [
                    _PulseDot(
                        arrived: _hasArrived,
                        socketLive: _socketConnected),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _hasArrived
                                  ? 'Ambulance Arrived'
                                  : (_socketConnected
                                      ? 'Live GPS Tracking'
                                      : 'Live Ambulance Tracking'),
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: AppColors.textPrimary(context)),
                            ),
                            Text(
                              _hasArrived
                                  ? 'Paramedic is at your location'
                                  : (_socketConnected
                                      ? 'Real-time GPS · ${_formatDistance()}'
                                      : 'En route via MG Road Corridor'),
                              style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textSecondary(context)),
                            ),
                          ]),
                    ),
                    InkWell(
                      onTap: _openTiersSheet,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                            color: const Color(0xFF1D9E75)
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12)),
                        child: const Row(children: [
                          Icon(Icons.airport_shuttle_rounded,
                              size: 14, color: Color(0xFF1D9E75)),
                          SizedBox(width: 4),
                          Text('ALS Unit',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1D9E75))),
                        ]),
                      ),
                    ),
                  ]),
                ),
              ),
            ]),
          ),

          // ── Re-center button ─────────────────────────────────────────────
          Positioned(
            right: 16,
            bottom: 275,
            child: FloatingActionButton.small(
              backgroundColor: AppColors.surface(context),
              onPressed: () => _mapController.move(incidentPoint, 15.0),
              child: Icon(Icons.my_location_rounded,
                  color: AppColors.textPrimary(context), size: 20),
            ),
          ),

          // ── Bottom drawer ─────────────────────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
              decoration: BoxDecoration(
                  color: AppColors.surface(context),
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(26)),
                  border: Border.all(color: AppColors.border(context)),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black87,
                        blurRadius: 24,
                        offset: Offset(0, -6))
                  ]),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                          color: AppColors.border(context),
                          borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ETA & Status Header (Rapido style clean headline)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isPast
                            ? (isCancelled ? 'Trip Cancelled' : 'Trip Completed')
                            : _formatEta(),
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: isPast
                                ? (isCancelled
                                    ? AppColors.textMuted(context)
                                    : lowColor)
                                : (_hasArrived
                                    ? lowColor
                                    : const Color(0xFF1D9E75))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Driver card
                  if (topAmbulance != null || !isPast)
                    InkWell(
                      onTap: () => showDriverProfileModal(
                          context: context,
                          driverName: driverName,
                          vehicleNumber: 'KA-05-EM-1082',
                          distanceText: _formatDistance(),
                          onCall: () => _callDriver(driverName)),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: AppColors.surfaceElevated(context),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: AppColors.border(context))),
                        child: Row(children: [
                          const DriverAvatarWidget(size: 46),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                              Row(children: [
                                Flexible(
                                  child: Text(driverName,
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13.5,
                                          color: AppColors.textPrimary(
                                              context)),
                                      overflow: TextOverflow.ellipsis),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.info_outline_rounded,
                                    size: 14,
                                    color: Color(0xFF1D9E75)),
                              ]),
                              const SizedBox(height: 2),
                              Row(children: [
                                Icon(Icons.star_rounded,
                                    size: 14, color: medColor),
                                const SizedBox(width: 3),
                                Text('4.9',
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary(
                                            context))),
                                const SizedBox(width: 8),
                                Text('•  ${_formatDistance()}',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondary(
                                            context))),
                              ]),
                            ]),
                          ),
                          InkWell(
                            onTap: () => _callDriver(driverName),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: const BoxDecoration(
                                  color: Color(0xFF1D9E75),
                                  shape: BoxShape.circle),
                              child: const Icon(
                                  Icons.phone_in_talk_rounded,
                                  color: Colors.white,
                                  size: 18),
                            ),
                          ),
                        ]),
                      ),
                    ),

                  const SizedBox(height: 14),

                  // Action buttons
                  if (isPast)
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: FilledButton.styleFrom(
                          backgroundColor:
                              AppColors.surfaceElevated(context),
                          foregroundColor:
                              AppColors.textPrimary(context),
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(
                                  color: AppColors.border(context)))),
                      child: const Text('Back to Home',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    )
                  else
                    Row(children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _cancelBooking,
                          style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14),
                              side: BorderSide(
                                  color: AppColors.border(context)),
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(14))),
                          child: const Text('Cancel Ride',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFEF4444))),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => _callDriver(driverName),
                          icon: const Icon(Icons.phone_in_talk_rounded,
                              size: 18),
                          label: const Text('Call Driver',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold)),
                          style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF1D9E75),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(14))),
                        ),
                      ),
                    ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Animated live GPS pulse dot ───────────────────────────────────────────────
class _PulseDot extends StatefulWidget {
  final bool arrived;
  final bool socketLive;
  const _PulseDot({this.arrived = false, this.socketLive = false});

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _anim = Tween(begin: 0.5, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _ctrl.repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.arrived
        ? const Color(0xFF10B981)
        : widget.socketLive
            ? const Color(0xFF3B82F6) // blue = real Socket.IO GPS
            : const Color(0xFF1D9E75); // green = simulation
    return AnimatedBuilder(
      animation: _anim,
      builder: (ctx, child2) => Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: color.withValues(alpha: _anim.value),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                color: color.withValues(alpha: _anim.value * 0.5),
                blurRadius: 6,
                spreadRadius: 2)
          ],
        ),
      ),
    );
  }
}
