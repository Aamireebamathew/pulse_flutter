import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'detector_interface.dart';

class PlatformDetector implements ObjectDetectorInterface {
  @override Future<void> initialize() async {}
  @override Future<List<DetectedObject>> detect({Uint8List? imageBytes}) async => [];
  @override Future<void> dispose() async {}
}