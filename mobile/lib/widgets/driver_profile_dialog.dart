import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'vehicle_driver_widgets.dart';

/// Modal bottom sheet showing driver/paramedic credentials & vehicle image
void showDriverProfileModal({
  required BuildContext context,
  required String driverName,
  required String vehicleNumber,
  required String distanceText,
  required VoidCallback onCall,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface(context),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      final brightness = Theme.of(ctx).brightness;
      final medColor = AppColors.severityColor('medium', brightness);

      return SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle Bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border(ctx),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Emergency Responder Profile',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary(ctx),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1D9E75).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF1D9E75)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified_rounded, size: 14, color: Color(0xFF1D9E75)),
                        SizedBox(width: 4),
                        Text(
                          'Verified EMS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1D9E75),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Driver Portrait Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated(ctx),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border(ctx)),
                ),
                child: Row(
                  children: [
                    // Driver Photo Avatar
                    const DriverAvatarWidget(size: 64),
                    const SizedBox(width: 16),

                    // Driver Credentials
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            driverName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary(ctx),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Chief Paramedic ? Trauma Specialist',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary(ctx),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.star_rounded, size: 16, color: medColor),
                              const SizedBox(width: 4),
                              Text(
                                '4.95',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary(ctx),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '?  428 missions',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary(ctx),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Assigned Ambulance Vehicle Card (Replacing Bike/Auto)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated(ctx),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border(ctx)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Ambulance Icon
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDC2626).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.airport_shuttle_rounded,
                            color: Color(0xFFDC2626),
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Vehicle Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Advanced Life Support (ALS) Ambulance',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary(ctx),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Reg: $vehicleNumber ? Force Traveller',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary(ctx),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 10),

                    // Medical Equipment Tags
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _EquipBadge(label: 'ICU Ventilator', icon: Icons.air_rounded),
                        _EquipBadge(label: 'Cardiac Defibrillator', icon: Icons.monitor_heart_rounded),
                        _EquipBadge(label: 'Oxygen Cylinder', icon: Icons.medical_services_rounded),
                        _EquipBadge(label: 'Emergency Stretcher', icon: Icons.hotel_rounded),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('Close'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        onCall();
                      },
                      icon: const Icon(Icons.phone_in_talk_rounded, size: 18),
                      label: const Text(
                        'Call Driver Now',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF1D9E75),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _EquipBadge extends StatelessWidget {
  final String label;
  final IconData icon;

  const _EquipBadge({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFF1D9E75)),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary(context),
            ),
          ),
        ],
      ),
    );
  }
}
