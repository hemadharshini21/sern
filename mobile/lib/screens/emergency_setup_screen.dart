import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/incident_service.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';
import 'map_picker_screen.dart';

class EmergencySetupScreen extends StatefulWidget {
  const EmergencySetupScreen({super.key});

  @override
  State<EmergencySetupScreen> createState() => _EmergencySetupScreenState();
}

class _EmergencySetupScreenState extends State<EmergencySetupScreen> {
  bool _firing = false;
  final TextEditingController _landmarkController = TextEditingController();

  // Binary urgency toggle selection ("critical_emergency" or "stable_urgent")
  String? _selectedUrgency;

  // Selected ambulance tier ('als', 'bls', 'transport')
  String _selectedAmbulanceTier = 'als';

  // Location state
  String _pickupAddress = 'Bangalore City Center (Detected GPS)';
  double _lat = 12.9716;
  double _lng = 77.5946;
  bool _loadingLocation = true;

  // Rapido-inspired destination selection
  String _selectedHospital = 'Nearest Emergency Room (Auto-select)';

  @override
  void initState() {
    super.initState();
    _fetchCurrentLocation();
  }

  @override
  void dispose() {
    _landmarkController.dispose();
    super.dispose();
  }

  Future<void> _fetchCurrentLocation() async {
    try {
      final pos = await LocationService.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
        _pickupAddress =
            'Bangalore GPS (${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)})';
        _loadingLocation = false;
      });
    } catch (_) {
      if (mounted) {
      }
    }
  }

  Future<void> _openMapPicker() async {
    final res = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => MapPickerScreen(
          initialLat: _lat,
          initialLng: _lng,
          initialAddress: _pickupAddress,
        ),
      ),
    );
    if (res != null && mounted) {
      setState(() {
        _lat = res['lat'] as double;
        _lng = res['lng'] as double;
        _pickupAddress = res['address'] as String;
      });
    }
  }

  void _openLocationSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final spots = [
          {'name': 'Current Detected GPS', 'lat': 12.9716, 'lng': 77.5946, 'sub': 'Bangalore City Center'},
          {'name': 'Koramangala 80ft Road', 'lat': 12.9352, 'lng': 77.6245, 'sub': 'South Bangalore Zone'},
          {'name': 'Indiranagar 100ft Road', 'lat': 12.9784, 'lng': 77.6408, 'sub': 'East Bangalore Zone'},
          {'name': 'Whitefield Main Road', 'lat': 12.9698, 'lng': 77.7500, 'sub': 'IT Hub Corridor'},
          {'name': 'Hebbal Flyover Junction', 'lat': 13.0359, 'lng': 77.5970, 'sub': 'North Bangalore Zone'},
        ];

        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              16,
              20,
              MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
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
                  Text(
                    'Select Pickup Location',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary(ctx),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Choose your exact pickup address for emergency dispatch',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary(ctx)),
                  ),
                  const SizedBox(height: 16),

                  // Option to Pick on Interactive Map
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.primary),
                    ),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.map_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      title: const Text(
                        'Pick Pin on Interactive Map',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        'Tap or drag map to choose exact GPS point',
                        style: TextStyle(
                          color: AppColors.textSecondary(ctx),
                          fontSize: 12,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.primary,
                      ),
                      onTap: () {
                        Navigator.of(ctx).pop();
                        _openMapPicker();
                      },
                    ),
                  ),

                  ...spots.map((spot) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated(ctx),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: spot['name'] == _pickupAddress
                                ? AppColors.primary
                                : AppColors.border(ctx),
                          ),
                        ),
                        child: ListTile(
                          leading: Icon(
                            Icons.location_on_rounded,
                            color: spot['name'] == _pickupAddress
                                ? AppColors.primary
                                : AppColors.textSecondary(ctx),
                          ),
                          title: Text(
                            spot['name'] as String,
                            style: TextStyle(
                              color: AppColors.textPrimary(ctx),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            spot['sub'] as String,
                            style: TextStyle(
                                color: AppColors.textSecondary(ctx), fontSize: 12),
                          ),
                          trailing: spot['name'] == _pickupAddress
                              ? const Icon(Icons.check_circle_rounded,
                                  color: AppColors.primary, size: 20)
                              : null,
                          onTap: () {
                            setState(() {
                              _lat = spot['lat'] as double;
                              _lng = spot['lng'] as double;
                              _pickupAddress = spot['name'] as String;
                            });
                            Navigator.of(ctx).pop();
                          },
                        ),
                      )),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _openHospitalPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final hospitals = [
          {
            'name': 'Nearest Emergency Room (Auto-select)',
            'sub': 'Fastest dispatch to nearest available ER',
            'beds': 'Fastest Dispatch',
            'isAuto': true,
          },
          {
            'name': 'Manipal Hospital ER',
            'sub': 'HAL Airport Road · 2.4 km away',
            'beds': '12 ICU Beds Free',
            'isAuto': false,
          },
          {
            'name': 'St. John\'s Emergency Center',
            'sub': 'Koramangala · 3.8 km away',
            'beds': '8 ICU Beds Free',
            'isAuto': false,
          },
          {
            'name': 'Victoria Hospital Trauma',
            'sub': 'Fort Road · 4.5 km away',
            'beds': 'Level-1 Trauma Center',
            'isAuto': false,
          },
        ];

        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              16,
              20,
              MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                Text(
                  'Select Target Emergency Room',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary(ctx),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Where should the dispatched ambulance transport the patient?',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary(ctx)),
                ),
                const SizedBox(height: 16),
                ...hospitals.map((h) {
                  final isSel = h['name'] == _selectedHospital;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: isSel
                          ? AppColors.primary.withValues(alpha: 0.12)
                          : AppColors.surfaceElevated(ctx),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSel ? AppColors.primary : AppColors.border(ctx),
                        width: isSel ? 2 : 1,
                      ),
                    ),
                    child: ListTile(
                      leading: Icon(
                        h['isAuto'] == true
                            ? Icons.flash_on_rounded
                            : Icons.local_hospital_rounded,
                        color: isSel ? AppColors.primary : AppColors.textSecondary(ctx),
                      ),
                      title: Text(
                        h['name'] as String,
                        style: TextStyle(
                          color: AppColors.textPrimary(ctx),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        '${h['sub']} • ${h['beds']}',
                        style: TextStyle(
                          color: AppColors.textSecondary(ctx),
                          fontSize: 11,
                        ),
                      ),
                      trailing: isSel
                          ? const Icon(Icons.check_circle_rounded,
                              color: AppColors.primary, size: 20)
                          : null,
                      onTap: () {
                        setState(() {
                          _selectedHospital = h['name'] as String;
                        });
                        Navigator.of(ctx).pop();
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _fireBooking() async {
    if (_firing || _selectedUrgency == null) return;
    setState(() => _firing = true);

    try {
      await AuthService.ensureGuest();

      final landmark = _landmarkController.text.trim();
      final incident = await IncidentService.create(
        type: _selectedUrgency!,
        landmark: landmark.isNotEmpty ? landmark : null,
        lat: _lat,
        lng: _lng,
        patient: 'self',
      );

      if (!mounted) return;
      Navigator.of(context).pop(incident);
    } catch (e) {
      if (!mounted) return;
      setState(() => _firing = false);
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: AppColors.surface(context),
          title: Text('Failed to book ambulance',
              style: TextStyle(color: AppColors.textPrimary(context))),
          content: Text(e.toString(),
              style: TextStyle(color: AppColors.textSecondary(context))),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                _fireBooking();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final criticalColor = AppColors.severityColor('critical', brightness);
    final criticalBg = AppColors.severityBgColor('critical', brightness);
    final stableColor = AppColors.severityColor('medium', brightness);
    final stableBg = AppColors.severityBgColor('medium', brightness);

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        backgroundColor: AppColors.background(context),
        elevation: 0,
        title: Text(
          'Confirm Ambulance Request',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary(context),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.close_rounded, color: AppColors.textPrimary(context)),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [


                    // ---------- INTERACTIVE PICKUP LOCATION CARD ----------
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface(context),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.border(context)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.my_location_rounded,
                                    color: AppColors.severityColor('low', brightness),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'CONFIRM PICKUP LOCATION',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.severityColor('low', brightness),
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                ],
                              ),
                              TextButton.icon(
                                onPressed: _openMapPicker,
                                icon: const Icon(Icons.edit_location_alt_rounded,
                                    size: 14, color: AppColors.primary),
                                label: const Text(
                                  'Change',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Location Detail Box
                          InkWell(
                            onTap: _openLocationSelector,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceElevated(context),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border(context)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.location_on_rounded,
                                      color: AppColors.primary,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _pickupAddress,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textPrimary(context),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _loadingLocation
                                              ? 'Detecting high-precision GPS...'
                                              : 'GPS Pin: ${_lat.toStringAsFixed(4)}, ${_lng.toStringAsFixed(4)}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textSecondary(context),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.chevron_right_rounded,
                                      color: AppColors.textSecondary(context)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ---------- TARGET HOSPITAL DESTINATION CARD (RAPIDO STYLE) ----------
                    Container(
                      margin: const EdgeInsets.only(top: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface(context),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.border(context)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.local_hospital_rounded,
                                    color: AppColors.primary,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'TARGET HOSPITAL DESTINATION',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                ],
                              ),
                              TextButton.icon(
                                onPressed: _openHospitalPicker,
                                icon: const Icon(Icons.search_rounded,
                                    size: 14, color: AppColors.primary),
                                label: const Text(
                                  'Change',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          InkWell(
                            onTap: _openHospitalPicker,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceElevated(context),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border(context)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.local_hospital_rounded,
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
                                          _selectedHospital,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textPrimary(context),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Patient will be transported to this ER center',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textSecondary(context),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.chevron_right_rounded,
                                      color: AppColors.textSecondary(context)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ---------- LANDMARK / GATE NOTE FIELD ----------
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface(context),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.border(context)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.edit_note_rounded,
                                color: AppColors.textSecondary(context),
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'LANDMARK OR GATE INSTRUCTIONS (OPTIONAL)',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textSecondary(context),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _landmarkController,
                            style: TextStyle(color: AppColors.textPrimary(context), fontSize: 13),
                            decoration: InputDecoration(
                              hintText:
                                  'e.g. Near HDFC Bank ATM, Gate 2, 3rd Floor',
                              hintStyle: TextStyle(
                                color: AppColors.textMuted(context),
                                fontSize: 13,
                              ),
                              filled: true,
                              fillColor: AppColors.surfaceElevated(context),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: AppColors.border(context)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: AppColors.border(context)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    const BorderSide(color: AppColors.primary),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ---------- BINARY URGENCY SELECTION TOGGLE ----------
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface(context),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: _selectedUrgency == null
                              ? AppColors.border(context)
                              : AppColors.primary.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Is this life-threatening right now?',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary(context),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              // 🔴 Yes — Critical Option
                              Expanded(
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      _selectedUrgency = 'critical_emergency';
                                      _selectedAmbulanceTier = 'als';
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                      horizontal: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _selectedUrgency == 'critical_emergency'
                                          ? criticalBg
                                          : AppColors.surfaceElevated(context),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _selectedUrgency == 'critical_emergency'
                                            ? criticalColor
                                            : AppColors.border(context),
                                        width: _selectedUrgency == 'critical_emergency' ? 2 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Text('🔴', style: TextStyle(fontSize: 16)),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            'Yes — Critical',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: _selectedUrgency == 'critical_emergency'
                                                  ? criticalColor
                                                  : AppColors.textPrimary(context),
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(width: 10),

                              // 🟡 No — Stable but urgent Option
                              Expanded(
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      _selectedUrgency = 'stable_urgent';
                                      _selectedAmbulanceTier = 'bls';
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                      horizontal: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _selectedUrgency == 'stable_urgent'
                                          ? stableBg
                                          : AppColors.surfaceElevated(context),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _selectedUrgency == 'stable_urgent'
                                            ? stableColor
                                            : AppColors.border(context),
                                        width: _selectedUrgency == 'stable_urgent' ? 2 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Text('🟡', style: TextStyle(fontSize: 16)),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            'No — Stable',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: _selectedUrgency == 'stable_urgent'
                                                  ? stableColor
                                                  : AppColors.textPrimary(context),
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ---------- RAPIDO-INSPIRED AMBULANCE TIER SELECTOR ----------
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface(context),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.border(context)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'AVAILABLE AMBULANCE TIERS',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textSecondary(context),
                                  letterSpacing: 0.6,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1D9E75).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text(
                                  'Govt EMS Free',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1D9E75),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          _buildAmbulanceTierTile(
                            tierId: 'als',
                            title: 'ALS Emergency Ambulance',
                            subtitle: 'ICU Ventilator, Defibrillator & Paramedic Crew',
                            eta: '2 mins away',
                            tag: 'Priority #1',
                            urgency: 'critical_emergency',
                          ),
                          const SizedBox(height: 10),

                          _buildAmbulanceTierTile(
                            tierId: 'bls',
                            title: 'BLS Standard Ambulance',
                            subtitle: 'Oxygen Cylinder, Stretcher & First Aid Kit',
                            eta: '3 mins away',
                            tag: 'Standard EMS',
                            urgency: 'stable_urgent',
                          ),
                          const SizedBox(height: 10),

                          _buildAmbulanceTierTile(
                            tierId: 'transport',
                            title: 'Patient Transport Ambulance',
                            subtitle: 'Wheelchair Accessible • Non-critical Transit',
                            eta: '5 mins away',
                            tag: 'Stable Transit',
                            urgency: 'stable_urgent',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ---------- BOTTOM CONFIRM & BOOK BUTTON ----------
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: FilledButton(
                onPressed: (_selectedUrgency == null || _firing) ? null : _fireBooking,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  backgroundColor: _selectedUrgency == null ? AppColors.surfaceElevated(context) : AppColors.primary,
                  disabledBackgroundColor: AppColors.surfaceElevated(context),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _firing
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.local_hospital_rounded,
                            color: _selectedUrgency == null ? AppColors.textMuted(context) : Colors.white,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'CONFIRM & BOOK AMBULANCE NOW',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: _selectedUrgency == null ? AppColors.textMuted(context) : Colors.white,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmbulanceTierTile({
    required String tierId,
    required String title,
    required String subtitle,
    required String eta,
    required String tag,
    required String urgency,
  }) {
    final isSelected = _selectedAmbulanceTier == tierId && _selectedUrgency == urgency;
    final primaryColor = tierId == 'als' ? const Color(0xFFDC2626) : const Color(0xFF1D9E75);

    return InkWell(
      onTap: () {
        setState(() {
          _selectedAmbulanceTier = tierId;
          _selectedUrgency = urgency;
        });
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor.withValues(alpha: 0.12)
              : AppColors.surfaceElevated(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? primaryColor : AppColors.border(context),
            width: isSelected ? 1.8 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? primaryColor.withValues(alpha: 0.18)
                    : AppColors.surface(context),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.airport_shuttle_rounded,
                color: isSelected ? primaryColor : AppColors.textSecondary(context),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary(context),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (isSelected)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'SELECTED',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        eta,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '•  $tag',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary(context),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              color: isSelected ? primaryColor : AppColors.border(context),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
