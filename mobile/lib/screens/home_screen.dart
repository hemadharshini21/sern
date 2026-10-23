import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/incident.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';
import 'emergency_setup_screen.dart';
import 'history_screen.dart';
import 'login_screen.dart';
import 'matching_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  User? _user;
  String _locationLabel = 'Bangalore City Center';
  LatLng _userPosition = const LatLng(12.9716, 77.5946); // Bangalore center
  final MapController _mapController = MapController();

  late AnimationController _pulseController;
  List<LatLng> _nearbyAmbulances = [];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _generateNearbyAmbulances(_userPosition);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUser();
      _loadLocation();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    if (await AuthService.isLoggedIn()) {
      final u = await AuthService.me();
      if (mounted) setState(() => _user = u);
    }
  }

  Future<void> _loadLocation() async {
    try {
      final pos = await LocationService.getCurrentPosition();
      if (!mounted) return;
      final newPos = LatLng(pos.latitude, pos.longitude);
      setState(() {
        _userPosition = newPos;
        _locationLabel =
            'Bangalore GPS (${pos.latitude.toStringAsFixed(3)}, ${pos.longitude.toStringAsFixed(3)})';
        _generateNearbyAmbulances(newPos);
      });
      _mapController.move(newPos, 14.5);
    } catch (_) {
      if (mounted) {
        setState(() {
          _locationLabel = 'Bangalore City Center';
          _generateNearbyAmbulances(_userPosition);
        });
      }
    }
  }

  void _generateNearbyAmbulances(LatLng center) {
    _nearbyAmbulances = [
      LatLng(center.latitude + 0.006, center.longitude + 0.005),
      LatLng(center.latitude - 0.005, center.longitude + 0.007),
      LatLng(center.latitude + 0.008, center.longitude - 0.004),
      LatLng(center.latitude - 0.004, center.longitude - 0.006),
    ];
  }

  Future<void> _goToEmergencySetup() async {
    final incident = await Navigator.of(context).push<Incident>(
      MaterialPageRoute(builder: (_) => const EmergencySetupScreen()),
    );
    if (incident != null && mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => MatchingScreen(incident: incident),
        ),
      );
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _openLogin() async {
    final ok = await Navigator.of(context)
        .push<bool>(MaterialPageRoute(builder: (_) => const LoginScreen()));
    if (ok == true) _loadUser();
  }

  @override
  Widget build(BuildContext context) {
    final firstName = _user?.name.split(' ').first;
    final brightness = Theme.of(context).brightness;
    final lowColor = AppColors.severityColor('low', brightness);

    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: Stack(
        children: [
          // ---------- VECTOR MAP BACKGROUND ----------
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _userPosition,
                initialZoom: 14.5,
                minZoom: 10,
                maxZoom: 18,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.sern.sern_citizen',
                ),

                // Map Markers
                MarkerLayer(
                  markers: [
                    // Patient Location Pin with Animated Pulse
                    Marker(
                      point: _userPosition,
                      width: 70,
                      height: 70,
                      child: AnimatedBuilder(
                        animation: _pulseController,
                        builder: (_, _) {
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 30 + (35 * _pulseController.value),
                                height: 30 + (35 * _pulseController.value),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.primary.withValues(
                                    alpha: 0.3 * (1 - _pulseController.value),
                                  ),
                                ),
                              ),
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                  border:
                                      Border.all(color: Colors.white, width: 3),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(alpha: 0.4),
                                      blurRadius: 14,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.person_pin_circle_rounded,
                                  color: Colors.white,
                                  size: 26,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),

                    // Nearby Available Ambulance Pins
                    ..._nearbyAmbulances.map(
                      (pos) => Marker(
                        point: pos,
                        width: 48,
                        height: 48,
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.5),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.4),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.local_hospital_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ---------- FLOATING GLASS TOP HEADER ----------
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surface(context).withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border(context)),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black45,
                    blurRadius: 16,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Icon(
                      Icons.local_hospital_rounded,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          firstName == null ? 'SERN Citizen' : 'Hi, $firstName',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary(context),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              size: 13,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                _locationLabel,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary(context),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.person_outline_rounded,
                        color: AppColors.textPrimary(context)),
                    onPressed: () {
                      if (_user == null) {
                        _openLogin();
                      } else {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ProfileScreen(),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),

          // ---------- SINGLE UNIFIED EMERGENCY AMBULANCE DRAWER CARD ----------
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              decoration: BoxDecoration(
                color: AppColors.surface(context).withValues(alpha: 0.96),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
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
                  // Top Drag Handle
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

                  // Header Badge: Nearby Ambulances Status
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: lowColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: lowColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: lowColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${_nearbyAmbulances.length} Ambulances Nearby',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: lowColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Instant Dispatch',
                          textAlign: TextAlign.end,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary(context),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // SINGLE UNIFIED AMBULANCE BOOKING BUTTON (Clinical Teal Primary)
                  GestureDetector(
                    onTap: _goToEmergencySetup,
                    child: AnimatedBuilder(
                      animation: _pulseController,
                      builder: (_, _) {
                        return Container(
                          height: 64,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(
                                  alpha: 0.4 + (0.2 * _pulseController.value),
                                ),
                                blurRadius: 18 + (6 * _pulseController.value),
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.local_hospital_rounded,
                                  color: Colors.white, size: 30),
                              SizedBox(width: 10),
                              Text(
                                'BOOK EMERGENCY AMBULANCE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Bottom Action Tile: Incident History
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const HistoryScreen(),
                      ),
                    ),
                    icon: Icon(Icons.history_rounded,
                        size: 18, color: AppColors.textSecondary(context)),
                    label: Text('Incident History',
                        style: TextStyle(color: AppColors.textPrimary(context), fontSize: 13, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: AppColors.border(context)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}