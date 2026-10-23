import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/incident.dart';
import '../services/gps_tracking_service.dart';
import '../services/incident_service.dart';
import '../theme/app_theme.dart';
import '../widgets/vehicle_driver_widgets.dart';

class DriverDispatchScreen extends StatefulWidget {
  final Incident incident;

  const DriverDispatchScreen({super.key, required this.incident});

  @override
  State<DriverDispatchScreen> createState() => _DriverDispatchScreenState();
}

class _DriverDispatchScreenState extends State<DriverDispatchScreen> {
  late String _currentStatus;
  bool _updating = false;
  final MapController _mapController = MapController();

  // ── Real-time GPS broadcasting service ──
  final GpsTrackingService _gpsService = GpsTrackingService();
  Timer? _gpsBroadcastTimer;
  LatLng? _driverLocation;
  late LatLng _startLocation;
  int _step = 0;
  static const int _totalSteps = 30;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.incident.status;
    _startLocation = LatLng(
      widget.incident.lat + 0.022,
      widget.incident.lng + 0.018,
    );
    _driverLocation = _startLocation;

    // Connect to Socket.IO hub as Captain
    _gpsService.trackIncident(widget.incident.id);
    _gpsService.startCaptainBroadcast(
      incidentId: widget.incident.id,
      captainId: 'KA-05-EM-1082',
    );

    // If already in_progress, begin broadcasting
    if (_currentStatus == 'in_progress') {
      _startGpsBroadcasting();
    }
  }

  void _startGpsBroadcasting() {
    _gpsBroadcastTimer?.cancel();
    _gpsBroadcastTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      _step++;
      final target = LatLng(widget.incident.lat, widget.incident.lng);
      final progress = (_step / _totalSteps).clamp(0.0, 1.0);

      final nextLat = _startLocation.latitude + (target.latitude - _startLocation.latitude) * progress;
      final nextLng = _startLocation.longitude + (target.longitude - _startLocation.longitude) * progress;
      final updatedPos = LatLng(nextLat, nextLng);

      setState(() {
        _driverLocation = updatedPos;
      });

      // Broadcast position to user app through backend Socket.IO
      _gpsService.pushGPS(
        incidentId: widget.incident.id,
        lat: updatedPos.latitude,
        lng: updatedPos.longitude,
        speed: progress < 1.0 ? 45.0 : 0.0,
      );

      if (progress >= 1.0) {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _gpsBroadcastTimer?.cancel();
    _gpsService.dispose();
    super.dispose();
  }

  Future<void> _updateStatus(String nextStatus) async {
    if (_updating) return;
    setState(() => _updating = true);

    try {
      await IncidentService.updateStatus(widget.incident.id, nextStatus, current: widget.incident);
      if (!mounted) return;
      setState(() {
        _currentStatus = nextStatus;
        _updating = false;
      });

      // Trigger automatic GPS broadcasting when driving starts
      if (nextStatus == 'in_progress') {
        _startGpsBroadcasting();
      } else if (nextStatus == 'arrived' || nextStatus == 'completed' || nextStatus == 'cancelled') {
        _gpsBroadcastTimer?.cancel();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Dispatch status updated: ${nextStatus.toUpperCase().replaceAll('_', ' ')}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _updating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update status: $e'),
          backgroundColor: AppColors.severityColor('critical', Theme.of(context).brightness),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final patientPoint = LatLng(widget.incident.lat, widget.incident.lng);
    final isCritical = widget.incident.severity.toLowerCase() == 'critical' ||
        widget.incident.type.contains('critical');

    final criticalColor = AppColors.severityColor('critical', brightness);
    final lowColor = AppColors.severityColor('low', brightness);

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        backgroundColor: AppColors.surface(context),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PARAMEDIC DISPATCH CONSOLE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                letterSpacing: 0.8,
              ),
            ),
            Text(
              'Unit: KA-05-EM-1082 (ALS)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary(context),
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isCritical
                  ? criticalColor.withValues(alpha: 0.15)
                  : lowColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isCritical ? criticalColor : lowColor,
              ),
            ),
            child: Text(
              isCritical ? '🔴 CRITICAL DISPATCH' : '🟡 STABLE DISPATCH',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isCritical ? criticalColor : lowColor,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // ---------- OPENSTREETMAP DISPLAY ----------
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: patientPoint,
                initialZoom: 14.5,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.sern.sern_driver',
                ),
                // Route polyline from driver to patient
                if (_driverLocation != null)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: [_driverLocation!, patientPoint],
                        strokeWidth: 5,
                        color: const Color(0xFF1D9E75),
                      ),
                    ],
                  ),
                MarkerLayer(
                  markers: [
                    // Patient Marker
                    Marker(
                      point: patientPoint,
                      width: 50,
                      height: 50,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: const [
                            BoxShadow(color: Colors.black45, blurRadius: 10),
                          ],
                        ),
                        child: const Icon(
                          Icons.person_pin_circle_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                    // Live Ambulance Position Marker
                    if (_driverLocation != null)
                      Marker(
                        point: _driverLocation!,
                        width: 65,
                        height: 65,
                        child: AmbulanceVehicleWidget(
                          isTop: true,
                          plateNumber: 'KA-05-1082',
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // ---------- DRIVER DISPATCH ACTIONS DRAWER CARD ----------
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              decoration: BoxDecoration(
                color: AppColors.surface(context),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(26)),
                border: Border.all(color: AppColors.border(context)),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black87,
                    blurRadius: 24,
                    offset: Offset(0, -6),
                  ),
                ],
              ),
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
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Patient & Location Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated(context),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border(context)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.location_on_rounded,
                            color: AppColors.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.incident.description ??
                                    'Bangalore GPS Location (${widget.incident.lat.toStringAsFixed(3)}, ${widget.incident.lng.toStringAsFixed(3)})',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppColors.textPrimary(context),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Incident ID: ${widget.incident.id.length >= 8 ? widget.incident.id.substring(0, 8) : widget.incident.id} • Live GPS Broadcaster',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // STEP-BY-STEP DRIVER DISPATCH STATE MACHINE BUTTONS
                  _buildStateActionButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStateActionButton() {
    if (_updating) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: CircularProgressIndicator(),
        ),
      );
    }

    switch (_currentStatus) {
      case 'pending':
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _updateStatus('cancelled'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: AppColors.border(context)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'Decline',
                  style: TextStyle(
                    color: AppColors.textSecondary(context),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: () => _updateStatus('assigned'),
                icon: const Icon(Icons.check_circle_rounded, size: 20),
                label: const Text(
                  'ACCEPT DISPATCH',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        );

      case 'assigned':
        return FilledButton.icon(
          onPressed: () => _updateStatus('in_progress'),
          icon: const Icon(Icons.navigation_rounded, size: 20),
          label: const Text(
            'START DRIVING EN-ROUTE (STREAM GPS)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        );

      case 'in_progress':
        return FilledButton.icon(
          onPressed: () => _updateStatus('arrived'),
          icon: const Icon(Icons.where_to_vote_rounded, size: 20),
          label: const Text(
            'MARK ARRIVED AT PATIENT',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.severityColor('low', Theme.of(context).brightness),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        );

      case 'arrived':
        return FilledButton.icon(
          onPressed: () => _updateStatus('completed'),
          icon: const Icon(Icons.task_alt_rounded, size: 20),
          label: const Text(
            'COMPLETE EMERGENCY TRIP',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        );

      case 'completed':
      case 'resolved':
      default:
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated(context),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border(context)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'DISPATCH COMPLETED & RESOLVED',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppColors.textPrimary(context),
                ),
              ),
            ],
          ),
        );
    }
  }
}
