import 'package:flutter/material.dart';

import '../../widgets/common_widgets.dart';

class LiveCameraScreen extends StatefulWidget {
  const LiveCameraScreen({super.key});

  @override
  State<LiveCameraScreen> createState() => _LiveCameraScreenState();
}

class _LiveCameraScreenState extends State<LiveCameraScreen> {
  bool _cameraActive = false;
  bool _audioEnabled = true;
  final List<_Detection> _detections = [];

  // In production: Initialize camera controller and TFLite model here
  // For the Flutter port, camera detection uses the `camera` package
  // and tflite_flutter for on-device ML inference.

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Live Camera Detection',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const Text('Real-time object detection using your camera',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 15)),
          const SizedBox(height: 24),

          // Camera preview placeholder
          GlassCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                Container(
                  height: 280,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFF0F172A),
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: _cameraActive
                      ? _buildActiveCameraView()
                      : _buildInactiveOverlay(),
                ),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: GradientButton(
                          label: _cameraActive ? 'Stop Camera' : 'Start Camera',
                          icon: _cameraActive
                              ? Icons.videocam_off_outlined
                              : Icons.videocam_outlined,
                          onPressed: () =>
                              setState(() => _cameraActive = !_cameraActive),
                          gradient: _cameraActive
                              ? [
                                  const Color(0xFFEF4444),
                                  const Color(0xFFDC2626)
                                ]
                              : null,
                          height: 46,
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        onPressed: () =>
                            setState(() => _audioEnabled = !_audioEnabled),
                        icon: Icon(
                          _audioEnabled
                              ? Icons.volume_up_outlined
                              : Icons.volume_off_outlined,
                          color: _audioEnabled
                              ? const Color(0xFF3B82F6)
                              : const Color(0xFF94A3B8),
                        ),
                        tooltip:
                            _audioEnabled ? 'Mute audio' : 'Enable audio',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Info cards row
          Row(
            children: [
              Expanded(
                child: GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Icon(Icons.remove_red_eye_outlined,
                          color: Color(0xFF3B82F6), size: 24),
                      const SizedBox(height: 6),
                      Text('${_detections.length}',
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold)),
                      const Text('Objects Detected',
                          style: TextStyle(
                              fontSize: 12, color: Color(0xFF94A3B8))),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Icon(Icons.speed_outlined,
                          color: Color(0xFF22C55E), size: 24),
                      const SizedBox(height: 6),
                      const Text('72%',
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold)),
                      const Text('Similarity Threshold',
                          style: TextStyle(
                              fontSize: 12, color: Color(0xFF94A3B8)),
                          textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // How it works
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.info_outline, color: Color(0xFF3B82F6)),
                    SizedBox(width: 8),
                    Text('How It Works',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 12),
                ...[
                  '📸 Camera captures frames every few seconds',
                  '🤖 On-device ML model extracts visual features',
                  '🔍 Compares against your registered objects',
                  '🔔 Alerts you when objects are detected or missing',
                  '📍 Logs detection events with location context',
                ].map((step) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(step,
                          style: const TextStyle(
                              fontSize: 14, color: Color(0xFF64748B))),
                    )),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: const Color(0xFFF59E0B).withOpacity(0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: Color(0xFFF59E0B), size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Camera permission required. Processing is done on-device for privacy.',
                          style: TextStyle(
                              fontSize: 13, color: Color(0xFFF59E0B)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (_detections.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text('Recent Detections',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ..._detections.map((d) => _DetectionRow(detection: d)),
          ],
        ],
      ),
    );
  }

  Widget _buildActiveCameraView() {
    // In production, replace with CameraPreview(controller)
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.videocam, color: Colors.white54, size: 40),
          SizedBox(height: 8),
          Text('Camera Active',
              style: TextStyle(color: Colors.white70, fontSize: 16)),
          SizedBox(height: 4),
          Text('Scanning for registered objects...',
              style: TextStyle(color: Colors.white38, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildInactiveOverlay() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.videocam_off_outlined,
              color: Colors.white38, size: 48),
          const SizedBox(height: 12),
          const Text('Camera is off',
              style:
                  TextStyle(color: Colors.white54, fontSize: 16)),
          const SizedBox(height: 4),
          const Text('Tap Start Camera to begin detection',
              style: TextStyle(color: Colors.white38, fontSize: 13)),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () => setState(() => _cameraActive = true),
            icon: const Icon(Icons.play_arrow, color: Colors.white70),
            label: const Text('Start',
                style: TextStyle(color: Colors.white70)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.white24),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Detection {
  final String name;
  final double similarity;
  final bool unusual;
  final DateTime time;

  _Detection({
    required this.name,
    required this.similarity,
    required this.unusual,
    required this.time,
  });
}

class _DetectionRow extends StatelessWidget {
  final _Detection detection;

  const _DetectionRow({required this.detection});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Icon(
            detection.unusual
                ? Icons.warning_amber_outlined
                : Icons.check_circle_outline,
            color: detection.unusual
                ? const Color(0xFFF59E0B)
                : const Color(0xFF22C55E),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(detection.name,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(
                    '${(detection.similarity * 100).toStringAsFixed(0)}% match',
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF94A3B8))),
              ],
            ),
          ),
          Text(
            '${detection.time.hour}:${detection.time.minute.toString().padLeft(2, '0')}',
            style: const TextStyle(
                fontSize: 12, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }
}
