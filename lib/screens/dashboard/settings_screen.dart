import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/supabase_service.dart';
import '../../widgets/common_widgets.dart';
import '../../utils/app_theme.dart';

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
  bool _saving  = false;

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
          'voice_assistant_enabled':
              data['voice_assistant_enabled'] ?? true,
          'camera_detection_enabled':
              data['camera_detection_enabled'] ?? false,
          'notification_sound_enabled':
              data['notification_sound_enabled'] ?? true,
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
      if (mounted) PulseSnackBar.show(context, 'Settings saved!', isSuccess: true);
    } catch (e) {
      if (mounted) PulseSnackBar.show(context, 'Failed to save settings.', isError: true);
    }
    setState(() => _saving = false);
  }

  // ── Biometric setup ───────────────────────────────────────────────────────
  Future<void> _handleBiometricSetup() async {
    final auth = context.read<AuthProvider>();

    if (auth.biometricEnabled) {
      // Already enabled → offer to disable
      final confirm = await _showConfirmDialog(
        title: 'Disable Biometrics',
        body: 'Are you sure you want to disable biometric login?',
        confirmLabel: 'Disable',
        destructive: true,
      );
      if (confirm == true) {
        final err = await auth.disableBiometric();
        if (mounted) {
          if (err == null) {
            PulseSnackBar.show(context, 'Biometric login disabled.', isSuccess: true);
          } else {
            PulseSnackBar.show(context, err, isError: true);
          }
        }
      }
      return;
    }

    if (!auth.biometricAvailable) {
      _showInfoDialog(
        icon: Icons.fingerprint,
        title: 'Not Available',
        body: 'Biometric authentication is not supported on this device or browser.\n\n'
            'To use biometrics, run the app on an Android or iOS device with fingerprint or Face ID enrolled.',
      );
      return;
    }

    // Show setup instructions, then trigger
    final proceed = await _showConfirmDialog(
      title: 'Setup Biometrics',
      body: 'You will be prompted to confirm your fingerprint or Face ID.\n\n'
          'After setup, you can use biometrics to sign in quickly.',
      confirmLabel: 'Continue',
    );
    if (proceed != true) return;

    final err = await auth.setupBiometric();
    if (mounted) {
      if (err == null) {
        PulseSnackBar.show(context,
            'Biometric login enabled! You can now sign in with your fingerprint.',
            isSuccess: true);
        setState(() {});
      } else {
        PulseSnackBar.show(context, err, isError: true);
      }
    }
  }

  // ── Voice setup ───────────────────────────────────────────────────────────
  Future<void> _handleVoiceSetup() async {
    final auth = context.read<AuthProvider>();

    if (auth.voiceEnabled) {
      final confirm = await _showConfirmDialog(
        title: 'Disable Voice Login',
        body: 'Are you sure you want to remove your voice passphrase?',
        confirmLabel: 'Disable',
        destructive: true,
      );
      if (confirm == true) {
        await auth.disableVoice();
        if (mounted) {
          PulseSnackBar.show(context, 'Voice login disabled.', isSuccess: true);
          setState(() {});
        }
      }
      return;
    }

    // Start voice setup wizard
    await _showVoiceSetupSheet(auth);
  }

  Future<void> _showVoiceSetupSheet(AuthProvider auth) async {
    final stt = SpeechToText();
    bool available = false;
    String status  = 'Tap the mic to record your passphrase';
    String spoken  = '';
    bool listening = false;
    bool done      = false;

    try {
      available = await stt.initialize(
        onError: (e) => status = 'Microphone error: ${e.errorMsg}',
        onStatus: (s) {
          if (s == 'done' || s == 'notListening') {
            listening = false;
          }
        },
      );
    } catch (_) {
      available = false;
    }

    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.xl2)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          Future<void> startListening() async {
            if (!available) {
              setSheet(() =>
                  status = 'Microphone not available. Check app permissions.');
              return;
            }
            setSheet(() { listening = true; spoken = ''; status = 'Listening…'; });
            await stt.listen(
              onResult: (result) {
                setSheet(() {
                  spoken = result.recognizedWords;
                  if (result.finalResult) {
                    listening = false;
                    if (spoken.trim().isNotEmpty) {
                      status = 'Heard: "$spoken"\nTap Save to confirm.';
                      done = true;
                    } else {
                      status = 'Nothing heard. Try again.';
                    }
                  }
                });
              },
              listenFor: const Duration(seconds: 10),
              pauseFor: const Duration(seconds: 3),
              listenOptions: SpeechListenOptions(
                partialResults: true,
                cancelOnError: true,
              ),
            );
          }

          Future<void> stopListening() async {
            await stt.stop();
            setSheet(() => listening = false);
          }

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.xl2),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle
                  Container(
                    width: 40, height: 4,
                    margin: const EdgeInsets.only(bottom: AppSpacing.xl),
                    decoration: BoxDecoration(
                      color: context.border,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                  ),

                  Text('Setup Voice Login',
                      style: AppTextStyles.h2
                          .copyWith(color: context.textPrimary)),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Speak a unique passphrase — e.g. "Open Pulse dashboard".\n'
                    'You will use this phrase every time you sign in with voice.',
                    style: AppTextStyles.body
                        .copyWith(color: context.textMuted),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xl2),

                  // Mic button
                  GestureDetector(
                    onTap: listening ? stopListening : startListening,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 88, height: 88,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: listening
                            ? AppColors.error.withOpacity(0.15)
                            : context.primary.withOpacity(0.12),
                        border: Border.all(
                          color: listening
                              ? AppColors.error
                              : context.primary,
                          width: 2,
                        ),
                        boxShadow: listening
                            ? [BoxShadow(
                                color: AppColors.error.withOpacity(0.3),
                                blurRadius: 20, spreadRadius: 4)]
                            : context.glowShadow,
                      ),
                      child: Icon(
                        listening ? Icons.stop : Icons.mic,
                        size: 38,
                        color: listening ? AppColors.error : context.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Status text
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      status,
                      key: ValueKey(status),
                      style: AppTextStyles.body.copyWith(
                        color: done
                            ? AppColors.success
                            : listening
                                ? AppColors.error
                                : context.textSecondary,
                        fontWeight: done ? FontWeight.w600 : FontWeight.normal,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl2),

                  // Save / Cancel
                  Row(children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.md + 2),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.md)),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: GradientButton(
                        label: 'Save Passphrase',
                        icon: Icons.check,
                        onPressed: done && spoken.trim().isNotEmpty
                            ? () async {
                                final err = await auth.setupVoice(spoken);
                                Navigator.pop(ctx);
                                if (mounted) {
                                  if (err == null) {
                                    PulseSnackBar.show(context,
                                        'Voice login enabled!',
                                        isSuccess: true);
                                    setState(() {});
                                  } else {
                                    PulseSnackBar.show(context, err,
                                        isError: true);
                                  }
                                }
                              }
                            : null,
                        height: 48,
                      ),
                    ),
                  ]),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Dialogs ───────────────────────────────────────────────────────────────
  Future<bool?> _showConfirmDialog({
    required String title,
    required String body,
    required String confirmLabel,
    bool destructive = false,
  }) =>
      showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.xl)),
          title: Text(title,
              style: AppTextStyles.h2
                  .copyWith(color: context.textPrimary)),
          content: Text(body,
              style: AppTextStyles.body
                  .copyWith(color: context.textSecondary)),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    destructive ? AppColors.error : context.primary,
                foregroundColor: Colors.white,
              ),
              child: Text(confirmLabel),
            ),
          ],
        ),
      );

  void _showInfoDialog({
    required IconData icon,
    required String title,
    required String body,
  }) =>
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.xl)),
          title: Row(children: [
            Icon(icon, color: context.primary),
            const SizedBox(width: AppSpacing.sm),
            Text(title,
                style:
                    AppTextStyles.h2.copyWith(color: context.textPrimary)),
          ]),
          content: Text(body,
              style: AppTextStyles.body
                  .copyWith(color: context.textSecondary)),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                  backgroundColor: context.primary,
                  foregroundColor: Colors.white),
              child: const Text('Got it'),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final auth  = context.watch<AuthProvider>();
    final theme = context.watch<ThemeProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Settings',
              style: AppTextStyles.display
                  .copyWith(color: context.textPrimary)),
          const SizedBox(height: AppSpacing.xs),
          Text('Manage your account and preferences',
              style: AppTextStyles.body.copyWith(color: context.textMuted)),
          const SizedBox(height: AppSpacing.xl2),

          // ── Account ─────────────────────────────────────────────────
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionTitle(
                    icon: Icons.person_outline, label: 'Account'),
                const SizedBox(height: AppSpacing.md),

                // Email row
                Row(children: [
                  Icon(Icons.email_outlined,
                      size: 16, color: context.textMuted),
                  const SizedBox(width: AppSpacing.sm),
                  Text('Email  ',
                      style: AppTextStyles.bodySm
                          .copyWith(color: context.textMuted)),
                  Expanded(
                    child: Text(
                      auth.user?.email ?? '',
                      style: AppTextStyles.body
                          .copyWith(color: context.textPrimary,
                              fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ]),
                const SizedBox(height: AppSpacing.lg),
                Divider(color: context.border),
                const SizedBox(height: AppSpacing.lg),

                // ── Biometric button ─────────────────────────────────
                _SecurityButton(
                  icon: Icons.fingerprint,
                  label: auth.biometricEnabled
                      ? 'Biometrics Enabled'
                      : 'Setup Biometrics',
                  subtitle: auth.biometricEnabled
                      ? 'Tap to disable fingerprint / Face ID login'
                      : auth.biometricAvailable
                          ? 'Use fingerprint or Face ID to sign in'
                          : 'Not available on this device/browser',
                  enabled: auth.biometricEnabled,
                  available: auth.biometricAvailable || auth.biometricEnabled,
                  onTap: _handleBiometricSetup,
                ),
                const SizedBox(height: AppSpacing.md),

                // ── Voice button ─────────────────────────────────────
                _SecurityButton(
                  icon: Icons.mic_outlined,
                  label: auth.voiceEnabled
                      ? 'Voice Login Enabled'
                      : 'Setup Voice Login',
                  subtitle: auth.voiceEnabled
                      ? 'Tap to remove your voice passphrase'
                      : 'Speak a passphrase to sign in hands-free',
                  enabled: auth.voiceEnabled,
                  available: true,
                  onTap: _handleVoiceSetup,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── Appearance ───────────────────────────────────────────────
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionTitle(
                    icon: Icons.palette_outlined, label: 'Appearance'),
                const SizedBox(height: AppSpacing.md),
                _SwitchRow(
                  label: 'Dark Mode',
                  subtitle: 'Switch between light and dark theme',
                  icon: theme.isDark
                      ? Icons.light_mode_outlined
                      : Icons.dark_mode_outlined,
                  value: theme.isDark,
                  onChanged: (_) => theme.toggleTheme(),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── Preferences ──────────────────────────────────────────────
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionTitle(icon: Icons.tune_outlined, label: 'Preferences'),
                const SizedBox(height: AppSpacing.md),
                _SwitchRow(
                  label: 'Voice Assistant',
                  subtitle: 'Enable voice commands and responses',
                  icon: Icons.mic_outlined,
                  value: _prefs['voice_assistant_enabled'] as bool,
                  onChanged: (v) =>
                      setState(() => _prefs['voice_assistant_enabled'] = v),
                ),
                Divider(color: context.border, height: AppSpacing.xl2),
                _SwitchRow(
                  label: 'Camera Detection',
                  subtitle: 'Enable live camera object detection',
                  icon: Icons.camera_alt_outlined,
                  value: _prefs['camera_detection_enabled'] as bool,
                  onChanged: (v) =>
                      setState(() => _prefs['camera_detection_enabled'] = v),
                ),
                Divider(color: context.border, height: AppSpacing.xl2),
                _SwitchRow(
                  label: 'Notification Sounds',
                  subtitle: 'Play sound for alerts',
                  icon: Icons.volume_up_outlined,
                  value: _prefs['notification_sound_enabled'] as bool,
                  onChanged: (v) => setState(
                      () => _prefs['notification_sound_enabled'] = v),
                ),
                Divider(color: context.border, height: AppSpacing.xl2),

                // Alert sensitivity
                Row(children: [
                  Icon(Icons.tune, size: 18, color: context.textMuted),
                  const SizedBox(width: AppSpacing.sm),
                  Text('Alert Sensitivity',
                      style: AppTextStyles.body.copyWith(
                          color: context.textPrimary,
                          fontWeight: FontWeight.w500)),
                ]),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: ['low', 'medium', 'high'].map((s) {
                    final selected = _prefs['alert_sensitivity'] == s;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(
                            () => _prefs['alert_sensitivity'] = s),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.sm + 2),
                          decoration: BoxDecoration(
                            color: selected
                                ? context.primary
                                : context.surfaceAlt,
                            borderRadius:
                                BorderRadius.circular(AppRadius.md),
                            border: Border.all(
                              color: selected
                                  ? context.primary
                                  : context.border,
                            ),
                          ),
                          child: Text(
                            s[0].toUpperCase() + s.substring(1),
                            textAlign: TextAlign.center,
                            style: AppTextStyles.label.copyWith(
                              color: selected
                                  ? Colors.white
                                  : context.textSecondary,
                              fontWeight: FontWeight.w600,
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
          const SizedBox(height: AppSpacing.lg),

          GradientButton(
            label: 'Save Settings',
            icon: Icons.save_outlined,
            onPressed: _savePreferences,
            loading: _saving,
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── Security ─────────────────────────────────────────────────
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionTitle(
                    icon: Icons.security_outlined, label: 'Security'),
                const SizedBox(height: AppSpacing.md),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.lock_reset, color: context.primary),
                  title: Text('Change Password',
                      style: AppTextStyles.body.copyWith(
                          color: context.primary,
                          fontWeight: FontWeight.w500)),
                  onTap: () {},
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md)),
                ),
                Divider(color: context.border, height: AppSpacing.xl),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.logout, color: AppColors.error),
                  title: Text('Sign Out',
                      style: AppTextStyles.body.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.w500)),
                  onTap: () async {
                    await auth.signOut();
                    if (context.mounted) context.go('/login');
                  },
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md)),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl3),
        ],
      ),
    );
  }
}

// ── Reusable sub-widgets ──────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SectionTitle({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 20, color: context.primary),
      const SizedBox(width: AppSpacing.sm),
      Text(label,
          style: AppTextStyles.h3.copyWith(color: context.textPrimary)),
    ]);
  }
}

class _SecurityButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool enabled;
  final bool available;
  final VoidCallback onTap;

  const _SecurityButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.enabled,
    required this.available,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = enabled
        ? AppColors.success
        : available
            ? context.primary
            : context.textMuted;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: AppTextStyles.h4.copyWith(color: color)),
                Text(subtitle,
                    style: AppTextStyles.caption
                        .copyWith(color: context.textMuted)),
              ],
            ),
          ),
          Icon(
            enabled ? Icons.check_circle : Icons.arrow_forward_ios,
            color: color, size: enabled ? 22 : 16,
          ),
        ]),
      ),
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
    return Row(children: [
      Icon(icon, size: 20, color: context.textMuted),
      const SizedBox(width: AppSpacing.md),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: AppTextStyles.body.copyWith(
                  color: context.textPrimary,
                  fontWeight: FontWeight.w500)),
          Text(subtitle,
              style: AppTextStyles.caption.copyWith(color: context.textMuted)),
        ]),
      ),
      Switch(
        value: value,
        onChanged: onChanged,
        activeColor: context.primary,
      ),
    ]);
  }
}