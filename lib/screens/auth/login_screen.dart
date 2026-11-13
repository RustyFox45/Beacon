import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/dismiss_keyboard.dart';
import 'forgot_password_screen.dart';
import 'signup_screen.dart';
import '../../theme/theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  bool _rememberMe = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _loadRememberedEmail();
  }

  Future<void> _loadRememberedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final remembered = prefs.getBool('remember_me') ?? false;
    final email = prefs.getString('remembered_email') ?? '';
    if (remembered && email.isNotEmpty) {
      setState(() {
        _rememberMe = true;
        _emailController.text = email;
      });
    }
  }

  Future<void> _saveRememberMe(String email) async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setBool('remember_me', true);
      await prefs.setString('remembered_email', email);
    } else {
      await prefs.remove('remember_me');
      await prefs.remove('remembered_email');
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showError('Please fill in all fields.');
      return;
    }

    final authProvider = context.read<AuthProvider>();
    await authProvider.signIn(email: email, password: password);

    if (!mounted) return;

    if (authProvider.error == null && authProvider.isAuthenticated) {
      await _saveRememberMe(email);
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
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
                  const SizedBox(height: 170),
                  Center(
                    child: Text(
                      'Welcome back',
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
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _handleLogin(),
                    suffixIcon: IconButton(
                      icon: _obscurePassword
                          ? AppIcons.visibilityOff(size: 20, color: AppColors.neutralCharcoal)
                          : AppIcons.visibility(size: 20, color: AppColors.neutralCharcoal),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildRememberForgotRow(),
                  const SizedBox(height: 56),
                  _buildLoginButton(authProvider.isLoading),
                  const SizedBox(height: 16),
                  _buildSignUpLink(),
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

  Widget _buildRememberForgotRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: Checkbox(
                value: _rememberMe,
                onChanged: (value) {
                  setState(() {
                    _rememberMe = value ?? false;
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
            const SizedBox(width: 6),
            Text(
              'Remember me',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
            );
          },
          child: Text(
            'Forgot password?',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.accentCyan,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton(bool isLoading) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: isLoading ? null : _handleLogin,
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.beaconYellow,
                ),
              )
            : const Text('Login'),
      ),
    );
  }

  Widget _buildSignUpLink() {
    final labelStyle = Theme.of(context).textTheme.labelSmall;
    return Center(
      child: RichText(
        text: TextSpan(
          style: labelStyle,
          children: [
            const TextSpan(text: "Don't have an account? "),
            TextSpan(
              text: 'Sign up',
              style: labelStyle?.copyWith(color: AppColors.accentCyan),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SignUpScreen()),
                  );
                },
            ),
          ],
        ),
      ),
    );
  }
}
