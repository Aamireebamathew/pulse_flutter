// toast_service.dart
// Global toast notification system — equivalent of ToastNotifications + useNotification
//
// Setup: wrap your app root with ToastOverlay:
//   runApp(ToastOverlay(child: MyApp()));
//
// Show a toast anywhere:
//   ToastService.show('Saved!');
//   ToastService.show('Something went wrong', type: ToastType.error);

import 'dart:async';
import 'package:flutter/material.dart';

enum ToastType { info, success, warning, error }

class _ToastItem {
  final String id;
  final String message;
  final ToastType type;
  _ToastItem({required this.id, required this.message, required this.type});
}

// ─── Global key so ToastService can push toasts from anywhere ────────────────
final _overlayKey = GlobalKey<_ToastOverlayState>();

class ToastService {
  static void show(
    String message, {
    ToastType type = ToastType.info,
    Duration duration = const Duration(milliseconds: 4000),
  }) {
    _overlayKey.currentState?.addToast(message, type, duration);
  }
}

// ─── Wrap your MaterialApp or Scaffold with this ─────────────────────────────
class ToastOverlay extends StatefulWidget {
  final Widget child;
  const ToastOverlay({super.key, required this.child});

  @override
  State<ToastOverlay> createState() => _ToastOverlayState();
}

class _ToastOverlayState extends State<ToastOverlay> {
  final List<_ToastItem> _toasts = [];

  void addToast(String message, ToastType type, Duration duration) {
    final item = _ToastItem(
      id:      DateTime.now().microsecondsSinceEpoch.toString(),
      message: message,
      type:    type,
    );
    setState(() {
      // Max 3 toasts; newest at top
      _toasts.insert(0, item);
      if (_toasts.length > 3) _toasts.removeLast();
    });
    Future.delayed(duration, () => _dismiss(item.id));
  }

  void _dismiss(String id) {
    if (mounted) setState(() => _toasts.removeWhere((t) => t.id == id));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      key: _overlayKey,
      children: [
        widget.child,
        Positioned(
          top: 48, right: 16,
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _toasts
                  .map((t) => _ToastCard(
                        key:       ValueKey(t.id),
                        item:      t,
                        onDismiss: () => _dismiss(t.id),
                      ))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Individual toast card ────────────────────────────────────────────────────
class _ToastCard extends StatefulWidget {
  final _ToastItem  item;
  final VoidCallback onDismiss;

  const _ToastCard({super.key, required this.item, required this.onDismiss});

  @override
  State<_ToastCard> createState() => _ToastCardState();
}

class _ToastCardState extends State<_ToastCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset>   _slide;
  late final Animation<double>   _fade;
  late final Animation<double>   _progress;

  static const _kDuration = Duration(milliseconds: 4000);
  static const _kEnter    = Duration(milliseconds: 300);

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: _kDuration);

    _slide = Tween<Offset>(
      begin: const Offset(1.5, 0),
      end:   Offset.zero,
    ).animate(CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0, 0.15, curve: Curves.easeOut),
    ));

    _fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0, 0.15, curve: Curves.easeOut),
      ),
    );

    // Progress bar goes from 1 → 0 over the full duration
    _progress = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.linear),
    );

    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color get _accentColor => switch (widget.item.type) {
    ToastType.info    => const Color(0xFF60A5FA), // blue-400
    ToastType.success => const Color(0xFF4ADE80), // green-400
    ToastType.warning => const Color(0xFFFBBF24), // yellow-400
    ToastType.error   => const Color(0xFFEF4444), // red-500
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _fade,
          child: Container(
            width: 288, // ~w-72
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A), // slate-900
              borderRadius: BorderRadius.circular(10),
              border: Border(
                left: BorderSide(color: _accentColor, width: 4),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          widget.item.message,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: widget.onDismiss,
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(Icons.close,
                              size: 14,
                              color: Color(0x66FFFFFF)),
                        ),
                      ),
                    ],
                  ),
                ),
                // Progress bar
                AnimatedBuilder(
                  animation: _progress,
                  builder: (_, __) => Container(
                    height: 2,
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: _progress.value,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}