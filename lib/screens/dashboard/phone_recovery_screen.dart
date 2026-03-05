import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../widgets/common_widgets.dart';
import '../../utils/app_theme.dart';

class PhoneRecoveryScreen extends StatefulWidget {
  const PhoneRecoveryScreen({super.key});

  @override
  State<PhoneRecoveryScreen> createState() => _PhoneRecoveryScreenState();
}

class _PhoneRecoveryScreenState extends State<PhoneRecoveryScreen> {
  Position? _position;
  String _locationError = '';
  bool _tracking = false;
  bool _locationLoading = false;
  DateTime _lastSeen = DateTime.now();
  double _bluetoothSignal = 0;
  bool _isPlaying = false;

  StreamSubscription<Position>? _positionSub;
  Timer? _btTimer;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _btTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchLocation() async {
    setState(() { _locationLoading = true; _locationError = ''; });

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() { _locationError = 'Location services are disabled.'; _locationLoading = false; });
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() { _locationError = 'Location permission denied.'; _locationLoading = false; });
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      setState(() { _locationError = 'Location permission permanently denied.'; _locationLoading = false; });
      return;
    }

    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      setState(() { _position = pos; _lastSeen = DateTime.now(); _locationLoading = false; });
      _animateMap(pos);
    } catch (e) {
      setState(() { _locationError = 'Unable to retrieve location.'; _locationLoading = false; });
    }
  }

  void _animateMap(Position pos) {
    try {
      _mapController.move(LatLng(pos.latitude, pos.longitude), 15.0);
    } catch (_) {}
  }

  void _toggleTracking() {
    if (_tracking) {
      _positionSub?.cancel();
      _btTimer?.cancel();
      setState(() { _tracking = false; _bluetoothSignal = 0; });
    } else {
      setState(() => _tracking = true);
      _positionSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      ).listen((pos) {
        setState(() { _position = pos; _lastSeen = DateTime.now(); });
        _animateMap(pos);
      });
      _btTimer = Timer.periodic(const Duration(seconds: 2), (_) {
        setState(() => _bluetoothSignal = (Random().nextDouble() * 60) + 40);
      });
    }
  }

  void _playSound() {
    setState(() => _isPlaying = !_isPlaying);
    if (_isPlaying) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _isPlaying = false);
      });
    }
  }

  void _openMaps() {
    if (_position == null) return;
    launchUrl(Uri.parse(
        'https://www.google.com/maps?q=${_position!.latitude},${_position!.longitude}'));
  }

  String _signalStrength() {
    if (_bluetoothSignal <= 0) return 'No Signal';
    if (_bluetoothSignal < 50) return 'Weak';
    if (_bluetoothSignal < 75) return 'Good';
    return 'Excellent';
  }

  Color _signalColor() {
    if (_bluetoothSignal <= 0) return AppColors.lightTextMute;
    if (_bluetoothSignal < 50) return AppColors.error;
    if (_bluetoothSignal < 75) return AppColors.warning;
    return AppColors.success;
  }

  String _timeSinceSeen() {
    final diff = DateTime.now().difference(_lastSeen);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }

  @override
  Widget build(BuildContext context) {
    final hasLocation = _position != null;
    final center = hasLocation
        ? LatLng(_position!.latitude, _position!.longitude)
        : const LatLng(0, 0);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Phone Recovery',
              style: AppTextStyles.display.copyWith(color: context.textPrimary)),
          const SizedBox(height: AppSpacing.xs),
          Text('Locate and recover your device',
              style: AppTextStyles.body.copyWith(color: context.textMuted)),
          const SizedBox(height: AppSpacing.xl2),

          // ── MAP CARD ──────────────────────────────────────────────────
          GlassCard(
            padding: EdgeInsets.zero,
            child: Column(children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppRadius.lg)),
                child: SizedBox(
                  height: 220,
                  child: hasLocation
                      ? FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: center,
                            initialZoom: 15,
                            interactionOptions: const InteractionOptions(
                              flags: InteractiveFlag.pinchZoom |
                                  InteractiveFlag.drag,
                            ),
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.pulse.app',
                            ),
                            MarkerLayer(markers: [
                              Marker(
                                point: center,
                                width: 48, height: 48,
                                child: _PulsingMarker(tracking: _tracking),
                              ),
                            ]),
                            CircleLayer(circles: [
                              CircleMarker(
                                point: center,
                                radius: _position!.accuracy,
                                useRadiusInMeter: true,
                                color: context.primary.withOpacity(0.12),
                                borderColor: context.primary.withOpacity(0.4),
                                borderStrokeWidth: 1.5,
                              ),
                            ]),
                          ],
                        )
                      : Container(
                          color: AppColors.darkSurface,
                          child: Center(
                            child: _locationLoading
                                ? Column(mainAxisSize: MainAxisSize.min, children: [
                                    CircularProgressIndicator(color: context.primary),
                                    const SizedBox(height: AppSpacing.md),
                                    const Text('Getting location…',
                                        style: TextStyle(color: Colors.white54)),
                                  ])
                                : Column(mainAxisSize: MainAxisSize.min, children: [
                                    const Icon(Icons.location_off,
                                        color: Colors.white38, size: 40),
                                    const SizedBox(height: AppSpacing.sm),
                                    Text(
                                      _locationError.isNotEmpty
                                          ? _locationError
                                          : 'Location unavailable',
                                      style: const TextStyle(color: Colors.white54, fontSize: 13),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: AppSpacing.md),
                                    OutlinedButton.icon(
                                      onPressed: _fetchLocation,
                                      icon: const Icon(Icons.refresh, color: Colors.white70, size: 16),
                                      label: const Text('Retry',
                                          style: TextStyle(color: Colors.white70)),
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(color: Colors.white24),
                                        shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(AppRadius.sm)),
                                      ),
                                    ),
                                  ]),
                          ),
                        ),
                ),
              ),

              if (hasLocation)
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(
                          '${_position!.latitude.toStringAsFixed(5)}, '
                          '${_position!.longitude.toStringAsFixed(5)}',
                          style: AppTextStyles.h4.copyWith(color: context.textPrimary),
                        ),
                        Text('±${_position!.accuracy.toStringAsFixed(0)} m accuracy',
                            style: AppTextStyles.caption.copyWith(color: context.textMuted)),
                      ]),
                    ),
                    OutlinedButton.icon(
                      onPressed: _openMaps,
                      icon: const Icon(Icons.open_in_new, size: 15),
                      label: const Text('Maps'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: context.primary,
                        side: BorderSide(color: context.primary),
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.sm)),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    IconButton(
                      onPressed: _fetchLocation,
                      icon: _locationLoading
                          ? SizedBox(
                              width: 18, height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: context.primary),
                            )
                          : Icon(Icons.my_location, color: context.primary),
                      tooltip: 'Refresh location',
                    ),
                  ]),
                ),
            ]),
          ),

          const SizedBox(height: AppSpacing.lg),

          // ── LAST SEEN + TRACKING ────────────────────────────────────
          GlassCard(
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Last Seen',
                      style: AppTextStyles.bodySm.copyWith(color: context.textMuted)),
                  const SizedBox(height: AppSpacing.xs),
                  Text(_timeSinceSeen(),
                      style: AppTextStyles.h1.copyWith(color: context.textPrimary)),
                ]),
              ),
              const SizedBox(width: AppSpacing.md),
              GradientButton(           // ✅ fullWidth: false — inside Row
                label: _tracking ? 'Stop' : 'Track Live',
                icon: _tracking ? Icons.stop : Icons.radio_button_checked,
                onPressed: _toggleTracking,
                gradient: _tracking
                    ? [AppColors.error, const Color(0xFFDC2626)]
                    : null,
                height: 44,
                fullWidth: false,
              ),
            ]),
          ),

          const SizedBox(height: AppSpacing.lg),

          // ── BLUETOOTH SIGNAL ────────────────────────────────────────
          GlassCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(Icons.bluetooth, color: context.primary),
                const SizedBox(width: AppSpacing.sm),
                Text('Bluetooth Signal',
                    style: AppTextStyles.h3.copyWith(color: context.textPrimary)),
                const Spacer(),
                Text(_signalStrength(),
                    style: AppTextStyles.h4.copyWith(color: _signalColor())),
              ]),
              const SizedBox(height: AppSpacing.md),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.xs),
                child: LinearProgressIndicator(
                  value: _bluetoothSignal / 100,
                  minHeight: 8,
                  backgroundColor: context.border,
                  valueColor: AlwaysStoppedAnimation(_signalColor()),
                ),
              ),
              if (!_tracking) ...[
                const SizedBox(height: AppSpacing.sm),
                Text('Start live tracking to see signal',
                    style: AppTextStyles.bodySm.copyWith(color: context.textMuted)),
              ],
            ]),
          ),

          const SizedBox(height: AppSpacing.lg),

          // ── SOUND ALERT ─────────────────────────────────────────────
          GlassCard(
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Sound Alert',
                      style: AppTextStyles.h3.copyWith(color: context.textPrimary)),
                  const SizedBox(height: AppSpacing.xs),
                  Text('Play a sound to help find your phone',
                      style: AppTextStyles.bodySm.copyWith(color: context.textMuted)),
                ]),
              ),
              const SizedBox(width: AppSpacing.md),
              GradientButton(           // ✅ fullWidth: false — inside Row
                label: _isPlaying ? 'Playing...' : 'Play Sound',
                icon: _isPlaying ? Icons.volume_up : Icons.volume_up_outlined,
                onPressed: _playSound,
                gradient: _isPlaying
                    ? [AppColors.success, const Color(0xFF16A34A)]
                    : null,
                height: 44,
                fullWidth: false,
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

class _PulsingMarker extends StatefulWidget {
  final bool tracking;
  const _PulsingMarker({required this.tracking});
  @override
  State<_PulsingMarker> createState() => _PulsingMarkerState();
}

class _PulsingMarkerState extends State<_PulsingMarker>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _scale, _opacity;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(seconds: 1))
      ..repeat(reverse: true);
    _scale   = Tween(begin: 0.85, end: 1.15)
        .animate(CurvedAnimation(parent: _anim, curve: Curves.easeInOut));
    _opacity = Tween(begin: 0.4, end: 1.0)
        .animate(CurvedAnimation(parent: _anim, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _anim.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final color = widget.tracking ? AppColors.success : context.primary;
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Transform.scale(
        scale: widget.tracking ? _scale.value : 1.0,
        child: Opacity(
          opacity: widget.tracking ? _opacity.value : 1.0,
          child: Container(
            decoration: BoxDecoration(
              color: color, shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: color.withOpacity(0.5), blurRadius: 10, spreadRadius: 2)],
            ),
            child: const Icon(Icons.smartphone, color: Colors.white, size: 22),
          ),
        ),
      ),
    );
  }
}