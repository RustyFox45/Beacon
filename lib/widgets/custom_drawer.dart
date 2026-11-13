import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/group_provider.dart';
import '../providers/lesson_provider.dart';
import '../providers/user_provider.dart';
import '../screens/home_screen.dart';
import '../screens/groups/groups_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../widgets/auth_gate.dart';
import '../theme/theme.dart';
import '../utils/ui_utils.dart';
import 'beacon_icon.dart';

class CustomDrawer extends StatelessWidget {
  final String? activeRoute;

  const CustomDrawer({super.key, this.activeRoute});

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final user = userProvider.currentUser;

    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.drawerGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Branded Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const BeaconIcon(
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'BEACON',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4.0,
                        color: AppColors.beaconYellow,
                        fontFamily: 'Serif',
                      ),
                    ),
                    Text(
                      'GOSPEL STUDY',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2.0,
                        color: AppColors.accentLightBlue.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 48),
                    // User Profile area — tappable to navigate to profile
                    InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ProfileScreen()),
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.white.withOpacity(0.1),
                              backgroundImage: UiUtils.getAvatarProvider(user.profilePictureUrl),
                              child: user.profilePictureUrl.isEmpty
                                  ? Text(
                                      user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.name.isNotEmpty ? user.name : 'Unknown User',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    user.email,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.accentLightBlue.withOpacity(0.8),
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Navigation Items
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _buildNavItem(
                      context,
                      icon: Icons.home_rounded,
                      title: 'HOME',
                      isActive: activeRoute == 'home',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const HomeScreen()),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildNavItem(
                      context,
                      icon: Icons.group_rounded,
                      title: 'GROUPS',
                      isActive: activeRoute == 'groups',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const GroupsScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Logout Footer
              Padding(
                padding: const EdgeInsets.all(24),
                child: _buildNavItem(
                  context,
                  icon: Icons.logout_rounded,
                  title: 'SIGN OUT',
                  isDestructive: true,
                  onTap: () async {
                    Navigator.pop(context);
                    context.read<UserProvider>().clear();
                    context.read<GroupProvider>().clear();
                    context.read<LessonProvider>().clear();
                    await context.read<AuthProvider>().signOut();
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (_) => const AuthGate(showLoginFirst: true),
                        ),
                        (route) => false,
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isActive = false,
    bool isDestructive = false,
  }) {
    final color = isDestructive
        ? Colors.redAccent.shade100
        : (isActive ? AppColors.beaconYellow : AppColors.accentLightBlue.withOpacity(0.9));

    final bgColor = isActive ? Colors.white.withOpacity(0.08) : Colors.transparent;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: isActive
            ? Border.all(color: AppColors.beaconYellow.withOpacity(0.2), width: 1)
            : null,
      ),
      child: ListTile(
        dense: true,
        visualDensity: VisualDensity.compact,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(icon, color: color, size: 20),
        title: Text(
          title,
          style: TextStyle(
            color: color,
            fontSize: 13,
            letterSpacing: 1.5,
            fontWeight: isActive || isDestructive ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
