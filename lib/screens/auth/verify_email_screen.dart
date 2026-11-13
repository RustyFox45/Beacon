import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/theme.dart';
import '../../widgets/otp_input_row.dart';

class VerifyEmailScreen extends StatefulWidget {
  final String email;

  const VerifyEmailScreen({super.key, required this.email});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _otpKey = GlobalKey<OtpInputRowState>();

  int _resendCooldown = 0;
  Timer? _cooldownTimer;
  bool _isVerifying = false;
  bool _hasNavigated = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkAuthAndNavigate();
  }

  void _checkAuthAndNavigate() {
    if (_hasNavigated) return;
    final authProvider = context.read<AuthProvider>();
    if (authProvider.isAuthenticated) {
      _hasNavigated = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      });
    }
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  Future<void> _submitCode(String code) async {
    if (_isVerifying || _hasNavigated) return;
    if (code.length != 6) return;

    setState(() => _isVerifying = true);

    final authProvider = context.read<AuthProvider>();
    await authProvider.verifyOTP(email: widget.email, token: code);

    if (!mounted) return;

    if (authProvider.error != null) {
      _showError(authProvider.error!);
      authProvider.clearError();
      _otpKey.currentState?.clear();
      setState(() => _isVerifying = false);
      return;
    }

    if (authProvider.isAuthenticated) {
      _hasNavigated = true;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      setState(() => _isVerifying = false);
    }
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
    await authProvider.resendOTP(email: widget.email);

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
    final authProvider = context.watch<AuthProvider>();
    if (authProvider.isAuthenticated && !_hasNavigated) {
      _hasNavigated = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      });
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 34),
            child: Column(
              children: [
                const SizedBox(height: 120),
                Text(
                  'Verify your email',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: 16),
                Text(
                  'We sent a verification code to your email',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 36),
                OtpInputRow(key: _otpKey, onCompleted: _submitCode),
                const SizedBox(height: 24),
                _buildResendRow(),
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
}
