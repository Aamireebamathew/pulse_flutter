import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/supabase_service.dart';
import '../../widgets/common_widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Map<String, dynamic> _prefs = {
    'voice_assistant_enabled': true,
    'camera_detection_enabled': false,
    'notification_sound_enabled': true,
    'alert_sensitivity': 'medium',
  };
  bool _loading = true;
  bool _saving = false;
  String _message = '';
  bool _messageIsError = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;
    final data = await SupabaseService.getUserPreferences(user.id);
    if (data != null) {
      setState(() {
        _prefs = {
          'voice_assistant_enabled': data['voice_assistant_enabled'] ?? true,
          'camera_detection_enabled': data['camera_detection_enabled'] ?? false,
          'notification_sound_enabled': data['notification_sound_enabled'] ?? true,
          'alert_sensitivity': data['alert_sensitivity'] ?? 'medium',
        };
      });
    }
    setState(() => _loading = false);
  }

  Future<void> _savePreferences() async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;
    setState(() => _saving = true);
    try {
      await SupabaseService.updateUserPreferences(user.id, _prefs);
      _showMessage('Settings saved successfully!', false);
    } catch (e) {
      _showMessage('Failed to save settings.', true);
    }
    setState(() => _saving = false);
  }

  void _showMessage(String msg, bool isError) {
    setState(() {
      _message = msg;
      _messageIsError = isError;
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _message = '');
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final auth = context.read<AuthProvider>();
    final theme = context.watch<ThemeProvider>();
    // Use theme-aware colors throughout
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final subtitleColor = colorScheme.onSurface.withOpacity(0.5);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Page title ──────────────────────────────────────────────────
          Text(
            'Settings',
            style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Manage your account and preferences',
            style: textTheme.bodyMedium?.copyWith(color: subtitleColor),
          ),
          const SizedBox(height: 24),

          // ── Message banner ──────────────────────────────────────────────
          if (_message.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _messageIsError
                    ? Colors.red.withOpacity(0.1)
                    : const Color(0xFF22C55E).withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _messageIsError ? Colors.red : const Color(0xFF22C55E),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _messageIsError ? Icons.error_outline : Icons.check_circle_outline,
                    color: _messageIsError ? Colors.red : const Color(0xFF22C55E),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _message,
                      style: TextStyle(
                        color: _messageIsError ? Colors.red : const Color(0xFF22C55E),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // ── Account ─────────────────────────────────────────────────────
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionHeader(icon: Icons.person_outline, label: 'Account'),
                const SizedBox(height: 12),
                _InfoRow(label: 'Email', value: auth.user?.email ?? ''),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.fingerprint, size: 18),
                        label: const Text('Setup Biometrics'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.mic_outlined, size: 18),
                        label: const Text('Setup Voice'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Appearance ──────────────────────────────────────────────────
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionHeader(icon: Icons.palette_outlined, label: 'Appearance'),
                const SizedBox(height: 12),
                _SwitchRow(
                  label: 'Dark Mode',
                  subtitle: 'Switch between light and dark theme',
                  icon: theme.isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                  value: theme.isDark,
                  onChanged: (_) => theme.toggleTheme(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Preferences ─────────────────────────────────────────────────
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionHeader(icon: Icons.tune_outlined, label: 'Preferences'),
                const SizedBox(height: 12),
                _SwitchRow(
                  label: 'Voice Assistant',
                  subtitle: 'Enable voice commands and responses',
                  icon: Icons.mic_outlined,
                  value: _prefs['voice_assistant_enabled'] as bool,
                  onChanged: (v) =>
                      setState(() => _prefs['voice_assistant_enabled'] = v),
                ),
                const Divider(height: 24),
                _SwitchRow(
                  label: 'Camera Detection',
                  subtitle: 'Enable live camera object detection',
                  icon: Icons.camera_alt_outlined,
                  value: _prefs['camera_detection_enabled'] as bool,
                  onChanged: (v) =>
                      setState(() => _prefs['camera_detection_enabled'] = v),
                ),
                const Divider(height: 24),
                _SwitchRow(
                  label: 'Notification Sounds',
                  subtitle: 'Play sound for alerts',
                  icon: Icons.volume_up_outlined,
                  value: _prefs['notification_sound_enabled'] as bool,
                  onChanged: (v) =>
                      setState(() => _prefs['notification_sound_enabled'] = v),
                ),
                const Divider(height: 24),

                // Alert sensitivity segmented control
                Row(
                  children: [
                    Icon(Icons.tune, size: 18, color: subtitleColor),
                    const SizedBox(width: 10),
                    Text(
                      'Alert Sensitivity',
                      style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: ['low', 'medium', 'high'].map((s) {
                    final isSelected = _prefs['alert_sensitivity'] == s;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => _prefs['alert_sensitivity'] = s),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF3B82F6)
                                : colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            s[0].toUpperCase() + s.substring(1),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: isSelected
                                  ? Colors.white
                                  : colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          GradientButton(
            label: 'Save Settings',
            icon: Icons.save_outlined,
            onPressed: _savePreferences,
            loading: _saving,
          ),
          const SizedBox(height: 16),

          // ── Security ────────────────────────────────────────────────────
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionHeader(icon: Icons.security_outlined, label: 'Security'),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () {},
                  icon: Icon(Icons.lock_reset, color: colorScheme.primary),
                  label: Text(
                    'Change Password',
                    style: TextStyle(color: colorScheme.primary),
                  ),
                ),
                const Divider(height: 20),
                TextButton.icon(
                  onPressed: () async {
                    await auth.signOut();
                    if (context.mounted) context.go('/login');
                  },
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: const Text(
                    'Sign Out',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SectionHeader({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF3B82F6)),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final subtitleColor =
        Theme.of(context).colorScheme.onSurface.withOpacity(0.5);
    return Row(
      children: [
        Text(
          '$label: ',
          style: TextStyle(color: subtitleColor),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchRow({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final subtitleColor =
        Theme.of(context).colorScheme.onSurface.withOpacity(0.5);
    return Row(
      children: [
        Icon(icon, size: 20, color: subtitleColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w500),
              ),
              Text(
                subtitle,
                style: TextStyle(color: subtitleColor, fontSize: 12),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFF3B82F6),
        ),
      ],
    );
  }
}