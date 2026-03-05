// detector_factory.dart
// Each platform file defines exactly ONE class: PlatformDetector
// So this file never references a class absent from the current build.

import 'detector_interface.dart';

import 'detector_platform_stub.dart'
    if (dart.library.html) 'detector_platform_web.dart'
    if (dart.library.io)   'detector_platform_mobile.dart';

class DetectorFactory {
  static ObjectDetectorInterface create() => PlatformDetector();
}