import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../widgets/common_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _forgotEmailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _showPassword = false;
  bool _loading = false;
  bool _showForgot = false;
  bool _forgotLoading = false;
  bool _forgotSent = false;
  String _error = '';

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
    if (RegExp(r'^\d+$').hasMatch(local)) {
      return 'Email cannot be only numbers before @.';
    }
    if (!v.toLowerCase().endsWith('.com')) {
      return 'Only .com email addresses are allowed.';
    }
    final regex = RegExp(r'^[a-zA-Z][a-zA-Z0-9._%+\-]*@[a-zA-Z0-9.\-]+\.com$');
    if (!regex.hasMatch(v.trim())) return 'Enter a valid email (e.g. you@example.com)';
    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Password is required.';
    if (v.length < 6) return 'Password must be at least 6 characters.';
    return null;
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = '';
    });

    final auth = context.read<AuthProvider>();
    final err = await auth.signIn(
      _emailController.text.trim(),
      _passwordController.text,
    );

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

    final auth = context.read<AuthProvider>();
    final err = await auth.resetPassword(email);

    if (!mounted) return;
    setState(() {
      _forgotLoading = false;
      if (err == null) {
        _forgotSent = true;
      } else {
        _error = err;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: PulseBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: _showForgot ? _buildForgotPassword(isDark) : _buildLoginForm(isDark),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 40),
        const Center(child: PulseLogo(size: 48)),
        const SizedBox(height: 40),

        Text(
          'Welcome back',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Sign in to your account',
          style: TextStyle(
            fontSize: 16,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),

        GlassCard(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: _validateEmail,
                ),
                const SizedBox(height: 16),

                // Password
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
                const SizedBox(height: 8),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => setState(() {
                      _showForgot = true;
                      _forgotSent = false;
                    }),
                    child: const Text('Forgot password?'),
                  ),
                ),

                if (_error.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _error,
                      style: const TextStyle(color: Colors.red, fontSize: 14),
                    ),
                  ),
                if (_error.isNotEmpty) const SizedBox(height: 16),

                GradientButton(
                  label: 'Sign In',
                  onPressed: _handleLogin,
                  loading: _loading,
                ),

                const SizedBox(height: 16),
                const Row(children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('or',
                        style: TextStyle(color: Color(0xFF94A3B8))),
                  ),
                  Expanded(child: Divider()),
                ]),
                const SizedBox(height: 16),

                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.fingerprint, size: 22),
                  label: const Text('Sign in with Biometrics'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                ),

                const SizedBox(height: 12),

                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.mic_outlined, size: 22),
                  label: const Text('Sign in with Voice'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Don't have an account? ",
              style: TextStyle(
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
            TextButton(
              onPressed: () => context.go('/register'),
              child: const Text('Sign Up'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildForgotPassword(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 40),
        Row(
          children: [
            IconButton(
              onPressed: () => setState(() {
                _showForgot = false;
                _forgotSent = false;
              }),
              icon: const Icon(Icons.arrow_back),
            ),
            const SizedBox(width: 8),
            Text(
              'Reset Password',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),

        GlassCard(
          padding: const EdgeInsets.all(24),
          child: _forgotSent
              ? Column(
                  children: [
                    const Icon(Icons.check_circle_outline,
                        color: Color(0xFF22C55E), size: 56),
                    const SizedBox(height: 16),
                    const Text(
                      'Reset link sent!',
                      style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Check your email at ${_forgotEmailController.text} for instructions.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 24),
                    GradientButton(
                      label: 'Back to Login',
                      onPressed: () => setState(() {
                        _showForgot = false;
                        _forgotSent = false;
                      }),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Enter your email address and we\'ll send you a link to reset your password.',
                      style: TextStyle(color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _forgotEmailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: 20),
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
