import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../providers/auth_provider.dart';
import '../widgets/common_widgets.dart';
import '../utils/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController        = TextEditingController();
  final _passwordController     = TextEditingController();
  final _forgotEmailController  = TextEditingController();
  final _formKey                = GlobalKey<FormState>();

  bool _showPassword   = false;
  bool _loading        = false;
  bool _showForgot     = false;
  bool _forgotLoading  = false;
  bool _forgotSent     = false;
  String _error        = '';

  // ── Voice sign-in state ───────────────────────────────────────────────────
  final SpeechToText _stt = SpeechToText();
  bool _voiceListening = false;
  bool _voiceSttReady  = false;

  @override
  void initState() {
    super.initState();
    _initStt();
  }

  Future<void> _initStt() async {
    try {
      final ok = await _stt.initialize(
        onError: (_) => setState(() => _voiceListening = false),
        onStatus: (s) {
          if (s == 'done' || s == 'notListening') {
            setState(() => _voiceListening = false);
          }
        },
      );
      if (mounted) setState(() => _voiceSttReady = ok);
    } catch (_) {}
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _forgotEmailController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email is required.';
    final local = v.trim().split('@').first;
    if (RegExp(r'^\d+$').hasMatch(local))
      return 'Email cannot be only numbers before @.';
    if (!v.toLowerCase().endsWith('.com'))
      return 'Only .com email addresses are allowed.';
    final regex =
        RegExp(r'^[a-zA-Z][a-zA-Z0-9._%+\-]*@[a-zA-Z0-9.\-]+\.com$');
    if (!regex.hasMatch(v.trim()))
      return 'Enter a valid email (e.g. you@example.com)';
    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Password is required.';
    if (v.length < 6) return 'Password must be at least 6 characters.';
    return null;
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = ''; });
    final err = await context.read<AuthProvider>()
        .signIn(_emailController.text.trim(), _passwordController.text);
    if (!mounted) return;
    setState(() => _loading = false);
    if (err != null) {
      setState(() => _error = err);
    } else {
      context.go('/dashboard');
    }
  }

  Future<void> _handleForgotPassword() async {
    final email = _forgotEmailController.text.trim();
    if (email.isEmpty) return;
    setState(() => _forgotLoading = true);
    final err = await context.read<AuthProvider>().resetPassword(email);
    if (!mounted) return;
    setState(() {
      _forgotLoading = false;
      if (err == null) { _forgotSent = true; } else { _error = err; }
    });
  }

  // ── Biometric sign-in ─────────────────────────────────────────────────────
  Future<void> _handleBiometricLogin() async {
    final auth = context.read<AuthProvider>();
    if (!auth.biometricEnabled) {
      _setError('Biometrics not set up. Enable it in Settings → Account.');
      return;
    }
    setState(() { _loading = true; _error = ''; });
    final err = await auth.signInWithBiometric();
    if (!mounted) return;
    setState(() => _loading = false);
    if (err == null) {
      context.go('/dashboard');
    } else {
      _setError(err);
    }
  }

  // ── Voice sign-in ─────────────────────────────────────────────────────────
  Future<void> _handleVoiceLogin() async {
    final auth = context.read<AuthProvider>();
    if (!auth.voiceEnabled) {
      _setError('Voice login not set up. Enable it in Settings → Account.');
      return;
    }
    if (!_voiceSttReady) {
      _setError('Microphone not available. Check app permissions.');
      return;
    }

    setState(() { _voiceListening = true; _error = ''; });

    await _stt.listen(
      onResult: (result) async {
        if (result.finalResult) {
          setState(() => _voiceListening = false);
          if (!mounted) return;
          final err = await auth.signInWithVoice(result.recognizedWords);
          if (!mounted) return;
          if (err == null) {
            context.go('/dashboard');
          } else {
            _setError(err);
          }
        }
      },
      listenFor: const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 3),
      listenOptions: SpeechListenOptions(partialResults: false),
    );
  }

  void _stopVoice() {
    _stt.stop();
    setState(() => _voiceListening = false);
  }

  void _setError(String msg) => setState(() => _error = msg);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PulseBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl2),
            child: _showForgot
                ? _buildForgotPassword()
                : _buildLoginForm(),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    final auth = context.watch<AuthProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.xl4),
        const Center(child: PulseLogo(size: 48)),
        const SizedBox(height: AppSpacing.xl3),

        Text('Welcome back',
            style: AppTextStyles.display
                .copyWith(color: context.textPrimary),
            textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.xs),
        Text('Sign in to your account',
            style: AppTextStyles.bodyLg
                .copyWith(color: context.textMuted),
            textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.xl3),

        GlassCard(
          padding: const EdgeInsets.all(AppSpacing.xl2),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Email ──────────────────────────────────────────────
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: _validateEmail,
                ),
                const SizedBox(height: AppSpacing.lg),

                // ── Password ───────────────────────────────────────────
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_showPassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_showPassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined),
                      onPressed: () =>
                          setState(() => _showPassword = !_showPassword),
                    ),
                  ),
                  validator: _validatePassword,
                ),
                const SizedBox(height: AppSpacing.xs),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => setState(() {
                      _showForgot = true;
                      _forgotSent = false;
                      _error      = '';
                    }),
                    child: const Text('Forgot password?'),
                  ),
                ),

                // ── Error ──────────────────────────────────────────────
                if (_error.isNotEmpty) ...[
                  InfoBanner(
                    title: 'Error',
                    body: _error,
                    icon: Icons.error_outline,
                    variant: BadgeVariant.error,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],

                GradientButton(
                  label: 'Sign In',
                  onPressed: _handleLogin,
                  loading: _loading,
                ),

                const SizedBox(height: AppSpacing.lg),
                LabeledDivider(label: 'or'),
                const SizedBox(height: AppSpacing.lg),

                // ── Biometric button ───────────────────────────────────
                _AltLoginButton(
                  icon: Icons.fingerprint,
                  label: auth.biometricEnabled
                      ? 'Sign in with Biometrics'
                      : 'Biometrics (setup in Settings)',
                  available: auth.biometricEnabled,
                  onTap: _handleBiometricLogin,
                ),
                const SizedBox(height: AppSpacing.md),

                // ── Voice button ───────────────────────────────────────
                _AltLoginButton(
                  icon: _voiceListening ? Icons.stop : Icons.mic_outlined,
                  label: _voiceListening
                      ? 'Listening… tap to cancel'
                      : auth.voiceEnabled
                          ? 'Sign in with Voice'
                          : 'Voice Login (setup in Settings)',
                  available: auth.voiceEnabled,
                  listening: _voiceListening,
                  onTap: _voiceListening ? _stopVoice : _handleVoiceLogin,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.xl2),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text("Don't have an account? ",
              style: AppTextStyles.body
                  .copyWith(color: context.textMuted)),
          TextButton(
            onPressed: () => context.go('/register'),
            child: const Text('Sign Up'),
          ),
        ]),
      ],
    );
  }

  Widget _buildForgotPassword() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.xl3),
        Row(children: [
          IconButton(
            onPressed: () => setState(() {
              _showForgot = false;
              _forgotSent = false;
              _error      = '';
            }),
            icon: Icon(Icons.arrow_back, color: context.textPrimary),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text('Reset Password',
              style: AppTextStyles.h1
                  .copyWith(color: context.textPrimary)),
        ]),
        const SizedBox(height: AppSpacing.xl2),

        GlassCard(
          padding: const EdgeInsets.all(AppSpacing.xl2),
          child: _forgotSent
              ? Column(children: [
                  const Icon(Icons.check_circle_outline,
                      color: AppColors.success, size: 56),
                  const SizedBox(height: AppSpacing.lg),
                  Text('Reset link sent!',
                      style: AppTextStyles.h2
                          .copyWith(color: context.textPrimary)),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Check ${_forgotEmailController.text} for instructions.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body
                        .copyWith(color: context.textMuted),
                  ),
                  const SizedBox(height: AppSpacing.xl2),
                  GradientButton(
                    label: 'Back to Login',
                    onPressed: () => setState(() {
                      _showForgot = false;
                      _forgotSent = false;
                    }),
                  ),
                ])
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Enter your email and we\'ll send a reset link.',
                      style: AppTextStyles.body
                          .copyWith(color: context.textMuted),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    if (_error.isNotEmpty) ...[
                      InfoBanner(
                        title: 'Error',
                        body: _error,
                        icon: Icons.error_outline,
                        variant: BadgeVariant.error,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                    TextFormField(
                      controller: _forgotEmailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    GradientButton(
                      label: 'Send Reset Link',
                      onPressed: _handleForgotPassword,
                      loading: _forgotLoading,
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

// ─── Alt login button (biometric / voice) ─────────────────────────────────────
class _AltLoginButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool available;
  final bool listening;
  final VoidCallback onTap;

  const _AltLoginButton({
    required this.icon,
    required this.label,
    required this.available,
    required this.onTap,
    this.listening = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = listening
        ? AppColors.error
        : available
            ? context.primary
            : context.textMuted;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md + 2, horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: color.withOpacity(listening ? 0.8 : 0.3)),
          boxShadow: listening
              ? [BoxShadow(
                  color: AppColors.error.withOpacity(0.2),
                  blurRadius: 12)]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(width: AppSpacing.sm),
            Text(label,
                style: AppTextStyles.body.copyWith(
                    color: color, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}