import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  // Replace with your actual Supabase project credentials
  static const String supabaseUrl = 'https://kopcskriuotewlscrmsz.supabase.co';
  static const String supabaseAnonKey = 'sb_publishable_dunWt3m5WwL8_LhYjArpwQ_t0oofQ7K';

  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  // Auth
  static User? get currentUser => client.auth.currentUser;

  static Stream<AuthState> get authStateChanges =>
      client.auth.onAuthStateChange;

  // Objects
  static Future<List<Map<String, dynamic>>> getObjects(String userId) async {
    final response = await client
        .from('objects')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<void> addObject({
    required String userId,
    required String objectName,
    required String usualLocation,
    required String objectId,
    String imageUrl = '',
  }) async {
    await client.from('objects').insert({
      'user_id': userId,
      'object_name': objectName,
      'usual_location': usualLocation,
      'object_id': objectId,
      'image_url': imageUrl,
    });

    await client.from('activity_logs').insert({
      'user_id': userId,
      'activity_type': 'registered',
      'location': usualLocation,
      'confidence': 1.0,
      'metadata': {'object_name': objectName},
    });
  }

  static Future<void> deleteObject(String id) async {
    await client.from('objects').delete().eq('id', id);
  }

  // Activity Logs
  static Future<List<Map<String, dynamic>>> getActivityLogs(
    String userId, {
    int limit = 50,
    DateTime? since,
  }) async {
    if (since != null && limit > 0) {
      final r = await client
          .from('activity_logs')
          .select()
          .eq('user_id', userId)
          .gte('created_at', since.toIso8601String())
          .order('created_at', ascending: false)
          .limit(limit);
      return List<Map<String, dynamic>>.from(r);
    } else if (since != null) {
      final r = await client
          .from('activity_logs')
          .select()
          .eq('user_id', userId)
          .gte('created_at', since.toIso8601String())
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(r);
    } else if (limit > 0) {
      final r = await client
          .from('activity_logs')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);
      return List<Map<String, dynamic>>.from(r);
    } else {
      final r = await client
          .from('activity_logs')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(r);
    }
  }

  // User Preferences
  static Future<Map<String, dynamic>?> getUserPreferences(
      String userId) async {
    final response = await client
        .from('user_preferences')
        .select()
        .eq('user_id', userId)
        .maybeSingle();
    return response;
  }

  static Future<void> updateUserPreferences(
    String userId,
    Map<String, dynamic> preferences,
  ) async {
    await client
        .from('user_preferences')
        .update(preferences)
        .eq('user_id', userId);
  }

  // Image upload
  static Future<String> uploadObjectImage(
      String userId, Uint8List bytes, String ext) async {
    final fileName = '$userId/${DateTime.now().millisecondsSinceEpoch}.$ext';
    await client.storage.from('object-images').uploadBinary(
          fileName,
          bytes,
        );
    return client.storage.from('object-images').getPublicUrl(fileName);
  }
}