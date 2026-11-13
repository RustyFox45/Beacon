import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  Session? _session;
  String? _pendingVerificationEmail;
  bool _hasSignedOut = false;
  late final StreamSubscription<AuthState> _authSubscription;

  AuthProvider() {
    _session = SupabaseService.currentSession;
    _authSubscription = SupabaseService.authStateChanges.listen((authState) {
      _session = authState.session;
      notifyListeners();
    });
  }

  bool get isAuthenticated => _session != null;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Session? get session => _session;
  User? get currentUser => _session?.user;
  String? get pendingVerificationEmail => _pendingVerificationEmail;
  bool get hasSignedOut => _hasSignedOut;

  Future<void> signUp({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await SupabaseService.signUp(email: email, password: password);
      _pendingVerificationEmail = email;
    } on AuthException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'An unexpected error occurred. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> verifyOTP({
    required String email,
    required String token,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await SupabaseService.verifyOTP(email: email, token: token);
      _pendingVerificationEmail = null;
    } on AuthException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Verification failed. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> resendOTP({required String email}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await SupabaseService.resendSignUpOTP(email: email);
    } on AuthException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Failed to resend code. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await SupabaseService.signIn(email: email, password: password);
      _session = response.session;
    } on AuthException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'An unexpected error occurred. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await SupabaseService.resetPasswordForEmail(email);
      _pendingVerificationEmail = email;
    } on AuthException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'An unexpected error occurred. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> verifyRecoveryOTP({
    required String email,
    required String token,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await SupabaseService.verifyRecoveryOTP(email: email, token: token);
      return true;
    } on AuthException catch (e) {
      _error = e.message;
      return false;
    } catch (e) {
      _error = 'Verification failed. Please try again.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updatePassword(String newPassword) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await SupabaseService.updatePassword(newPassword);
      return true;
    } on AuthException catch (e) {
      _error = e.message;
      return false;
    } catch (e) {
      _error = 'Failed to update password. Please try again.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    _isLoading = true;
    _hasSignedOut = true;
    notifyListeners();

    try {
      await SupabaseService.signOut();
    } on AuthException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Failed to sign out. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }
}
