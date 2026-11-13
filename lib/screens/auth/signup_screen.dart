import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/dismiss_keyboard.dart';
import 'login_screen.dart';
import 'terms_of_service_screen.dart';
import 'privacy_policy_screen.dart';
import 'verify_email_screen.dart';
import '../../theme/theme.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();
  bool _agreedToTerms = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      _showError('Please fill in all fields.');
      return;
    }

    final emailRegex = RegExp(r'^[\w\.\+\-]+@[\w\-]+\.[\w\-]{2,}$');
    if (!emailRegex.hasMatch(email)) {
      _showError('Please enter a valid email address.');
      return;
    }

    if (password != confirmPassword) {
      _showError('Passwords do not match.');
      return;
    }

    if (!_agreedToTerms) {
      _showError('You must agree to the Terms of Service and Privacy Policy.');
      return;
    }

    final authProvider = context.read<AuthProvider>();
    await authProvider.signUp(email: email, password: password);

    if (!mounted) return;

    if (authProvider.error == null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => VerifyEmailScreen(email: email)),
      );
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

    if (authProvider.error != null) {
      final errorMessage = authProvider.error!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _showError(errorMessage);
        authProvider.clearError();
      });
    }

    return DismissKeyboard(
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 120),
                  Center(
                    child: Text(
                      'Create Account',
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                  ),
                  const SizedBox(height: 60),
                  _buildLabel('Email'),
                  const SizedBox(height: 4),
                  _buildTextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    focusNode: _emailFocus,
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) => _passwordFocus.requestFocus(),
                  ),
                  const SizedBox(height: 20),
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
                          ? AppIcons.visibilityOff(size: 20, color: AppColors.neutralCharcoal)
                          : AppIcons.visibility(size: 20, color: AppColors.neutralCharcoal),
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
                    onSubmitted: (_) => _handleSignUp(),
                    suffixIcon: IconButton(
                      icon: _obscureConfirmPassword
                          ? AppIcons.visibilityOff(size: 20, color: AppColors.neutralCharcoal)
                          : AppIcons.visibility(size: 20, color: AppColors.neutralCharcoal),
                      onPressed: () => setState(
                        () =>
                            _obscureConfirmPassword = !_obscureConfirmPassword,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildTermsRow(),
                  const SizedBox(height: 20),
                  _buildSignUpButton(authProvider.isLoading),
                  const SizedBox(height: 16),
                  _buildLoginLink(),
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
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
    FocusNode? focusNode,
    TextInputAction? textInputAction,
    ValueChanged<String>? onSubmitted,
  }) {
    return SizedBox(
      height: 48,
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
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
            borderSide: const BorderSide(color: AppColors.neutralCharcoal, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: AppColors.neutralCharcoal, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: AppColors.primaryMidTeal, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildTermsRow() {
    final labelStyle = Theme.of(context).textTheme.labelSmall;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 20,
          height: 20,
          child: Checkbox(
            value: _agreedToTerms,
            onChanged: (value) {
              setState(() {
                _agreedToTerms = value ?? false;
              });
            },
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(2),
            ),
            side: const BorderSide(color: AppColors.neutralCharcoal, width: 1),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: labelStyle,
              children: [
                const TextSpan(text: 'I agree to the '),
                TextSpan(
                  text: 'Terms of Service',
                  style: labelStyle?.copyWith(color: AppColors.accentCyan),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TermsOfServiceScreen(),
                        ),
                      );
                    },
                ),
                const TextSpan(text: ' and '),
                TextSpan(
                  text: 'Privacy Policy',
                  style: labelStyle?.copyWith(color: AppColors.accentCyan),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PrivacyPolicyScreen(),
                        ),
                      );
                    },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignUpButton(bool isLoading) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: isLoading ? null : _handleSignUp,
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.beaconYellow,
                ),
              )
            : const Text('Sign up'),
      ),
    );
  }

  Widget _buildLoginLink() {
    final labelStyle = Theme.of(context).textTheme.labelSmall;
    return Center(
      child: RichText(
        text: TextSpan(
          style: labelStyle,
          children: [
            const TextSpan(text: 'Already have an account? '),
            TextSpan(
              text: 'Log in',
              style: labelStyle?.copyWith(color: AppColors.accentCyan),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
            ),
          ],
        ),
      ),
    );
  }
}
