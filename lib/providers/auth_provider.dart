import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

// local_auth only works on Android/iOS — guard every call with !kIsWeb
import 'package:local_auth/local_auth.dart'
    if (dart.library.html) '../utils/local_auth_stub.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  bool  _loading = true;

  // ── Biometric ─────────────────────────────────────────────────────────────
  // Only instantiate LocalAuthentication on mobile — crashes on web/desktop
  final _localAuth = kIsWeb ? null : LocalAuthentication();
  bool _biometricEnabled   = false;
  bool _biometricAvailable = false;
  List<BiometricType> _availableBiometrics = [];

  // ── Voice ─────────────────────────────────────────────────────────────────
  bool    _voiceEnabled = false;
  String? _voicePin;

  User? get user               => _user;
  bool  get loading            => _loading;
  bool  get isAuthenticated    => _user != null;
  bool  get biometricAvailable => _biometricAvailable;
  bool  get biometricEnabled   => _biometricEnabled;
  bool  get voiceEnabled       => _voiceEnabled;
  List<BiometricType> get availableBiometrics => _availableBiometrics;

  // True only on actual mobile hardware with enrolled biometrics
  bool get canUseBiometric => !kIsWeb && _biometricAvailable;

  AuthProvider() { _init(); }

  Future<void> _init() async {
    _user    = SupabaseService.currentUser;
    _loading = false;
    notifyListeners();

    SupabaseService.authStateChanges.listen((data) {
      _user = data.session?.user;
      notifyListeners();
    });

    if (!kIsWeb) {
      await _checkBiometricSupport();
    }
    await _loadSecurityPrefs();
  }

  // ── Redirect URL for email confirmation ───────────────────────────────────
  // On web: use current origin so the confirmation link returns to the app
  // On mobile: use deep link scheme
  static String get _redirectUrl {
    if (kIsWeb) {
      // Uri.base.origin = e.g. "http://localhost:52462"
      // Supabase will append #access_token=... which the Flutter web client
      // picks up automatically via onAuthStateChange
      return Uri.base.origin;
    }
    return 'io.supabase.neardear://login-callback';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STANDARD AUTH
  // ═══════════════════════════════════════════════════════════════════════════

  Future<String?> signIn(String email, String password) async {
    try {
      await SupabaseService.client.auth
          .signInWithPassword(email: email, password: password);
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> signUp(String email, String password) async {
    try {
      await SupabaseService.client.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: _redirectUrl, // ← sends user back to app after confirm
      );
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> signOut() async {
    await SupabaseService.client.auth.signOut();
  }

  Future<String?> resetPassword(String email) async {
    try {
      await SupabaseService.client.auth.resetPasswordForEmail(
        email,
        redirectTo: _redirectUrl,
      );
      return null;
    } on AuthException catch (e) {
      return e.message;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BIOMETRIC — mobile only
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _checkBiometricSupport() async {
    if (kIsWeb || _localAuth == null) {
      _biometricAvailable = false;
      notifyListeners();
      return;
    }
    try {
      _biometricAvailable = await _localAuth!.canCheckBiometrics &&
          await _localAuth!.isDeviceSupported();
      if (_biometricAvailable) {
        _availableBiometrics = await _localAuth!.getAvailableBiometrics();
      }
    } on PlatformException {
      _biometricAvailable = false;
    }
    notifyListeners();
  }

  Future<void> _loadSecurityPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _biometricEnabled = prefs.getBool('biometric_enabled') ?? false;
    _voiceEnabled     = prefs.getBool('voice_enabled')     ?? false;
    _voicePin         = prefs.getString('voice_pin');
    notifyListeners();
  }

  Future<String?> setupBiometric() async {
    if (kIsWeb) return 'Biometrics are not supported on web or desktop. Use the mobile app.';
    await _checkBiometricSupport();
    if (!_biometricAvailable) return 'Biometric authentication is not available on this device.';
    if (_availableBiometrics.isEmpty) {
      return 'No biometrics enrolled. Please set up fingerprint or Face ID in device settings.';
    }
    try {
      final ok = await _localAuth!.authenticate(
        localizedReason: 'Confirm your identity to enable biometric login',
        options: const AuthenticationOptions(biometricOnly: true, stickyAuth: true),
      );
      if (ok) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('biometric_enabled', true);
        _biometricEnabled = true;
        notifyListeners();
        return null;
      }
      return 'Biometric confirmation was cancelled.';
    } on PlatformException catch (e) {
      return 'Biometric error: ${e.message}';
    }
  }

  Future<String?> disableBiometric() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometric_enabled', false);
    _biometricEnabled = false;
    notifyListeners();
    return null;
  }

  Future<String?> signInWithBiometric() async {
    if (kIsWeb) return 'Biometrics are not supported on web or desktop.';
    if (!_biometricEnabled) return 'Biometric login is not set up.';
    try {
      final ok = await _localAuth!.authenticate(
        localizedReason: 'Sign in to NearDear',
        options: const AuthenticationOptions(biometricOnly: true, stickyAuth: true),
      );
      if (ok) {
        final session = SupabaseService.client.auth.currentSession;
        if (session != null) {
          _user = session.user;
          notifyListeners();
          return null;
        }
        return 'No saved session. Please sign in with email first.';
      }
      return 'Biometric authentication failed.';
    } on PlatformException catch (e) {
      return 'Biometric error: ${e.message}';
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // VOICE
  // ═══════════════════════════════════════════════════════════════════════════

  Future<String?> setupVoice(String spokenPhrase) async {
    if (spokenPhrase.trim().length < 4) {
      return 'Voice passphrase too short. Please speak a longer phrase.';
    }
    final normalized = spokenPhrase.trim().toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('voice_enabled', true);
    await prefs.setString('voice_pin', normalized);
    _voiceEnabled = true;
    _voicePin     = normalized;
    notifyListeners();
    return null;
  }

  Future<String?> disableVoice() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('voice_enabled', false);
    await prefs.remove('voice_pin');
    _voiceEnabled = false;
    _voicePin     = null;
    notifyListeners();
    return null;
  }

  Future<String?> signInWithVoice(String spokenPhrase) async {
    if (!_voiceEnabled || _voicePin == null) return 'Voice login is not set up.';
    final input = spokenPhrase.trim().toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ');
    if (input == _voicePin) {
      final session = SupabaseService.client.auth.currentSession;
      if (session != null) {
        _user = session.user;
        notifyListeners();
        return null;
      }
      return 'No saved session. Please sign in with email first.';
    }
    return 'Voice passphrase did not match. Try again.';
  }
}