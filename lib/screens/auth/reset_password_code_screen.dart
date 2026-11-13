import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/theme.dart';
import '../../widgets/otp_input_row.dart';
import 'reset_password_screen.dart';

class ResetPasswordCodeScreen extends StatefulWidget {
  final String email;

  const ResetPasswordCodeScreen({super.key, required this.email});

  @override
  State<ResetPasswordCodeScreen> createState() =>
      _ResetPasswordCodeScreenState();
}

class _ResetPasswordCodeScreenState extends State<ResetPasswordCodeScreen> {
  final _otpKey = GlobalKey<OtpInputRowState>();

  int _resendCooldown = 0;
  Timer? _cooldownTimer;
  bool _isVerifying = false;

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  Future<void> _submitCode(String code) async {
    if (_isVerifying) return;
    if (code.length != 6) return;

    setState(() => _isVerifying = true);

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.verifyRecoveryOTP(
      email: widget.email,
      token: code,
    );

    if (!mounted) return;

    if (!success) {
      if (authProvider.error != null) {
        _showError(authProvider.error!);
        authProvider.clearError();
      }
      _otpKey.currentState?.clear();
      setState(() => _isVerifying = false);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ResetPasswordScreen()),
    );
    setState(() => _isVerifying = false);
  }

  void _startResendCooldown() {
    setState(() => _resendCooldown = 60);
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _resendCooldown--;
        if (_resendCooldown <= 0) {
          timer.cancel();
        }
      });
    });
  }

  Future<void> _handleResend() async {
    if (_resendCooldown > 0) return;

    final authProvider = context.read<AuthProvider>();
    await authProvider.sendPasswordResetEmail(widget.email);

    if (!mounted) return;

    if (authProvider.error != null) {
      _showError(authProvider.error!);
      authProvider.clearError();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification code resent.')),
      );
      _startResendCooldown();
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primaryDarkTeal,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 34),
            child: Column(
              children: [
                const SizedBox(height: 170),
                Text(
                  'Reset Password',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: 16),
                Text(
                  'Enter the 6-digit code to reset your password',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 20),
                OtpInputRow(key: _otpKey, onCompleted: _submitCode),
                const SizedBox(height: 24),
                _buildResendRow(),
                const SizedBox(height: 40),
                _buildUseDifferentEmailLink(),
                if (_isVerifying) ...[
                  const SizedBox(height: 32),
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.beaconYellow,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResendRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("Didn't get a code? ", style: Theme.of(context).textTheme.bodySmall),
        GestureDetector(
          onTap: _resendCooldown > 0 ? null : _handleResend,
          child: Text(
            _resendCooldown > 0 ? 'Resend (${_resendCooldown}s)' : 'Resend',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: _resendCooldown > 0
                  ? AppColors.neutralCharcoal
                  : AppColors.accentCyan,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUseDifferentEmailLink() {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Text(
        '\u2190 Use a different email',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.accentCyan,
        ),
      ),
    );
  }
}
