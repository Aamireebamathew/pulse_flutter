// Stub file for web/desktop — local_auth is Android/iOS only.
// auth_provider.dart imports this file on non-mobile platforms via
// conditional import:
//   import 'package:local_auth/local_auth.dart'
//       if (dart.library.html) '../utils/local_auth_stub.dart';

class LocalAuthentication {
  Future<bool> get canCheckBiometrics async => false;
  Future<bool> isDeviceSupported() async => false;
  Future<List<BiometricType>> getAvailableBiometrics() async => [];
  Future<bool> authenticate({
    required String localizedReason,
    AuthenticationOptions options = const AuthenticationOptions(),
  }) async =>
      false;
}

class AuthenticationOptions {
  final bool biometricOnly;
  final bool stickyAuth;
  const AuthenticationOptions({
    this.biometricOnly = false,
    this.stickyAuth = false,
  });
}

enum BiometricType { face, fingerprint, iris, strong, weak }