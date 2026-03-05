import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  bool  _loading = true;

  // ── Biometric state ───────────────────────────────────────────────────────
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _biometricEnabled  = false;
  bool _biometricAvailable = false;
  List<BiometricType> _availableBiometrics = [];

  // ── Voice state ───────────────────────────────────────────────────────────
  bool _voiceEnabled = false;
  String? _voicePin; // SHA-256 stored in prefs — user speaks a passphrase

  User? get user              => _user;
  bool  get loading           => _loading;
  bool  get isAuthenticated   => _user != null;
  bool  get biometricEnabled  => _biometricEnabled;
  bool  get biometricAvailable=> _biometricAvailable;
  bool  get voiceEnabled      => _voiceEnabled;
  List<BiometricType> get availableBiometrics => _availableBiometrics;

  AuthProvider() { _init(); }

  Future<void> _init() async {
    _user    = SupabaseService.currentUser;
    _loading = false;
    notifyListeners();

    SupabaseService.authStateChanges.listen((data) {
      _user = data.session?.user;
      notifyListeners();
    });

    await _checkBiometricSupport();
    await _loadSecurityPrefs();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BIOMETRIC
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _checkBiometricSupport() async {
    try {
      _biometricAvailable = await _localAuth.canCheckBiometrics &&
          await _localAuth.isDeviceSupported();
      if (_biometricAvailable) {
        _availableBiometrics = await _localAuth.getAvailableBiometrics();
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

  /// Call from Setup Biometrics button — prompts the user and enables if success.
  Future<String?> setupBiometric() async {
    await _checkBiometricSupport();

    if (!_biometricAvailable) {
      return 'Biometric authentication is not available on this device.';
    }
    if (_availableBiometrics.isEmpty) {
      return 'No biometrics enrolled. Please set up fingerprint or face in device settings.';
    }

    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Confirm your identity to enable biometric login',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (authenticated) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('biometric_enabled', true);
        _biometricEnabled = true;
        notifyListeners();
        return null; // success
      } else {
        return 'Biometric confirmation was cancelled.';
      }
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

  /// Sign in using biometrics — only works if biometricEnabled == true.
  Future<String?> signInWithBiometric() async {
    if (!_biometricEnabled) return 'Biometric login is not set up.';

    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Sign in to Pulse',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (authenticated) {
        // Re-use the saved session — Supabase persists it on device
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

  /// Store a voice passphrase (hashed). Called after user speaks their phrase.
  Future<String?> setupVoice(String spokenPhrase) async {
    if (spokenPhrase.trim().length < 4) {
      return 'Voice passphrase too short. Please speak a longer phrase.';
    }
    final hash = spokenPhrase.trim().toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('voice_enabled', true);
    await prefs.setString('voice_pin', hash);
    _voiceEnabled = true;
    _voicePin     = hash;
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

  /// Verify a spoken phrase against the stored passphrase.
  Future<String?> signInWithVoice(String spokenPhrase) async {
    if (!_voiceEnabled || _voicePin == null) {
      return 'Voice login is not set up.';
    }
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

  // ═══════════════════════════════════════════════════════════════════════════
  // STANDARD AUTH
  // ═══════════════════════════════════════════════════════════════════════════

  Future<String?> signIn(String email, String password) async {
    try {
      await SupabaseService.client.auth.signInWithPassword(
        email: email, password: password);
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
        email: email, password: password);
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
      await SupabaseService.client.auth.resetPasswordForEmail(email);
      return null;
    } on AuthException catch (e) {
      return e.message;
    }
  }
}