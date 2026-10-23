import 'dart:async';
import 'package:flutter/material.dart';
import '../models/incident.dart';
import '../theme/app_theme.dart';
import 'incident_screen.dart';

class MatchingScreen extends StatefulWidget {
  final Incident incident;

  const MatchingScreen({super.key, required this.incident});

  @override
  State<MatchingScreen> createState() => _MatchingScreenState();
}

class _MatchingScreenState extends State<MatchingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _stepIndex = 0;

  final List<String> _steps = [
    'Scanning 10km spatial radius with PostGIS...',
    'Evaluating ML severity & multi-factor match score...',
    'Matching best ambulance (Distance + Response Speed)...',
    'Ambulance assigned! Redirecting to live tracking...',
  ];

  Timer? _stepTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _stepTimer = Timer.periodic(const Duration(milliseconds: 600), (timer) {
      if (!mounted) return;
      if (_stepIndex < _steps.length - 1) {
        setState(() => _stepIndex++);
      } else {
        timer.cancel();
        Future.delayed(const Duration(milliseconds: 400), () {
          if (!mounted) return;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => IncidentScreen(incident: widget.incident),
            ),
          );
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _stepTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rankedCount = widget.incident.rankedResponders?.length ?? 0;
    final brightness = Theme.of(context).brightness;
    final sevColor = AppColors.severityColor(widget.incident.severity, brightness);

    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Animated Radar Circle
              AnimatedBuilder(
                animation: _controller,
                builder: (_, _) {
                  return SizedBox(
                    width: 200,
                    height: 200,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        for (int i = 0; i < 3; i++)
                          Container(
                            width: 100 + (i * 40) * _controller.value,
                            height: 100 + (i * 40) * _controller.value,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary.withValues(
                                alpha: (0.3 - i * 0.08) * (1 - _controller.value),
                              ),
                            ),
                          ),
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.4),
                                blurRadius: 24,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.local_hospital_rounded,
                            color: Colors.white,
                            size: 44,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 48),

              // Title & Status
              Text(
                'Dispatching Emergency Ambulance',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.3,
                  color: AppColors.textPrimary(context),
                ),
              ),

              const SizedBox(height: 12),

              // Current Step Description
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  _steps[_stepIndex],
                  key: ValueKey(_stepIndex),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary(context),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Severity & Ambulance badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surface(context),
                  borderRadius: BorderRadius.circular(AppTheme.radius),
                  border: Border.all(color: AppColors.border(context)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: sevColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'SEVERITY: ${widget.incident.severity.toUpperCase()}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: sevColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '•  $rankedCount Nearby',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary(context),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
