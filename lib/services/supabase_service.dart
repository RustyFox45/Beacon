import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user.dart' as app_models;

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;
  static GoTrueClient get auth => client.auth;

  // Returns the Supabase auth user (not our app User model)
  static User? get currentAuthUser => auth.currentUser;
  static String? get currentUserId => auth.currentUser?.id;
  static Session? get currentSession => auth.currentSession;
  static Stream<AuthState> get authStateChanges => auth.onAuthStateChange;

  static Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) {
    return auth.signUp(email: email, password: password);
  }

  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return auth.signInWithPassword(email: email, password: password);
  }

  static Future<AuthResponse> verifyOTP({
    required String email,
    required String token,
  }) {
    return auth.verifyOTP(
      email: email,
      token: token,
      type: OtpType.signup,
    );
  }

  static Future<ResendResponse> resendSignUpOTP({
    required String email,
  }) {
    return auth.resend(
      type: OtpType.signup,
      email: email,
    );
  }

  static Future<void> resetPasswordForEmail(String email) {
    return auth.resetPasswordForEmail(email);
  }

  static Future<AuthResponse> verifyRecoveryOTP({
    required String email,
    required String token,
  }) {
    return auth.verifyOTP(
      email: email,
      token: token,
      type: OtpType.recovery,
    );
  }

  static Future<UserResponse> updatePassword(String newPassword) {
    return auth.updateUser(UserAttributes(password: newPassword));
  }

  static Future<void> signOut() {
    return auth.signOut();
  }

  static Future<Map<String, dynamic>?> getProfile(String userId) async {
    final response = await client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    return response;
  }

  static Future<void> updateProfile({
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    await client.from('profiles').update(data).eq('id', userId);
  }

  static Future<List<app_models.User>> searchUsers(String query) async {
    if (query.trim().isEmpty) return [];
    final response = await client
        .from('profiles')
        .select()
        .or('name.ilike.%$query%,email.ilike.%$query%')
        .limit(20);
    return response
        .map<app_models.User>((row) => app_models.User.fromMap(row))
        .toList();
  }

  static Future<String> uploadAvatar(String userId, String filePath) async {
    final file = File(filePath);
    final ext = filePath.split('.').last;
    final path = '$userId/avatar.$ext';
    await client.storage.from('avatars').upload(
      path,
      file,
      fileOptions: const FileOptions(upsert: true),
    );
    final url = client.storage.from('avatars').getPublicUrl(path);
    return '$url?t=${DateTime.now().millisecondsSinceEpoch}';
  }

  static Future<String> uploadGroupPhoto(
    String groupId,
    String filePath,
  ) async {
    final file = File(filePath);
    final ext = filePath.split('.').last;
    final path = '$groupId/photo.$ext';
    await client.storage.from('group-photos').upload(
      path,
      file,
      fileOptions: const FileOptions(upsert: true),
    );
    return client.storage.from('group-photos').getPublicUrl(path);
  }
}
