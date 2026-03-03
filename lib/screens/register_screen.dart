import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../widgets/common_widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _showPassword = false;
  bool _showConfirm = false;
  bool _loading = false;
  String _error = '';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email is required.';
    final regex = RegExp(r'^[a-zA-Z][a-zA-Z0-9._%+\-]*@[a-zA-Z0-9.\-]+\.com$');
    if (!regex.hasMatch(v.trim())) return 'Enter a valid email address.';
    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Password is required.';
    if (v.length < 6) return 'Password must be at least 6 characters.';
    return null;
  }

  String? _validateConfirm(String? v) {
    if (v != _passwordController.text) return 'Passwords do not match.';
    return null;
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = '';
    });

    final auth = context.read<AuthProvider>();
    final err = await auth.signUp(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _loading = false);

   if (err == 'CHECK_EMAIL') {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Check your email'),
      content: Text(
        'A confirmation link was sent to ${_emailController.text.trim()}. '
        'Click it to verify, then sign in.',
      ),
      actions: [
        ElevatedButton(
          onPressed: () { Navigator.pop(ctx); context.go('/login'); },
          child: const Text('Go to Sign In'),
        ),
      ],
    ),
  );
} else if (err != null) {
  setState(() => _error = err);
} else {
  context.go('/dashboard');
}
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: PulseBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),
                const Center(child: PulseLogo(size: 48)),
                const SizedBox(height: 32),

                Text(
                  'Create account',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Start tracking your belongings',
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                GlassCard(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
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
                              onPressed: () => setState(
                                  () => _showPassword = !_showPassword),
                            ),
                          ),
                          validator: _validatePassword,
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _confirmController,
                          obscureText: !_showConfirm,
                          decoration: InputDecoration(
                            labelText: 'Confirm Password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(_showConfirm
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined),
                              onPressed: () => setState(
                                  () => _showConfirm = !_showConfirm),
                            ),
                          ),
                          validator: _validateConfirm,
                        ),
                        const SizedBox(height: 8),

                        // Password requirements
                        _buildRequirements(),
                        const SizedBox(height: 16),

                        if (_error.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _error,
                              style: const TextStyle(
                                  color: Colors.red, fontSize: 14),
                            ),
                          ),
                        if (_error.isNotEmpty) const SizedBox(height: 16),

                        GradientButton(
                          label: 'Create Account',
                          onPressed: _handleRegister,
                          loading: _loading,
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
                      'Already have an account? ',
                      style: TextStyle(
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.go('/login'),
                      child: const Text('Sign In'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRequirements() {
    final password = _passwordController.text;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RequirementRow(
          met: password.length >= 6,
          label: 'At least 6 characters',
        ),
        _RequirementRow(
          met: password.contains(RegExp(r'[A-Z]')),
          label: 'At least one uppercase letter',
        ),
        _RequirementRow(
          met: password.contains(RegExp(r'[0-9]')),
          label: 'At least one number',
        ),
      ],
    );
  }
}

class _RequirementRow extends StatelessWidget {
  final bool met;
  final String label;

  const _RequirementRow({required this.met, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle : Icons.circle_outlined,
            size: 16,
            color: met ? const Color(0xFF22C55E) : const Color(0xFF94A3B8),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: met ? const Color(0xFF22C55E) : const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }
}
