// Mobile implementation (Android / iOS) — compiled only when dart.library.io is available.
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';

import 'detector_interface.dart';

class PlatformDetector implements ObjectDetectorInterface {
  late final ObjectDetector _detector;

  @override
  Future<void> initialize() async {
    final options = ObjectDetectorOptions(
      mode: DetectionMode.stream,
      classifyObjects: true,
      multipleObjects: true,
    );
    _detector = ObjectDetector(options: options);
  }

  @override
  Future<List<DetectedObject>> detect({Uint8List? imageBytes}) async {
    if (imageBytes == null) return [];
    final inputImage = InputImage.fromBytes(
      bytes: imageBytes,
      metadata: InputImageMetadata(
        size: const Size(640, 480),
        rotation: InputImageRotation.rotation0deg,
        format: InputImageFormat.nv21,
        bytesPerRow: 640,
      ),
    );
    final mlObjects = await _detector.processImage(inputImage);
    return mlObjects.map((obj) {
      const imgW = 640.0;
      const imgH = 480.0;
      final normBox = Rect.fromLTWH(
        obj.boundingBox.left   / imgW,
        obj.boundingBox.top    / imgH,
        obj.boundingBox.width  / imgW,
        obj.boundingBox.height / imgH,
      );
      final topLabel = obj.labels.isNotEmpty
          ? obj.labels.reduce((a, b) => a.confidence > b.confidence ? a : b)
          : null;
      return DetectedObject(
        label:       topLabel?.text.toLowerCase() ?? 'object',
        confidence:  topLabel?.confidence         ?? 0.5,
        boundingBox: normBox,
      );
    }).where((d) => d.confidence >= 0.50).toList();
  }

  @override
  Future<void> dispose() async => _detector.close();
}