import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? _user;
  bool _loading = true;

  // Local-only emergency contacts (stored in SharedPreferences)
  List<Map<String, String>> _contacts = [];

  // Medical info (self only)
  String _bloodGroup = '';
  String _allergies = '';

  static const _contactsKey = 'emergency_contacts';
  static const _bloodKey = 'medical_blood_group';
  static const _allergiesKey = 'medical_allergies';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();

    // Load contacts
    final raw = prefs.getStringList(_contactsKey) ?? [];
    _contacts = raw.map((e) {
      final parts = e.split('|');
      return {'name': parts[0], 'phone': parts[1]};
    }).toList();

    _bloodGroup = prefs.getString(_bloodKey) ?? '';
    _allergies = prefs.getString(_allergiesKey) ?? '';

    // Load user
    if (await AuthService.isLoggedIn()) {
      final u = await AuthService.me();
      if (mounted) setState(() => _user = u);
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _saveContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = _contacts.map((c) => '${c['name']}|${c['phone']}').toList();
    await prefs.setStringList(_contactsKey, raw);
  }

  Future<void> _saveMedical() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_bloodKey, _bloodGroup);
    await prefs.setString(_allergiesKey, _allergies);
  }

  Future<void> _addContact() async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface(context),
        title: Text('Add emergency contact',
            style: TextStyle(color: AppColors.textPrimary(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: TextStyle(color: AppColors.textPrimary(context)),
              decoration: InputDecoration(
                labelText: 'Name',
                labelStyle: TextStyle(color: AppColors.textSecondary(context)),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              style: TextStyle(color: AppColors.textPrimary(context)),
              decoration: InputDecoration(
                labelText: 'Phone',
                labelStyle: TextStyle(color: AppColors.textSecondary(context)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary(context))),
          ),
          FilledButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty &&
                  phoneController.text.trim().isNotEmpty) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result == true) {
      setState(() {
        _contacts.add({
          'name': nameController.text.trim(),
          'phone': phoneController.text.trim(),
        });
      });
      await _saveContacts();
    }
  }

  Future<void> _deleteContact(int index) async {
    setState(() => _contacts.removeAt(index));
    await _saveContacts();
  }

  Future<void> _editMedical() async {
    final bloodController = TextEditingController(text: _bloodGroup);
    final allergiesController = TextEditingController(text: _allergies);

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface(context),
        title: Text('Medical info',
            style: TextStyle(color: AppColors.textPrimary(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: bloodController,
              style: TextStyle(color: AppColors.textPrimary(context)),
              decoration: InputDecoration(
                labelText: 'Blood group (e.g., O+)',
                labelStyle: TextStyle(color: AppColors.textSecondary(context)),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: allergiesController,
              style: TextStyle(color: AppColors.textPrimary(context)),
              decoration: InputDecoration(
                labelText: 'Allergies (optional)',
                labelStyle: TextStyle(color: AppColors.textSecondary(context)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary(context))),
          ),
          FilledButton(
            onPressed: () async {
              setState(() {
                _bloodGroup = bloodController.text.trim();
                _allergies = allergiesController.text.trim();
              });
              await _saveMedical();
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _signOut() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface(context),
        title: Text('Sign out?',
            style: TextStyle(color: AppColors.textPrimary(context))),
        content: Text('You will need to sign in again to view history.',
            style: TextStyle(color: AppColors.textSecondary(context))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary(context))),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );

    if (ok == true) {
      await AuthService.logout();
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.background(context),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ---------- USER CARD ----------
          _SectionCard(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                  child: const Icon(
                    Icons.person,
                    size: 36,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _user?.name ?? 'Guest User',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _user?.email ?? 'Not signed in',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary(context),
                  ),
                ),
                if (_user?.phone != null && _user!.phone!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    _user!.phone!,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    (_user?.role ?? 'guest').toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ---------- EMERGENCY CONTACTS ----------
          _SectionHeader(
            title: 'Emergency contacts',
            action: IconButton(
              onPressed: _addContact,
              icon: const Icon(
                Icons.add_circle_outline,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (_contacts.isEmpty)
            _SectionCard(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'No contacts added. Add someone to notify during an emergency.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary(context),
                  ),
                ),
              ),
            )
          else
            ...List.generate(_contacts.length, (i) {
              final c = _contacts[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _SectionCard(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary.withValues(
                        alpha: 0.12,
                      ),
                      child: const Icon(
                        Icons.phone,
                        color: AppColors.primary,
                        size: 18,
                      ),
                    ),
                    title: Text(
                      c['name'] ?? '',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary(context),
                      ),
                    ),
                    subtitle: Text(
                      c['phone'] ?? '',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary(context),
                      ),
                    ),
                    trailing: IconButton(
                      onPressed: () => _deleteContact(i),
                      icon: Icon(Icons.delete_outline,
                          size: 20, color: AppColors.textMuted(context)),
                    ),
                  ),
                ),
              );
            }),

          const SizedBox(height: 16),

          // ---------- MEDICAL INFO ----------
          _SectionHeader(
            title: 'Medical info (self)',
            action: IconButton(
              onPressed: _editMedical,
              icon: const Icon(
                Icons.edit_outlined,
                color: AppColors.primary,
                size: 20,
              ),
            ),
          ),
          const SizedBox(height: 8),
          _SectionCard(
            child: Column(
              children: [
                _InfoRow(
                  label: 'Blood group',
                  value: _bloodGroup.isEmpty ? 'Not set' : _bloodGroup,
                ),
                Divider(height: 20, color: AppColors.border(context)),
                _InfoRow(
                  label: 'Allergies',
                  value: _allergies.isEmpty ? 'None recorded' : _allergies,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ---------- SIGN OUT ----------
          if (_user != null)
            OutlinedButton.icon(
              onPressed: _signOut,
              icon: const Icon(Icons.logout, color: AppColors.primary),
              label: const Text(
                'Sign out',
                style: TextStyle(color: AppColors.primary),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: AppColors.primary),
              ),
            )
          else
            FilledButton(
              onPressed: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const LoginScreen())),
              child: const Text('Sign in'),
            ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ---------- Helpers ----------

class _SectionHeader extends StatelessWidget {
  final String title;
  final Widget? action;
  const _SectionHeader({required this.title, this.action});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary(context),
            ),
          ),
        ),
        ?action,
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: child,
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary(context),
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary(context),
          ),
        ),
      ],
    );
  }
}
