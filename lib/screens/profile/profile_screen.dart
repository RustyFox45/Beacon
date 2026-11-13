import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../utils/ui_utils.dart';
import 'edit_profile_screen.dart';
import 'terms_of_service_screen.dart';
import 'privacy_policy_screen.dart';
import '../../theme/theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('PROFILE'),
      ),
      body: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height -
                MediaQuery.of(context).padding.top -
                kToolbarHeight,
          ),
          child: IntrinsicHeight(
            child: Column(
              children: [
                _ProfileHero(
                  name: user.name,
                  profilePictureUrl: user.profilePictureUrl,
                ),
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: _ProfileInfoCard(
                    phoneNumber: user.phoneNumber,
                    email: user.email,
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: _ProfileMenuCard(),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EditProfileScreen(),
                          ),
                        );
                      },
                      child: const Text('EDIT PROFILE'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  final String name;
  final String profilePictureUrl;

  const _ProfileHero({
    required this.name,
    required this.profilePictureUrl,
  });

  static const double _avatarRadius = 52.0;
  static const double _avatarOverlap = 36.0;
  static const double _bannerHeight = 120.0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              height: _bannerHeight,
              color: AppColors.primaryDarkTeal,
            ),
            Positioned(
              bottom: -_avatarOverlap,
              child: _ProfileAvatar(
                radius: _avatarRadius,
                profilePictureUrl: profilePictureUrl,
              ),
            ),
          ],
        ),
        SizedBox(height: _avatarOverlap + 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Text(
            name.isEmpty ? '—' : name,
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  final double radius;
  final String profilePictureUrl;

  const _ProfileAvatar({
    required this.radius,
    required this.profilePictureUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.backgroundTint,
          width: 4,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey[300],
        backgroundImage: UiUtils.getAvatarProvider(profilePictureUrl),
        child: profilePictureUrl.isEmpty
            ? AppIcons.profile(size: radius, color: Colors.grey)
            : null,
      ),
    );
  }
}

class _ProfileInfoCard extends StatelessWidget {
  final String phoneNumber;
  final String email;

  const _ProfileInfoCard({
    required this.phoneNumber,
    required this.email,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryMidTeal.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          _InfoRow(
            icon: Icons.phone_outlined,
            value: phoneNumber.isEmpty ? '—' : phoneNumber,
          ),
          Divider(
            height: 1,
            color: AppColors.primaryMidTeal.withValues(alpha: 0.08),
          ),
          _InfoRow(
            icon: Icons.email_outlined,
            value: email.isEmpty ? '—' : email,
          ),
        ],
      ),
    );
  }
}

class _ProfileMenuCard extends StatelessWidget {
  const _ProfileMenuCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryMidTeal.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          _MenuRow(
            label: 'Terms of Service',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const TermsOfServiceScreen(),
              ),
            ),
          ),
          Divider(
            height: 1,
            color: AppColors.primaryMidTeal.withValues(alpha: 0.08),
          ),
          _MenuRow(
            label: 'Privacy Policy',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const PrivacyPolicyScreen(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _MenuRow({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14.0),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ),
            AppIcons.chevronRight(size: 18, color: AppColors.primaryMidTeal),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14.0),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: AppColors.primaryMidTeal,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
