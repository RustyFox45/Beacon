import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/theme.dart';
import '../../widgets/dismiss_keyboard.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _passwordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (password.isEmpty || confirmPassword.isEmpty) {
      _showError('Please fill in all fields.');
      return;
    }

    if (password.length < 6) {
      _showError('Password must be at least 6 characters.');
      return;
    }

    if (password != confirmPassword) {
      _showError('Passwords do not match.');
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.updatePassword(password);

    if (!mounted) return;

    if (success) {
      await authProvider.signOut();
      if (!mounted) return;

      Navigator.of(context).popUntil((route) => route.isFirst);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Password reset successfully. Please log in.',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: AppColors.primaryDarkTeal,
        ),
      );
    } else if (authProvider.error != null) {
      final error = authProvider.error!;
      authProvider.clearError();

      if (error.toLowerCase().contains('session') ||
          error.toLowerCase().contains('expired') ||
          error.toLowerCase().contains('not authenticated')) {
        _showError('Session expired. Please start over.');
        await Future.delayed(const Duration(seconds: 2));
        if (!mounted) return;
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        _showError(error);
      }
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

    return DismissKeyboard(
      child: Scaffold(
        appBar: AppBar(),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 60),
                  Center(
                    child: Text(
                      'Reset Password',
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      'Enter a new password',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  const SizedBox(height: 40),
                  _buildLabel('Password'),
                  const SizedBox(height: 4),
                  _buildTextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    focusNode: _passwordFocus,
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) => _confirmPasswordFocus.requestFocus(),
                    suffixIcon: IconButton(
                      icon: _obscurePassword
                          ? AppIcons.visibilityOff(
                              size: 20,
                              color: AppColors.neutralCharcoal,
                            )
                          : AppIcons.visibility(
                              size: 20,
                              color: AppColors.neutralCharcoal,
                            ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildLabel('Confirm password'),
                  const SizedBox(height: 4),
                  _buildTextField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    focusNode: _confirmPasswordFocus,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _handleResetPassword(),
                    suffixIcon: IconButton(
                      icon: _obscureConfirmPassword
                          ? AppIcons.visibilityOff(
                              size: 20,
                              color: AppColors.neutralCharcoal,
                            )
                          : AppIcons.visibility(
                              size: 20,
                              color: AppColors.neutralCharcoal,
                            ),
                      onPressed: () => setState(
                        () =>
                            _obscureConfirmPassword = !_obscureConfirmPassword,
                      ),
                    ),
                  ),
                  const SizedBox(height: 130),
                  _buildContinueButton(authProvider.isLoading),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 13),
      child: Text(text, style: Theme.of(context).textTheme.bodySmall),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    bool obscureText = false,
    FocusNode? focusNode,
    TextInputAction? textInputAction,
    ValueChanged<String>? onSubmitted,
    Widget? suffixIcon,
  }) {
    return SizedBox(
      height: 48,
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        focusNode: focusNode,
        textInputAction: textInputAction,
        onSubmitted: onSubmitted,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(
              color: AppColors.neutralCharcoal,
              width: 1,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(
              color: AppColors.neutralCharcoal,
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(
              color: AppColors.primaryMidTeal,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContinueButton(bool isLoading) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: isLoading ? null : _handleResetPassword,
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.beaconYellow,
                ),
              )
            : const Text('Continue'),
      ),
    );
  }
}
