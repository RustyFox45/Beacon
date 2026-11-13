import 'package:flutter/material.dart';
import '../../theme/theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('PRIVACY POLICY'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Effective date: March 18, 2026', style: textTheme.bodySmall),
            const SizedBox(height: 24),
            _Section(
              title: '1. Introduction',
              body:
                  'Gospel Beacon ("we", "our", or "us") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use the Gospel Beacon mobile application ("the App"). Please read this policy carefully.',
            ),
            _Section(
              title: '2. Information We Collect',
              body:
                  'We may collect the following types of information:\n\n'
                  '• Account Information: Your name, email address, and phone number when you register.\n'
                  '• Profile Information: A profile picture you choose to upload.\n'
                  '• User Content: Lesson plans, group data, and other content you create within the App.\n'
                  '• Usage Data: Information about how you interact with the App, such as features used and actions taken.\n'
                  '• Device Information: Device type, operating system version, and unique device identifiers.',
            ),
            _Section(
              title: '3. How We Use Your Information',
              body:
                  'We use the information we collect to:\n\n'
                  '• Provide, operate, and maintain the App.\n'
                  '• Create and manage your account.\n'
                  '• Enable collaboration features such as group membership and lesson sharing.\n'
                  '• Communicate with you about updates, support, and account-related matters.\n'
                  '• Improve the App through analytics and usage patterns.\n'
                  '• Comply with legal obligations.',
            ),
            _Section(
              title: '4. Sharing of Information',
              body:
                  'We do not sell your personal information. We may share your information in the following limited circumstances:\n\n'
                  '• With other group members when you join or create a group within the App, as required for collaboration features.\n'
                  '• With service providers who assist us in operating the App (e.g., cloud storage, analytics), under confidentiality agreements.\n'
                  '• If required by law or in response to valid legal process.\n'
                  '• In connection with a merger, acquisition, or sale of assets, with appropriate notice to you.',
            ),
            _Section(
              title: '5. Data Storage and Security',
              body:
                  'Your data is stored using Supabase, a secure cloud database platform. We implement industry-standard security measures including encryption in transit (TLS) and at rest. However, no method of transmission over the internet is 100% secure, and we cannot guarantee absolute security.',
            ),
            _Section(
              title: '6. Data Retention',
              body:
                  'We retain your personal information for as long as your account is active or as needed to provide the service. You may request deletion of your account and associated data at any time by contacting us at support@gospelbeacon.app.',
            ),
            _Section(
              title: '7. Children\'s Privacy',
              body:
                  'The App is not directed to children under the age of 13. We do not knowingly collect personal information from children under 13. If we become aware that a child under 13 has provided us with personal information, we will take steps to delete such information.',
            ),
            _Section(
              title: '8. Your Rights',
              body:
                  'Depending on your location, you may have the right to:\n\n'
                  '• Access the personal information we hold about you.\n'
                  '• Request correction of inaccurate data.\n'
                  '• Request deletion of your personal data.\n'
                  '• Object to or restrict certain processing of your data.\n\n'
                  'To exercise any of these rights, contact us at support@gospelbeacon.app.',
            ),
            _Section(
              title: '9. Third-Party Services',
              body:
                  'The App may use third-party services such as Google Fonts and image hosting providers. These services have their own privacy policies, and we encourage you to review them. We are not responsible for the privacy practices of third-party services.',
            ),
            _Section(
              title: '10. Changes to This Policy',
              body:
                  'We may update this Privacy Policy from time to time. We will notify you of any material changes by updating the "Last updated" date at the top of this page. Your continued use of the App after such changes constitutes your acceptance of the updated policy.',
            ),
            _Section(
              title: '11. Contact Us',
              body:
                  'If you have any questions or concerns about this Privacy Policy, please contact us at:\n\nsupport@gospelbeacon.app',
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String body;

  const _Section({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: textTheme.titleSmall?.copyWith(
              color: AppColors.primaryDarkTeal,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(body, style: textTheme.bodyMedium),
        ],
      ),
    );
  }
}
