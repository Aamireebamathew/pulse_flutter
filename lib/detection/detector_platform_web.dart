// Web implementation — compiled only when dart.library.html is available.
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
    // Wait for window.cocoSsdReady (set in index.html)
    for (int i = 0; i < 300; i++) {
      await Future.delayed(const Duration(milliseconds: 100));
      try {
        final ready = js.context['_dartCocoReady'];
        if (ready == true) { _ready = true; return; }
        // Trigger the JS promise chain once
        if (i == 0) {
          js.context.callMethod('eval', ['''
            (async () => { await window.cocoSsdReady; window._dartCocoReady = true; })();
          ''']);
        }
      } catch (_) {}
    }
    throw Exception('TF.js COCO-SSD did not load within 30 s');
  }

  @override
  Future<List<DetectedObject>> detect({Uint8List? imageBytes}) async {
    if (!_ready) return [];
    try {
      final jsResult = js.context.callMethod('runCocoSsd', []);
      if (jsResult == null) return [];
      final rawList = await _jsPromiseToFuture(jsResult as js.JsObject);
      if (rawList == null) return [];
      final list = rawList as js.JsArray;
      final results = <DetectedObject>[];
      for (int i = 0; i < list.length; i++) {
        try {
          final item = list[i] as js.JsObject;
          final bbox = item['bbox'] as js.JsArray;
          final vw = (item['videoWidth']  as num?)?.toDouble() ?? 640;
          final vh = (item['videoHeight'] as num?)?.toDouble() ?? 480;
          final conf = (item['score'] as num).toDouble();
          if (conf < 0.50) continue;
          results.add(DetectedObject(
            label: (item['class'] as String).toLowerCase(),
            confidence: conf,
            boundingBox: Rect.fromLTWH(
              (bbox[0] as num) / vw,
              (bbox[1] as num) / vh,
              (bbox[2] as num) / vw,
              (bbox[3] as num) / vh,
            ),
          ));
        } catch (_) {}
      }
      return results;
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> dispose() async => _ready = false;

  Future<dynamic> _jsPromiseToFuture(js.JsObject promise) {
    final c = Completer<dynamic>();
    promise.callMethod('then', [
      js.allowInterop((r) => c.complete(r)),
      js.allowInterop((e) => c.completeError(e.toString())),
    ]);
    return c.future;
  }
}