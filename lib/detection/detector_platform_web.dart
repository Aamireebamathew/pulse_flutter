// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'detector_interface.dart';

class PlatformDetector implements ObjectDetectorInterface {
  bool _ready = false;

  @override
  Future<void> initialize() async {
    // Start webcam into hidden <video> first
    try {
      final startResult = js.context.callMethod('startWebcam', []);
      if (startResult != null) {
        await _jsPromiseToFuture(startResult as js.JsObject);
      }
    } catch (e) {
      debugPrint('[WebDetector] startWebcam: $e');
    }

    // Await the model load promise directly
    try {
      final modelPromise = js.context['cocoSsdReady'];
      if (modelPromise == null) throw Exception('cocoSsdReady not found on window');
      await _jsPromiseToFuture(modelPromise as js.JsObject);
      _ready = true;
      debugPrint('[WebDetector] ready ✓');
    } catch (e) {
      debugPrint('[WebDetector] init failed: $e');
      rethrow;
    }
  }

  @override
  Future<List<DetectedObject>> detect({Uint8List? imageBytes}) async {
    if (!_ready) return [];
    try {
      final jsPromise = js.context.callMethod('runCocoSsd', []);
      if (jsPromise == null) return [];
      final raw = await _jsPromiseToFuture(jsPromise as js.JsObject);
      if (raw == null) return [];

      final list = raw as js.JsArray;
      final results = <DetectedObject>[];

      for (int i = 0; i < list.length; i++) {
        try {
          final item  = list[i] as js.JsObject;
          final bbox  = item['bbox'] as js.JsArray;
          final vw    = (item['videoWidth']  as num?)?.toDouble() ?? 640;
          final vh    = (item['videoHeight'] as num?)?.toDouble() ?? 480;
          final conf  = (item['score'] as num).toDouble();
          final label = (item['class'] as String).toLowerCase();

          // bbox = [x, y, width, height] in px relative to video element
          final left   = ((bbox[0] as num) / vw).clamp(0.0, 1.0);
          final top    = ((bbox[1] as num) / vh).clamp(0.0, 1.0);
          final width  = ((bbox[2] as num) / vw).clamp(0.0, 1.0 - left);
          final height = ((bbox[3] as num) / vh).clamp(0.0, 1.0 - top);

          debugPrint('[WebDetector] $label ${(conf*100).toStringAsFixed(0)}% '
              'box=(${left.toStringAsFixed(2)}, ${top.toStringAsFixed(2)}, '
              '${width.toStringAsFixed(2)}, ${height.toStringAsFixed(2)})');

          if (conf < 0.45) continue;

          results.add(DetectedObject(
            label:      label,
            confidence: conf,
            boundingBox: Rect.fromLTWH(left, top, width, height),
          ));
        } catch (e) {
          debugPrint('[WebDetector] parse error item $i: $e');
        }
      }
      return results;
    } catch (e) {
      debugPrint('[WebDetector] detect error: $e');
      return [];
    }
  }

  @override
  Future<void> dispose() async {
    _ready = false;
    try { js.context.callMethod('stopWebcam', []); } catch (_) {}
  }

  Future<dynamic> _jsPromiseToFuture(js.JsObject promise) {
    final c = Completer<dynamic>();
    promise.callMethod('then', [
      js.allowInterop((dynamic r) => c.complete(r)),
      js.allowInterop((dynamic e) => c.completeError(e.toString())),
    ]);
    return c.future;
  }
}