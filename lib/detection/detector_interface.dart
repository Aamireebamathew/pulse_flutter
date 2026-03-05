import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart'; // Rect

/// A single detected object returned by any detector implementation.
class DetectedObject {
  /// COCO class label e.g. "cell phone", "person", "laptop"
  final String label;

  /// Confidence in [0, 1]
  final double confidence;

  /// Normalised bounding box (values 0–1 relative to frame size).
  /// left, top, width, height — all in [0, 1].
  final Rect boundingBox;

  const DetectedObject({
    required this.label,
    required this.confidence,
    required this.boundingBox,
  });
}

/// Common contract that both mobile (ML Kit) and web (TF.js) detectors fulfil.
abstract class ObjectDetectorInterface {
  /// Initialise the underlying model. Call once before [detect].
  Future<void> initialize();

  /// Run detection. On mobile pass [imageBytes] (JPEG/PNG from camera stream).
  /// On web the detector reads directly from the live <video> element, so
  /// [imageBytes] may be null.
  Future<List<DetectedObject>> detect({Uint8List? imageBytes});

  /// Release resources.
  Future<void> dispose();
}