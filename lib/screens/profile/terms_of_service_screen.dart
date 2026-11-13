import 'package:flutter/material.dart';
import '../../theme/theme.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('TERMS OF SERVICE'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Effective date: March 18, 2026', style: textTheme.bodySmall),
            const SizedBox(height: 24),
            _Section(
              title: '1. Acceptance of Terms',
              body:
                  'By downloading, installing, or using Gospel Beacon ("the App"), you agree to be bound by these Terms of Service ("Terms"). If you do not agree to these Terms, do not use the App.',
            ),
            _Section(
              title: '2. Description of Service',
              body:
                  'Gospel Beacon is a lesson planning and group coordination tool designed to help individuals and organizations prepare and share gospel-centered lesson content. The App allows users to create, edit, and share lesson plans, manage groups, and collaborate with other members.',
            ),
            _Section(
              title: '3. User Accounts',
              body:
                  'You must create an account to use certain features of the App. You are responsible for maintaining the confidentiality of your account credentials and for all activity that occurs under your account. You agree to notify us immediately of any unauthorized use of your account.',
            ),
            _Section(
              title: '4. User Content',
              body:
                  'You retain ownership of any content you create within the App, including lesson plans and group materials ("User Content"). By submitting User Content, you grant Gospel Beacon a non-exclusive, royalty-free license to store and display that content solely for the purpose of providing the service to you and your group members.',
            ),
            _Section(
              title: '5. Acceptable Use',
              body:
                  'You agree not to use the App to:\n\n'
                  '• Upload or share content that is unlawful, harmful, threatening, abusive, harassing, defamatory, or otherwise objectionable.\n'
                  '• Impersonate any person or entity or falsely state your affiliation with any person or entity.\n'
                  '• Interfere with or disrupt the integrity or performance of the App or its servers.\n'
                  '• Attempt to gain unauthorized access to any portion of the App or its related systems.',
            ),
            _Section(
              title: '6. Intellectual Property',
              body:
                  'The App and its original content (excluding User Content), features, and functionality are and will remain the exclusive property of Gospel Beacon and its licensors. You may not copy, modify, distribute, or create derivative works based on the App without our express written permission.',
            ),
            _Section(
              title: '7. Termination',
              body:
                  'We reserve the right to suspend or terminate your account and access to the App at our sole discretion, without notice, for conduct that we believe violates these Terms or is harmful to other users, us, or third parties.',
            ),
            _Section(
              title: '8. Disclaimer of Warranties',
              body:
                  'The App is provided on an "as is" and "as available" basis without warranties of any kind, either express or implied. We do not warrant that the App will be uninterrupted, error-free, or free of viruses or other harmful components.',
            ),
            _Section(
              title: '9. Limitation of Liability',
              body:
                  'To the fullest extent permitted by law, Gospel Beacon shall not be liable for any indirect, incidental, special, consequential, or punitive damages arising out of or related to your use of the App, even if we have been advised of the possibility of such damages.',
            ),
            _Section(
              title: '10. Changes to Terms',
              body:
                  'We may update these Terms from time to time. We will notify you of any material changes by updating the "Last updated" date at the top of this page. Your continued use of the App after such changes constitutes your acceptance of the new Terms.',
            ),
            _Section(
              title: '11. Contact',
              body:
                  'If you have any questions about these Terms, please contact us at support@gospelbeacon.app.',
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
