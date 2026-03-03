import 'dart:async';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/supabase_service.dart';
import '../../widgets/common_widgets.dart';

// ─── Detection type ───────────────────────────────────────────────────────────
enum DetectionType { normal, unusual, unregistered }

// ─── COCO class aliases ───────────────────────────────────────────────────────
// Maps what a user might register as → COCO class names the model detects.
// NOTE: 'book' intentionally does NOT alias to laptop/computer to avoid
// false positives when different books/items of same class are detected.
const Map<String, List<String>> _kAliases = {
  // Electronics
  'phone':          ['cell phone'],
  'mobile':         ['cell phone'],
  'smartphone':     ['cell phone'],
  'iphone':         ['cell phone'],
  'android':        ['cell phone'],
  'laptop':         ['laptop'],
  'macbook':        ['laptop'],
  'computer':       ['laptop'],
  'chromebook':     ['laptop'],
  'keyboard':       ['keyboard'],
  'mouse':          ['mouse'],
  'monitor':        ['tv'],
  'screen':         ['tv'],
  'tv':             ['tv'],
  'television':     ['tv'],
  'remote':         ['remote'],
  'remote control': ['remote'],
  // Audio — COCO has no airpods class; 'remote' is the closest small object
  'airpods':        ['remote'],
  'earbuds':        ['remote'],
  'earphones':      ['remote'],
  'headphones':     ['remote'],
  'headset':        ['remote'],
  // Bags
  'backpack':       ['backpack'],
  'bag':            ['backpack', 'handbag'],
  'school bag':     ['backpack'],
  'handbag':        ['handbag'],
  'purse':          ['handbag'],
  'wallet':         ['handbag'],
  // Books / stationery — strict: only match if user registers exactly "book"
  'book':           ['book'],
  'notebook':       ['book'],
  'diary':          ['book'],
  'journal':        ['book'],
  'textbook':       ['book'],
  // Bottles / cups
  'bottle':         ['bottle'],
  'water bottle':   ['bottle'],
  'flask':          ['bottle'],
  'cup':            ['cup'],
  'mug':            ['cup'],
  'glass':          ['cup', 'wine glass'],
  'tumbler':        ['cup'],
  // Furniture
  'chair':          ['chair'],
  'sofa':           ['couch'],
  'couch':          ['couch'],
  'table':          ['dining table'],
  'desk':           ['dining table'],
  'bed':            ['bed'],
  // Kitchen
  'fridge':         ['refrigerator'],
  'refrigerator':   ['refrigerator'],
  'microwave':      ['microwave'],
  'oven':           ['oven'],
  'sink':           ['sink'],
  'knife':          ['knife'],
  'fork':           ['fork'],
  'spoon':          ['spoon'],
  'bowl':           ['bowl'],
  // Clothing / accessories
  'umbrella':       ['umbrella'],
  'tie':            ['tie'],
  'suitcase':       ['suitcase'],
  'luggage':        ['suitcase'],
  // Pets
  'cat':            ['cat'],
  'kitten':         ['cat'],
  'dog':            ['dog'],
  'puppy':          ['dog'],
  // Sports / toys
  'ball':           ['sports ball'],
  'football':       ['sports ball'],
  'basketball':     ['sports ball'],
  'teddy':          ['teddy bear'],
  'teddy bear':     ['teddy bear'],
  'bicycle':        ['bicycle'],
  'bike':           ['bicycle'],
  // Plants
  'plant':          ['potted plant'],
  'flower':         ['potted plant'],
  // People
  'person':         ['person'],
  'human':          ['person'],
  // Vehicle
  'car':            ['car'],
};

// Full COCO-SSD class list used by the simulation
const List<String> _kCocoClasses = [
  'cell phone', 'laptop', 'keyboard', 'mouse', 'remote', 'book',
  'backpack', 'handbag', 'bottle', 'cup', 'chair', 'couch',
  'tv', 'clock', 'vase', 'scissors', 'toothbrush', 'hair drier',
  'teddy bear', 'potted plant', 'umbrella', 'tie', 'suitcase',
  'bicycle', 'cat', 'dog', 'person', 'dining table', 'bed',
  'refrigerator', 'microwave', 'oven', 'sink', 'bowl', 'knife',
  'fork', 'spoon', 'wine glass', 'sports ball',
];

// Pairs of classes that look visually similar — require 75 %+ confidence
// before treating as a match to avoid false positives
const Map<String, List<String>> _kAmbiguous = {
  'book':       ['laptop', 'keyboard'],
  'laptop':     ['book'],
  'remote':     ['cell phone'],
  'cell phone': ['remote'],
  'handbag':    ['backpack'],
  'backpack':   ['handbag'],
};

// ─── Result model ─────────────────────────────────────────────────────────────
class DetectionResult {
  final String cocoClass;
  final String displayName;
  final String usualLocation;
  final double confidence;
  final DetectionType type;
  final Rect boundingBox; // normalized 0..1

  const DetectionResult({
    required this.cocoClass,
    required this.displayName,
    required this.usualLocation,
    required this.confidence,
    required this.type,
    required this.boundingBox,
  });
}

// ─── Matching helpers ─────────────────────────────────────────────────────────

Map<String, dynamic>? _findMatch(
  String cocoClass,
  List<Map<String, dynamic>> objects,
  double confidence,
) {
  if (confidence < 0.60) return null;

  final cl = cocoClass.toLowerCase().trim();

  for (final obj in objects) {
    final name = (obj['object_name'] as String? ?? '').toLowerCase().trim();

    // Tier 1 — exact class name match
    if (name == cl) return obj;

    // Tier 2 — registered name is an alias key → check if COCO class is in targets
    final aliasTargets = _kAliases[name] ?? [];
    if (aliasTargets.contains(cl)) return obj;

    // Tier 3 — COCO class is an alias key → check if registered name is in targets
    final reverseTargets = _kAliases[cl] ?? [];
    if (reverseTargets.any((t) => name == t || name.contains(t))) return obj;
  }
  return null;
}

bool _passesAmbiguityCheck(
    String cocoClass, String registeredName, double confidence) {
  final cl = cocoClass.toLowerCase().trim();
  final rn = registeredName.toLowerCase().trim();
  final conflicts = _kAmbiguous[cl] ?? [];
  if (conflicts.any((c) => rn.contains(c) || c.contains(rn))) {
    return confidence >= 0.75;
  }
  return true;
}

// ─── Screen ───────────────────────────────────────────────────────────────────
class LiveCameraScreen extends StatefulWidget {
  const LiveCameraScreen({super.key});

  @override
  State<LiveCameraScreen> createState() => _LiveCameraScreenState();
}

class _LiveCameraScreenState extends State<LiveCameraScreen> {
  CameraController? _controller;
  bool _cameraActive = false;
  bool _audioEnabled = true;
  bool _initializing = false;
  String? _cameraError;

  List<DetectionResult> _detections = [];
  List<Map<String, dynamic>> _registeredObjects = [];
  Timer? _detectionTimer;
  final _rng = Random();

  String _currentLocation = 'Living Room';
  final List<String> _locationOptions = [
    'Living Room', 'Bedroom', 'Kitchen', 'Bathroom',
    'Office', 'Garage', 'Hallway', 'Other',
  ];

  final Map<String, int> _lastLoggedAt = {};

  @override
  void initState() {
    super.initState();
    _loadRegisteredObjects();
  }

  @override
  void dispose() {
    _detectionTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _loadRegisteredObjects() async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;
    final objects = await SupabaseService.getObjects(user.id);
    if (mounted) setState(() => _registeredObjects = objects);
  }

  Future<void> _startCamera() async {
    setState(() { _initializing = true; _cameraError = null; });
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() { _cameraError = 'No cameras found.'; _initializing = false; });
        return;
      }
      _controller = CameraController(
          cameras.first, ResolutionPreset.medium, enableAudio: _audioEnabled);
      await _controller!.initialize();
      if (mounted) {
        setState(() { _cameraActive = true; _initializing = false; });
        _startDetectionLoop();
      }
    } catch (e) {
      setState(() { _cameraError = 'Camera error: $e'; _initializing = false; });
    }
  }

  Future<void> _stopCamera() async {
    _detectionTimer?.cancel();
    await _controller?.dispose();
    _controller = null;
    if (mounted) setState(() { _cameraActive = false; _detections = []; });
  }

  void _startDetectionLoop() {
    _detectionTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (_cameraActive) _runSimulatedDetection();
    });
  }

  /// Simulated detection loop.
  /// Replace with real tflite_flutter inference when ready:
  ///   final preds = await _model.runModelOnFrame(cameraImage);
  ///   // preds = List of {class, confidence, bbox}
  Future<void> _runSimulatedDetection() async {
    final results = <DetectionResult>[];
    final usedBoxes = <Rect>[];

    // ── Generate COCO candidates from registered objects ──────────────────
    for (final obj in _registeredObjects) {
      final name = (obj['object_name'] as String? ?? '').toLowerCase().trim();
      final cocoTargets = _kAliases[name] ?? [name];
      final cocoClass = cocoTargets.first;
      if (!_kCocoClasses.contains(cocoClass)) continue;

      final conf = 0.65 + _rng.nextDouble() * 0.30; // 65–95 %
      final box = _generateBox(usedBoxes);
      usedBoxes.add(box);

      final matched = _findMatch(cocoClass, _registeredObjects, conf);

      if (matched != null) {
        final regName = matched['object_name'] as String? ?? cocoClass;

        if (!_passesAmbiguityCheck(cocoClass, regName, conf)) {
          results.add(DetectionResult(
            cocoClass: cocoClass,
            displayName: cocoClass,
            usualLocation: '',
            confidence: conf,
            type: DetectionType.unregistered,
            boundingBox: box,
          ));
          continue;
        }

        final usualLoc =
            (matched['usual_location'] as String? ?? '').toLowerCase().trim();
        final currentLoc = _currentLocation.toLowerCase().trim();
        final isUsual = usualLoc.isEmpty ||
            currentLoc.contains(usualLoc) ||
            usualLoc.contains(currentLoc);

        results.add(DetectionResult(
          cocoClass: cocoClass,
          displayName: regName,
          usualLocation: matched['usual_location'] as String? ?? '',
          confidence: conf,
          type: isUsual ? DetectionType.normal : DetectionType.unusual,
          boundingBox: box,
        ));
      } else {
        results.add(DetectionResult(
          cocoClass: cocoClass,
          displayName: cocoClass,
          usualLocation: '',
          confidence: conf,
          type: DetectionType.unregistered,
          boundingBox: box,
        ));
      }
    }

    // ── Add 1–2 random unregistered detections ────────────────────────────
    final randomCount = _rng.nextInt(2) + 1;
    for (int i = 0; i < randomCount; i++) {
      final cls = _kCocoClasses[_rng.nextInt(_kCocoClasses.length)];
      final conf = 0.45 + _rng.nextDouble() * 0.40;
      // Only show if not already matched as registered
      final alreadyMatched = results.any((r) => r.cocoClass == cls &&
          r.type != DetectionType.unregistered);
      if (alreadyMatched) continue;
      final box = _generateBox(usedBoxes);
      usedBoxes.add(box);
      results.add(DetectionResult(
        cocoClass: cls,
        displayName: cls,
        usualLocation: '',
        confidence: conf,
        type: DetectionType.unregistered,
        boundingBox: box,
      ));
    }

    if (mounted) setState(() => _detections = results);

    // ── Log to Supabase (throttled 30 s per object) ───────────────────────
    final user = context.read<AuthProvider>().user;
    if (user == null) return;
    final now = DateTime.now().millisecondsSinceEpoch;

    for (final det in results) {
      if (det.type == DetectionType.unregistered) continue;
      final key = det.displayName;
      if (now - (_lastLoggedAt[key] ?? 0) < 30000) continue;
      _lastLoggedAt[key] = now;

      await SupabaseService.client.from('activity_logs').insert({
        'user_id': user.id,
        'activity_type': det.type == DetectionType.unusual
            ? 'unusual_activity'
            : 'detected',
        'location': _currentLocation,
        'confidence': det.confidence,
        'metadata': {
          'object_name': det.displayName,
          'coco_class': det.cocoClass,
          'detection_type': det.type.name,
          'usual_location': det.usualLocation,
        },
      });
    }
  }

  Rect _generateBox(List<Rect> existing) {
    for (int t = 0; t < 20; t++) {
      final w = 0.22 + _rng.nextDouble() * 0.25;
      final h = 0.22 + _rng.nextDouble() * 0.25;
      final x = _rng.nextDouble() * (1 - w);
      final y = _rng.nextDouble() * (1 - h);
      final c = Rect.fromLTWH(x, y, w, h);
      if (!existing.any((e) => e.overlaps(c))) return c;
    }
    return Rect.fromLTWH(_rng.nextDouble() * 0.5, _rng.nextDouble() * 0.5, 0.3, 0.3);
  }

  Color _color(DetectionType t) {
    switch (t) {
      case DetectionType.normal:       return const Color(0xFF22C55E);
      case DetectionType.unusual:      return const Color(0xFFEF4444);
      case DetectionType.unregistered: return const Color(0xFF3B82F6);
    }
  }

  String _sublabel(DetectionResult d) {
    switch (d.type) {
      case DetectionType.normal:
        return '✓ ${d.usualLocation.isNotEmpty ? d.usualLocation : "Normal location"}';
      case DetectionType.unusual:
        return '⚠ Should be: ${d.usualLocation}';
      case DetectionType.unregistered:
        return 'Not registered';
    }
  }

  @override
  Widget build(BuildContext context) {
    final normal = _detections.where((d) => d.type == DetectionType.normal).length;
    final unusual = _detections.where((d) => d.type == DetectionType.unusual).length;
    final unregistered = _detections.where((d) => d.type == DetectionType.unregistered).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Live Camera Detection',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const Text('Real-time object detection using your camera',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 15)),
          const SizedBox(height: 16),

          // Location picker
          GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(children: [
              const Icon(Icons.location_on_outlined,
                  color: Color(0xFF3B82F6), size: 20),
              const SizedBox(width: 10),
              const Text('Current Location:',
                  style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _currentLocation,
                    isExpanded: true,
                    items: _locationOptions
                        .map((l) =>
                            DropdownMenuItem(value: l, child: Text(l)))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _currentLocation = v!),
                  ),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 16),

          // Camera card
          GlassCard(
            padding: EdgeInsets.zero,
            child: Column(children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                child: SizedBox(
                  height: 340,
                  width: double.infinity,
                  child: _buildCameraView(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  Expanded(
                    child: GradientButton(
                      label: _initializing
                          ? 'Starting...'
                          : _cameraActive
                              ? 'Stop Camera'
                              : 'Start Camera',
                      icon: _cameraActive
                          ? Icons.videocam_off_outlined
                          : Icons.videocam_outlined,
                      onPressed: _initializing
                          ? null
                          : (_cameraActive ? _stopCamera : _startCamera),
                      loading: _initializing,
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
                  ),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 16),

          // Legend
          GlassCard(
            padding: const EdgeInsets.all(14),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _LegendItem(color: Color(0xFF22C55E), label: 'Normal location'),
                _LegendItem(color: Color(0xFFEF4444), label: 'Unusual place'),
                _LegendItem(color: Color(0xFF3B82F6), label: 'Unregistered'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Stats
          Row(children: [
            Expanded(child: _StatMini(
              icon: Icons.check_circle_outline,
              color: const Color(0xFF22C55E),
              count: normal, label: 'Normal',
            )),
            const SizedBox(width: 10),
            Expanded(child: _StatMini(
              icon: Icons.warning_amber_outlined,
              color: const Color(0xFFEF4444),
              count: unusual, label: 'Unusual',
            )),
            const SizedBox(width: 10),
            Expanded(child: _StatMini(
              icon: Icons.help_outline,
              color: const Color(0xFF3B82F6),
              count: unregistered, label: 'Unknown',
            )),
          ]),

          // Detection list
          if (_detections.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('Detections',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ..._detections.map((d) => _DetectionCard(
                detection: d, color: _color(d.type), sublabel: _sublabel(d))),
          ],

          // Info box
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: const Color(0xFF3B82F6).withOpacity(0.2)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.info_outline,
                      color: Color(0xFF3B82F6), size: 16),
                  SizedBox(width: 8),
                  Text('How Detection Works',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF3B82F6))),
                ]),
                SizedBox(height: 8),
                Text(
                  '• 🟢 Green = your object in its usual place\n'
                  '• 🔴 Red = your object found in wrong location\n'
                  '• 🔵 Blue = detected object not in your registry\n'
                  '• Similar items (e.g. different books) need 75%+ confidence to match\n'
                  '• Register objects by their common name: "laptop" not "MacBook", "phone" not "Samsung"',
                  style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                      height: 1.6),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraView() {
    if (_cameraError != null) {
      return Container(
        color: const Color(0xFF0F172A),
        child: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 40),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(_cameraError!,
                  style: const TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _startCamera,
              icon: const Icon(Icons.refresh, color: Colors.white70),
              label: const Text('Retry',
                  style: TextStyle(color: Colors.white70)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white24),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ]),
        ),
      );
    }

    if (_initializing) {
      return Container(
        color: const Color(0xFF0F172A),
        child: const Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            CircularProgressIndicator(color: Color(0xFF3B82F6)),
            SizedBox(height: 16),
            Text('Starting camera...',
                style: TextStyle(color: Colors.white54)),
          ]),
        ),
      );
    }

    if (_cameraActive &&
        _controller != null &&
        _controller!.value.isInitialized) {
      return LayoutBuilder(builder: (ctx, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        return Stack(
          fit: StackFit.expand,
          children: [
            CameraPreview(_controller!),
            ..._detections.map((det) {
              final b = det.boundingBox;
              return Positioned(
                left: b.left * w,
                top: b.top * h,
                width: b.width * w,
                height: b.height * h,
                child: _BoundingBox(
                  label: det.displayName,
                  sublabel: _sublabel(det),
                  color: _color(det.type),
                  confidence: det.confidence,
                ),
              );
            }),
            Positioned(
              top: 12, right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    width: 8, height: 8,
                    decoration: const BoxDecoration(
                        color: Color(0xFF22C55E),
                        shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  const Text('Scanning',
                      style:
                          TextStyle(color: Colors.white, fontSize: 12)),
                ]),
              ),
            ),
          ],
        );
      });
    }

    return Container(
      color: const Color(0xFF0F172A),
      child: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.videocam_off_outlined,
              color: Colors.white38, size: 48),
          const SizedBox(height: 12),
          const Text('Camera is off',
              style: TextStyle(color: Colors.white54, fontSize: 16)),
          const SizedBox(height: 4),
          const Text('Tap Start Camera to begin detection',
              style: TextStyle(color: Colors.white38, fontSize: 13)),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: _startCamera,
            icon: const Icon(Icons.play_arrow, color: Colors.white70),
            label: const Text('Start',
                style: TextStyle(color: Colors.white70)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.white24),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ]),
      ),
    );
  }
}

// ─── Raw detection (internal) ─────────────────────────────────────────────────
class _RawDetection {
  final String cocoClass;
  final double confidence;
  _RawDetection({required this.cocoClass, required this.confidence});
}

// ─── Bounding box ─────────────────────────────────────────────────────────────
class _BoundingBox extends StatelessWidget {
  final String label;
  final String sublabel;
  final Color color;
  final double confidence;

  const _BoundingBox({
    required this.label,
    required this.sublabel,
    required this.color,
    required this.confidence,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (confidence * 100).toStringAsFixed(0);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: color, width: 2.5),
            borderRadius: BorderRadius.circular(6),
            color: color.withOpacity(0.07),
          ),
        ),
        Positioned(top: -2, left: -2,
            child: _CornerAccent(color: color, top: true,  left: true)),
        Positioned(top: -2, right: -2,
            child: _CornerAccent(color: color, top: true,  left: false)),
        Positioned(bottom: -2, left: -2,
            child: _CornerAccent(color: color, top: false, left: true)),
        Positioned(bottom: -2, right: -2,
            child: _CornerAccent(color: color, top: false, left: false)),
        Positioned(
          top: -1, left: 0,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 160),
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                bottomRight: Radius.circular(8),
              ),
              boxShadow: [
                BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 6,
                    offset: const Offset(0, 2))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${label.toUpperCase()}  $pct%',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3),
                  overflow: TextOverflow.ellipsis,
                ),
                if (sublabel.isNotEmpty)
                  Text(sublabel,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 9),
                      overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CornerAccent extends StatelessWidget {
  final Color color;
  final bool top, left;
  const _CornerAccent(
      {required this.color, required this.top, required this.left});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 14, height: 14,
        child: CustomPaint(
            painter: _CornerPainter(color: color, top: top, left: left)),
      );
}

class _CornerPainter extends CustomPainter {
  final Color color;
  final bool top, left;
  _CornerPainter(
      {required this.color, required this.top, required this.left});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final x = left ? 0.0 : size.width;
    final y = top  ? 0.0 : size.height;
    canvas.drawLine(Offset(x, y), Offset(left ? size.width : 0, y), p);
    canvas.drawLine(Offset(x, y), Offset(x, top ? size.height : 0), p);
  }

  @override
  bool shouldRepaint(_CornerPainter o) => false;
}

// ─── Small widgets ────────────────────────────────────────────────────────────
class _DetectionCard extends StatelessWidget {
  final DetectionResult detection;
  final Color color;
  final String sublabel;

  const _DetectionCard(
      {required this.detection,
      required this.color,
      required this.sublabel});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 1.5),
        borderRadius: BorderRadius.circular(14),
        color: color.withOpacity(0.06),
      ),
      child: Row(children: [
        Container(
            width: 10, height: 10,
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(detection.displayName,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                Text(sublabel,
                    style: TextStyle(fontSize: 12, color: color)),
                Text(
                  '${(detection.confidence * 100).toStringAsFixed(0)}% confidence · ${detection.cocoClass}',
                  style: const TextStyle(
                      fontSize: 10, color: Color(0xFF94A3B8)),
                ),
              ]),
        ),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            detection.type == DetectionType.normal
                ? 'Normal'
                : detection.type == DetectionType.unusual
                    ? 'Unusual'
                    : 'Unknown',
            style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w600),
          ),
        ),
      ]),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
          width: 12, height: 12,
          decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: color.withOpacity(0.4), blurRadius: 4)
              ])),
      const SizedBox(width: 6),
      Text(label,
          style: const TextStyle(
              fontSize: 12, color: Color(0xFF64748B))),
    ]);
  }
}

class _StatMini extends StatelessWidget {
  final IconData icon;
  final Color color;
  final int count;
  final String label;

  const _StatMini(
      {required this.icon,
      required this.color,
      required this.count,
      required this.label});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 6),
        Text('$count',
            style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold)),
        Text(label,
            style: const TextStyle(
                fontSize: 11, color: Color(0xFF94A3B8))),
      ]),
    );
  }
}