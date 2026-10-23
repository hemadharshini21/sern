import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../theme/app_theme.dart';

class MapPickerScreen extends StatefulWidget {
  final double initialLat;
  final double initialLng;
  final String initialAddress;

  const MapPickerScreen({
    super.key,
    required this.initialLat,
    required this.initialLng,
    required this.initialAddress,
  });

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  late MapController _mapController;
  late LatLng _selectedCenter;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _selectedCenter = LatLng(widget.initialLat, widget.initialLng);
  }

  void _confirmSelection() {
    final address =
        'Bangalore GPS (${_selectedCenter.latitude.toStringAsFixed(4)}, ${_selectedCenter.longitude.toStringAsFixed(4)})';
    Navigator.of(context).pop({
      'lat': _selectedCenter.latitude,
      'lng': _selectedCenter.longitude,
      'address': address,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        title: Text(
          'Pick Location on Map',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary(context),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.check_rounded, color: AppColors.primary, size: 26),
            onPressed: _confirmSelection,
          ),
        ],
      ),
      body: Stack(
        children: [
          // OpenStreetMap Vector Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedCenter,
              initialZoom: 15.5,
              minZoom: 10,
              maxZoom: 18,
              onPositionChanged: (pos, hasGesture) {
                setState(() {
                  _selectedCenter = pos.center;
                });
              },
              onTap: (tapPos, point) {
                setState(() {
                  _selectedCenter = point;
                });
                _mapController.move(point, _mapController.camera.zoom);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.sern.sern_citizen',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _selectedCenter,
                    width: 60,
                    height: 60,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black45,
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.location_on_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Instruction Toast at Top
          Positioned(
            top: 16,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surface(context).withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border(context)),
                boxShadow: const [
                  BoxShadow(color: Colors.black38, blurRadius: 10),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.touch_app_rounded, color: AppColors.primary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Drag or tap map to position pin',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Floating Details & Confirm Button
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface(context),
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.my_location_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'SELECTED GPS PIN',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textSecondary(context),
                                letterSpacing: 0.6,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${_selectedCenter.latitude.toStringAsFixed(4)}, ${_selectedCenter.longitude.toStringAsFixed(4)}',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: _confirmSelection,
                    icon: const Icon(Icons.check_circle_rounded, size: 20),
                    label: const Text(
                      'CONFIRM THIS PICKUP LOCATION',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
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
