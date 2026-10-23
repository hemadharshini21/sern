// Custom vehicle and driver graphic widgets for SERN

import 'package:flutter/material.dart';

/// Rapido/Uber-style 3D-effect Ambulance Vehicle graphic on map
class AmbulanceVehicleWidget extends StatelessWidget {
  final bool isTop;
  final String plateNumber;
  final double heading; // in degrees

  const AmbulanceVehicleWidget({
    super.key,
    this.isTop = true,
    this.plateNumber = 'KA-05-1082',
    this.heading = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Plate / ETA Tag above vehicle
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.white70, width: 1),
            boxShadow: const [
              BoxShadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2)),
            ],
          ),
          child: Text(
            plateNumber,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: 2),

        // Ambulance Graphic Container
        Stack(
          alignment: Alignment.center,
          children: [
            // Pulse Beacon Glow Effect
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (isTop ? const Color(0xFFEF4444) : const Color(0xFF3B82F6))
                    .withValues(alpha: 0.3),
              ),
            ),

            // Vehicle Body
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isTop ? const Color(0xFFDC2626) : const Color(0xFF2563EB),
                  width: 2.5,
                ),
                boxShadow: const [
                  BoxShadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, 3)),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Red Cross
                  Icon(
                    Icons.airport_shuttle_rounded,
                    color: isTop ? const Color(0xFFDC2626) : const Color(0xFF2563EB),
                    size: 22,
                  ),
                  // Flashing Beacon Light at top
                  Positioned(
                    top: 2,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF3B82F6),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.blueAccent, blurRadius: 4, spreadRadius: 1),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Paramedic / Driver Photo Avatar with verified badge
class DriverAvatarWidget extends StatelessWidget {
  final double size;
  final bool showBadge;

  const DriverAvatarWidget({
    super.key,
    this.size = 52,
    this.showBadge = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Paramedic Portrait Container
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF1E293B),
              border: Border.all(color: const Color(0xFF1D9E75), width: 2),
              boxShadow: const [
                BoxShadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, 2)),
              ],
            ),
            child: ClipOval(
              child: Container(
                color: const Color(0xFF0F172A),
                child: Center(
                  child: Icon(
                    Icons.account_circle_rounded,
                    size: size * 0.95,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ),
            ),
          ),

          // Verified Green / Blue Badge
          if (showBadge)
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Color(0xFF1D9E75),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 10,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
