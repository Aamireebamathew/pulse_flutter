// voice_service.dart
// Flutter equivalent of useVoice() hook
// Wraps speech_to_text + flutter_tts packages
//
// pubspec.yaml dependencies:
//   speech_to_text: ^6.6.0
//   flutter_tts: ^4.0.0

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';

enum MicError { notSupported, permissionDenied, noSpeech, network, unknown }

class VoiceService extends ChangeNotifier {
  static final VoiceService instance = VoiceService._();
  VoiceService._();

  final SpeechToText _stt = SpeechToText();
  final FlutterTts   _tts = FlutterTts();

  bool      _isListening = false;
  bool      _isSupported = false;
  String    _transcript  = '';
  String    _detectedLang = 'en-US';
  MicError? _micError;

  bool      get isListening  => _isListening;
  bool      get isSupported  => _isSupported;
  String    get transcript   => _transcript;
  String    get detectedLang => _detectedLang;
  MicError? get micError     => _micError;

  Future<void> initialize() async {
    _isSupported = await _stt.initialize(
      onError: (e) {
        _isListening = false;
        switch (e.errorMsg) {
          case 'error_permission_blocked':
          case 'error_permission_denied':
            _micError = MicError.permissionDenied; break;
          case 'error_no_match':
          case 'error_speech_timeout':
            _micError = MicError.noSpeech; break;
          case 'error_network':
          case 'error_network_timeout':
            _micError = MicError.network; break;
          default:
            _micError = MicError.unknown;
        }
        notifyListeners();
      },
      onStatus: (s) {
        if (s == 'done' || s == 'notListening') {
          _isListening = false;
          notifyListeners();
        }
      },
    );

    if (!_isSupported) {
      _micError = MicError.notSupported;
      notifyListeners();
    }

    await _tts.setLanguage(_detectedLang);
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
  }

  void setLanguage(String langCode) {
    _detectedLang = langCode;
    _tts.setLanguage(langCode);
    notifyListeners();
  }

  Future<void> startListening() async {
    if (!_isSupported || _isListening) return;
    _transcript = '';
    _micError   = null;
    notifyListeners();

    final available = await _stt.initialize();
    if (!available) {
      _micError = MicError.permissionDenied;
      notifyListeners();
      return;
    }

    await _stt.listen(
      localeId: _detectedLang,
      listenFor: const Duration(seconds: 30),
      pauseFor:  const Duration(seconds: 3),
      onResult: (result) {
        _transcript = result.recognizedWords;
        _micError   = null;
        notifyListeners();
      },
    );
    _isListening = true;
    notifyListeners();
  }

  void stopListening() {
    if (_isListening) {
      _stt.stop();
      _isListening = false;
      notifyListeners();
    }
  }

  Future<void> speak(String text, {String? lang}) async {
    await _tts.setLanguage(lang ?? _detectedLang);
    await _tts.stop();
    await _tts.speak(text);
  }

  void clearTranscript() {
    _transcript = '';
    notifyListeners();
  }

  @override
  void dispose() {
    _stt.cancel();
    _tts.stop();
    super.dispose();
  }
}