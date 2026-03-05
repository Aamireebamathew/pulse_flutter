// onboarding_screen.dart
// Flutter equivalent of Onboarding.tsx
// Usage: show this before the dashboard on first launch.
// Store completion in SharedPreferences:
//   final prefs = await SharedPreferences.getInstance();
//   prefs.setBool('onboarding_done', true);

import 'package:flutter/material.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  int _current = 0;
  late AnimationController _animCtrl;
  late Animation<Offset>   _slideAnim;
  late Animation<double>   _fadeAnim;

  static const _slides = [
    _Slide(
      emoji:       '🎤',
      icon:        Icons.mic,
      iconGradient:[Color(0xFF3B82F6), Color(0xFF2563EB)],
      bgColors:   [Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
      title:       'Voice-Activated Assistant',
      description: 'Simply speak to find your belongings. '
                   'Ask "Where are my keys?" and get instant answers.',
    ),
    _Slide(
      emoji:       '📍',
      icon:        Icons.location_on,
      iconGradient:[Color(0xFF9333EA), Color(0xFF7C3AED)],
      bgColors:   [Color(0xFFF5F3FF), Color(0xFFEDE9FE)],
      title:       'Track Your Items',
      description: 'Keep tabs on your keys, wallet, phone, and important '
                   'items with real-time location tracking.',
    ),
    _Slide(
      emoji:       '🔔',
      icon:        Icons.notifications,
      iconGradient:[Color(0xFFF97316), Color(0xFFEA580C)],
      bgColors:   [Color(0xFFFFF7ED), Color(0xFFFED7AA)],
      title:       'Smart Alerts',
      description: 'Get notified when items are left behind or when '
                   'unusual activity is detected at home.',
    ),
    _Slide(
      emoji:       '🛡️',
      icon:        Icons.shield,
      iconGradient:[Color(0xFF22C55E), Color(0xFF16A34A)],
      bgColors:   [Color(0xFFF0FDF4), Color(0xFFBBF7D0)],
      title:       'Privacy & Safety First',
      description: 'Your data is secure and private. Camera alerts and '
                   'location data stay on your device.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _buildAnims();
    _animCtrl.forward();
  }

  void _buildAnims() {
    _slideAnim = Tween<Offset>(
      begin: const Offset(0.4, 0), end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _fadeAnim = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
  }

  void _goTo(int index) {
    setState(() => _current = index);
    _animCtrl.reset();
    _animCtrl.forward();
  }

  void _next() {
    if (_current < _slides.length - 1) {
      _goTo(_current + 1);
    } else {
      widget.onComplete();
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_current];
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(children: [
          // ── Skip ────────────────────────────────────────────────────
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: widget.onComplete,
              child: const Text('Skip',
                  style: TextStyle(color: Color(0xFF6B7280))),
            ),
          ),

          // ── Slide content ────────────────────────────────────────────
          Expanded(
            child: Center(
              child: SlideTransition(
                position: _slideAnim,
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Illustration box
                        _PulsingBox(
                          bgColors: slide.bgColors,
                          child: Text(slide.emoji,
                              style: const TextStyle(fontSize: 80)),
                        ),
                        const SizedBox(height: 32),

                        // Icon badge
                        Container(
                          width: 64, height: 64,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                                colors: slide.iconGradient,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: slide.iconGradient.last
                                    .withOpacity(0.4),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(slide.icon,
                              color: Colors.white, size: 30),
                        ),
                        const SizedBox(height: 24),

                        Text(slide.title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF111827),
                              height: 1.2,
                            )),
                        const SizedBox(height: 16),
                        Text(slide.description,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFF6B7280),
                              height: 1.6,
                            )),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Navigation ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            child: Column(children: [
              // Dot indicators
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_slides.length, (i) {
                  final active = i == _current;
                  return GestureDetector(
                    onTap: () => _goTo(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 8,
                      width: active ? 32 : 8,
                      decoration: BoxDecoration(
                        gradient: active
                            ? const LinearGradient(colors: [
                                Color(0xFF3B82F6),
                                Color(0xFF9333EA),
                              ])
                            : null,
                        color: active ? null : const Color(0xFFD1D5DB),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),

              // Next / Get Started button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF2563EB),
                        Color(0xFF9333EA),
                        Color(0xFF16A34A),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3B82F6).withOpacity(0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _next,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const SizedBox.shrink(),
                    label: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _current == _slides.length - 1
                              ? 'Get Started'
                              : 'Next',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.chevron_right,
                            color: Colors.white, size: 22),
                      ],
                    ),
                  ),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ─── Data class ───────────────────────────────────────────────────────────────
class _Slide {
  final String       emoji;
  final IconData     icon;
  final List<Color>  iconGradient;
  final List<Color>  bgColors;
  final String       title;
  final String       description;
  const _Slide({
    required this.emoji,
    required this.icon,
    required this.iconGradient,
    required this.bgColors,
    required this.title,
    required this.description,
  });
}

// ─── Pulsing illustration box ─────────────────────────────────────────────────
class _PulsingBox extends StatefulWidget {
  final List<Color> bgColors;
  final Widget      child;
  const _PulsingBox({required this.bgColors, required this.child});

  @override
  State<_PulsingBox> createState() => _PulsingBoxState();
}

class _PulsingBoxState extends State<_PulsingBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>   _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 1.0, end: 1.05)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Container(
        width: 240, height: 240,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: widget.bgColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(56),
          boxShadow: [
            BoxShadow(
              color: widget.bgColors.last.withOpacity(0.4),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(child: widget.child),
      ),
    );
  }
}