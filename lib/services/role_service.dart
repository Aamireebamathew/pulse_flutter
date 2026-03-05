// role_service.dart
// Equivalent of useRole() React hook
// Usage: final role = await RoleService.getRole();

import 'package:supabase_flutter/supabase_flutter.dart';

class RoleService {
  static final _client = Supabase.instance.client;

  /// Fetches the current user's role from the profiles table.
  /// Returns null if not logged in or no role set.
  static Future<String?> getRole() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    try {
      final data = await _client
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .single();
      return data['role'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// Stream version — re-emits whenever auth state changes.
  static Stream<String?> roleStream() async* {
    final user = _client.auth.currentUser;
    if (user == null) { yield null; return; }
    try {
      final data = await _client
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .single();
      yield data['role'] as String?;
    } catch (_) {
      yield null;
    }
  }
}