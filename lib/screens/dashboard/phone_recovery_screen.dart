import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../widgets/common_widgets.dart';

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
    setState(() {
      _locationLoading = true;
      _locationError = '';
    });

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _locationError = 'Location services are disabled.';
        _locationLoading = false;
      });
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _locationError = 'Location permission denied.';
          _locationLoading = false;
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _locationError =
            'Location permission permanently denied. Enable in settings.';
        _locationLoading = false;
      });
      return;
    }

    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      setState(() {
        _position = pos;
        _lastSeen = DateTime.now();
        _locationLoading = false;
      });
    } catch (e) {
      setState(() {
        _locationError = 'Unable to retrieve location.';
        _locationLoading = false;
      });
    }
  }

  void _toggleTracking() {
    if (_tracking) {
      _positionSub?.cancel();
      _btTimer?.cancel();
      setState(() {
        _tracking = false;
        _bluetoothSignal = 0;
      });
    } else {
      setState(() => _tracking = true);
      _positionSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      ).listen((pos) {
        setState(() {
          _position = pos;
          _lastSeen = DateTime.now();
        });
      });

      // Simulate bluetooth signal
      _btTimer = Timer.periodic(const Duration(seconds: 2), (_) {
        setState(() {
          _bluetoothSignal = (Random().nextDouble() * 60) + 40;
        });
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
    final lat = _position!.latitude;
    final lng = _position!.longitude;
    launchUrl(Uri.parse('https://www.google.com/maps?q=$lat,$lng'));
  }

  String _signalStrength() {
    if (_bluetoothSignal <= 0) return 'No Signal';
    if (_bluetoothSignal < 50) return 'Weak';
    if (_bluetoothSignal < 75) return 'Good';
    return 'Excellent';
  }

  Color _signalColor() {
    if (_bluetoothSignal <= 0) return const Color(0xFF94A3B8);
    if (_bluetoothSignal < 50) return const Color(0xFFEF4444);
    if (_bluetoothSignal < 75) return const Color(0xFFF59E0B);
    return const Color(0xFF22C55E);
  }

  String _timeSinceSeen() {
    final diff = DateTime.now().difference(_lastSeen);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Phone Recovery',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const Text('Locate and recover your device',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 15)),
          const SizedBox(height: 24),

          // Location card
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Color(0xFF3B82F6)),
                    const SizedBox(width: 8),
                    const Text('Current Location',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    IconButton(
                      onPressed: _fetchLocation,
                      icon: _locationLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (_locationError.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: Colors.red, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_locationError,
                              style: const TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  )
                else if (_position != null) ...[
                  _CoordRow(
                    label: 'Latitude',
                    value:
                        _position!.latitude.toStringAsFixed(6),
                  ),
                  const SizedBox(height: 8),
                  _CoordRow(
                    label: 'Longitude',
                    value:
                        _position!.longitude.toStringAsFixed(6),
                  ),
                  const SizedBox(height: 8),
                  _CoordRow(
                    label: 'Accuracy',
                    value:
                        '±${_position!.accuracy.toStringAsFixed(0)}m',
                  ),
                  const SizedBox(height: 16),
                  GradientButton(
                    label: 'Open in Maps',
                    icon: Icons.navigation_outlined,
                    onPressed: _openMaps,
                    height: 46,
                  ),
                ] else
                  const Text('Fetching location...',
                      style: TextStyle(color: Color(0xFF94A3B8))),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Last seen & tracking
          GlassCard(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Last Seen',
                          style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF94A3B8))),
                      Text(
                        _timeSinceSeen(),
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                GradientButton(
                  label: _tracking ? 'Stop' : 'Track Live',
                  icon: _tracking ? Icons.stop : Icons.radio_button_checked,
                  onPressed: _toggleTracking,
                  gradient: _tracking
                      ? [const Color(0xFFEF4444), const Color(0xFFDC2626)]
                      : null,
                  height: 44,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Bluetooth signal
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.bluetooth, color: Color(0xFF3B82F6)),
                    const SizedBox(width: 8),
                    const Text('Bluetooth Signal',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Text(
                      _signalStrength(),
                      style: TextStyle(
                          color: _signalColor(),
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _bluetoothSignal / 100,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFE2E8F0),
                    valueColor:
                        AlwaysStoppedAnimation(_signalColor()),
                  ),
                ),
                if (!_tracking)
                  const Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: Text(
                      'Start live tracking to see signal',
                      style: TextStyle(
                          color: Color(0xFF94A3B8), fontSize: 13),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Sound alert
          GlassCard(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Sound Alert',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600)),
                      const Text(
                          'Play a sound to help find your phone',
                          style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 13)),
                    ],
                  ),
                ),
                GradientButton(
                  label: _isPlaying ? 'Playing...' : 'Play Sound',
                  icon: _isPlaying
                      ? Icons.volume_up
                      : Icons.volume_up_outlined,
                  onPressed: _playSound,
                  gradient: _isPlaying
                      ? [const Color(0xFF22C55E), const Color(0xFF16A34A)]
                      : null,
                  height: 44,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CoordRow extends StatelessWidget {
  final String label;
  final String value;

  const _CoordRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
          ),
        ),
        Text(
          value,
          style:
              const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ],
    );
  }
}
