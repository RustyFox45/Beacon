import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/group_provider.dart';
import '../providers/lesson_provider.dart';
import '../providers/user_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/home_screen.dart';

class AuthGate extends StatefulWidget {
  final bool showLoginFirst;

  const AuthGate({super.key, this.showLoginFirst = false});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _profileLoadTriggered = false;
  bool _dataLoadTriggered = false;

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final userProvider = context.watch<UserProvider>();

    if (!authProvider.isAuthenticated) {
      _profileLoadTriggered = false;
      _dataLoadTriggered = false;
      final showLogin = widget.showLoginFirst || authProvider.hasSignedOut;
      return showLogin ? const LoginScreen() : const SignUpScreen();
    }

    if (!_profileLoadTriggered) {
      _profileLoadTriggered = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final userId = authProvider.currentUser!.id;
        userProvider.loadProfile(userId);
      });
    }

    if (userProvider.isLoading || !userProvider.hasProfile) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: Colors.black)),
      );
    }

    if (!_dataLoadTriggered) {
      _dataLoadTriggered = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<GroupProvider>().loadGroups();
        context.read<LessonProvider>().loadLessons();
      });
    }

    return const HomeScreen();
  }
}
