import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _loading = true;

  User? get user => _user;
  bool get loading => _loading;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    _init();
  }

  void _init() {
    _user = SupabaseService.currentUser;
    _loading = false;

    SupabaseService.authStateChanges.listen((data) {
      _user = data.session?.user;
      notifyListeners();
    });
  }

  Future<String?> signIn(String email, String password) async {
    try {
      await SupabaseService.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
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
      await SupabaseService.client.auth.resetPasswordForEmail(email);
      return null;
    } on AuthException catch (e) {
      return e.message;
    }
  }
}
