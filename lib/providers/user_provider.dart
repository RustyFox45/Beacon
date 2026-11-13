import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/supabase_service.dart';

class UserProvider extends ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  String? _error;

  User get currentUser => _currentUser ?? User(id: '', name: '', email: '');
  bool get isLoading => _isLoading;
  bool get hasProfile => _currentUser != null;
  String? get error => _error;

  Future<void> loadProfile(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await SupabaseService.getProfile(userId);
      if (data != null) {
        _currentUser = User.fromMap(data);
      } else {
        _error = 'Profile not found.';
      }
    } catch (e) {
      _error = 'Failed to load profile.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile({
    String? name,
    String? phoneNumber,
    String? email,
    String? profilePictureUrl,
  }) async {
    if (_currentUser == null) return;

    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (phoneNumber != null) updates['phone_number'] = phoneNumber;
    if (email != null) updates['email'] = email;
    if (profilePictureUrl != null) {
      updates['profile_picture_url'] = profilePictureUrl;
    }

    if (updates.isEmpty) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await SupabaseService.updateProfile(
        userId: _currentUser!.id,
        data: updates,
      );
      _currentUser = _currentUser!.copyWith(
        name: name,
        phoneNumber: phoneNumber,
        email: email,
        profilePictureUrl: profilePictureUrl,
      );
    } catch (e) {
      _error = 'Failed to update profile.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clear() {
    _currentUser = null;
    _error = null;
    notifyListeners();
  }
}
