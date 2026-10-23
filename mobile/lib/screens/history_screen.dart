import 'package:flutter/material.dart';

import '../models/incident.dart';
import '../services/auth_service.dart';
import '../services/incident_service.dart';
import '../theme/app_theme.dart';
import 'incident_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Incident>? _incidents;
  String? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    if (!await AuthService.isLoggedIn()) {
      setState(() {
        _error = 'Sign in to view your incident history.';
        _loading = false;
      });
      return;
    }

    try {
      final list = await IncidentService.list();
      if (mounted) setState(() => _incidents = list);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading && _incidents == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline, size: 48, color: AppColors.textMuted(context)),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary(context)),
              ),
              const SizedBox(height: 16),
              OutlinedButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final list = _incidents ?? [];
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.history, size: 48, color: AppColors.textMuted(context)),
              const SizedBox(height: 12),
              Text(
                'No incidents yet',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary(context),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Your SOS requests will appear here.',
                style: TextStyle(color: AppColors.textSecondary(context)),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _IncidentCard(
          incident: list[i],
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => IncidentScreen(incident: list[i]),
            ),
          ),
        ),
      ),
    );
  }
}

class _IncidentCard extends StatelessWidget {
  final Incident incident;
  final VoidCallback onTap;

  const _IncidentCard({
    required this.incident,
    required this.onTap,
  });

  String _formatDate(DateTime d) {
    final l = d.toLocal();
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final h = l.hour.toString().padLeft(2, '0');
    final m = l.minute.toString().padLeft(2, '0');
    return '${l.day} ${months[l.month - 1]} ${l.year} · $h:$m';
  }

  Color _statusColor(String s, Brightness brightness) {
    switch (s.toLowerCase()) {
      case 'pending':
        return AppColors.severityColor('medium', brightness);
      case 'assigned':
      case 'in_progress':
        return AppColors.primary;
      case 'resolved':
        return AppColors.severityColor('low', brightness);
      case 'cancelled':
      default:
        return brightness == Brightness.dark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final sevColor = AppColors.severityColor(incident.severity, brightness);
    final sevBg = AppColors.severityBgColor(incident.severity, brightness);
    final statColor = _statusColor(incident.status, brightness);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radius),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(AppTheme.radius),
          border: Border.all(color: AppColors.border(context)),
        ),
        child: Row(
          children: [
            // Severity badge
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: sevBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.local_hospital, color: sevColor, size: 22),
            ),
            const SizedBox(width: 12),

            // Middle: title + subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        incident.type.toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppColors.textPrimary(context),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: sevBg,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          incident.severity.toUpperCase(),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: sevColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(incident.createdAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: statColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        incident.status.replaceAll('_', ' '),
                        style: TextStyle(
                          fontSize: 11,
                          color: statColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary(context),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
