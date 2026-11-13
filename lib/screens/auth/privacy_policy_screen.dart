import 'package:flutter/material.dart';

import 'legal_document_screen.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalDocumentScreen(
      title: 'Privacy Policy',
      children: [
        LegalParagraph('Effective date: March 18, 2026'),
        LegalParagraph(
          'This Privacy Policy explains what information Gospel Beacon collects, how Gospel Beacon uses it, who can access it, and what choices you have. It applies to Gospel Beacon as currently implemented on March 18, 2026.',
        ),
        LegalHeading('1. Contact Us'),
        LegalParagraph(
          'If you have questions about privacy or want help with your information, please use the contact email or support channel identified for Gospel Beacon in the app listing, distribution page, or other official Gospel Beacon materials.',
        ),
        LegalHeading('2. The Data We Collect'),
        LegalSubheading('Data you provide directly'),
        LegalBulletList([
          'Account data such as your email address when you sign up or sign in.',
          'Authentication credentials used for login. Password handling is performed through Gospel Beacon\u2019s authentication provider rather than being stored in your Gospel Beacon profile record.',
          'Profile data you choose to add or edit, including your name, phone number, email address, and profile photo.',
          'Group data you create or manage, such as group names, group photos, privacy settings, membership, roles, and join codes.',
          'Lesson and study content you create, including lesson titles, descriptions, target audiences, dates, section titles, written content, and linked resource information.',
        ]),
        LegalSubheading('Data collected from your device or usage'),
        LegalBulletList([
          'A remembered email address stored locally on your device if you enable the "Remember me" option on the login screen.',
          'Files and images you choose to upload for your profile photo or a group photo.',
          'Basic service metadata such as timestamps and records needed to authenticate you, save your content, and keep the service working.',
        ]),
        LegalSubheading(
          'Data from websites and third-party services you choose to use',
        ),
        LegalBulletList([
          'If you add a web resource, Gospel Beacon may request metadata for the selected page and store the URL, title, and preview image returned for that resource.',
          'If you open external websites inside Gospel Beacon, those websites may collect information under their own privacy policies.',
        ]),
        LegalHeading('3. Why We Collect Your Data'),
        LegalBulletList([
          'To create and secure your account.',
          'To let you create, edit, save, and delete lesson plans and lesson sections.',
          'To let you create groups, manage membership, assign roles, and share content with the relevant group.',
          'To store and display profile photos, group photos, and linked resources you choose to add.',
          'To support account verification, password recovery, and basic service communications.',
          'To operate, maintain, debug, and protect Gospel Beacon.',
        ]),
        LegalHeading('4. Who Can See Your Data'),
        LegalSubheading('Other Gospel Beacon users'),
        LegalParagraph(
          'Gospel Beacon\u2019s current group and people-search features use profile information to help users find one another and collaborate. Depending on the feature being used, other Gospel Beacon users may be able to see information such as your name, email address, profile photo, shared lesson content, and the groups or resources you intentionally share with them.',
        ),
        LegalSubheading('Service providers'),
        LegalParagraph(
          'Gospel Beacon currently relies on third-party infrastructure to provide authentication, database storage, and file storage. Those providers may process data only as needed to host and operate Gospel Beacon.',
        ),
        LegalSubheading('Legal and safety disclosures'),
        LegalParagraph(
          'Gospel Beacon may disclose information when reasonably necessary to comply with law, respond to valid legal requests, enforce Gospel Beacon\u2019s terms, or protect the rights, safety, and security of Gospel Beacon, its users, or others.',
        ),
        LegalHeading('5. Data Retention'),
        LegalParagraph(
          'Gospel Beacon keeps your information for as long as it is reasonably needed to operate the service, maintain your account, provide shared features, comply with legal obligations, resolve disputes, and enforce agreements. Retention may vary by data type and by whether content has been shared with groups or other users.',
        ),
        LegalHeading('6. Your Rights and Choices'),
        LegalBulletList([
          'You can update profile details such as your name, phone number, email address, and profile photo from the app\u2019s profile editing flow.',
          'You can remove the locally stored remembered email on a device by turning off "Remember me" and signing in again, or by clearing the app\u2019s local data on that device.',
          'You can delete lesson content or groups you control using the features Gospel Beacon currently provides.',
          'If you need account deletion or additional privacy help beyond the app\u2019s current controls, contact Gospel Beacon using the official support contact made available with the app.',
        ]),
        LegalHeading('7. Children'),
        LegalParagraph(
          'Gospel Beacon is not intended for use in violation of applicable child privacy laws. If a parent or guardian believes a child provided personal information without the required permission, they should contact Gospel Beacon using the official support channel so the request can be reviewed.',
        ),
        LegalHeading('8. Security'),
        LegalParagraph(
          'Gospel Beacon uses reasonable administrative, technical, and organizational measures to protect information, but no method of transmission or storage is completely secure. You are also responsible for protecting your account credentials and for using discretion when sharing content in groups or through external links.',
        ),
        LegalHeading('9. Changes to This Policy'),
        LegalParagraph(
          'Gospel Beacon may update this Privacy Policy from time to time. When that happens, Gospel Beacon will post the revised version in the app or otherwise make it available to users. Your continued use of Gospel Beacon after the updated policy becomes effective means the new policy applies going forward.',
        ),
        LegalHeading('10. Current Scope'),
        LegalParagraph(
          'As of March 18, 2026, Gospel Beacon does not currently include in-app advertising or a paid purchase flow in the codebase reviewed for this policy. If Gospel Beacon later adds analytics, ads, payments, or new integrations, this policy should be updated before release.',
        ),
      ],
    );
  }
}
